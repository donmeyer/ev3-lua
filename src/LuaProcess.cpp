// LuaProcess.cpp
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//


#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/timerfd.h>
#include <assert.h>
#include <math.h>
#include <poll.h>

#include <sys/socket.h>
#include <netinet/in.h>

#include <lua.hpp>

#include "LuaProcess.h"
#include "log.h"
#include "config.h"
#include "luatools.h"
#include "processlib.h"
#include "loglib.h"
#include "telnet.h"


#define EVENT_DEBUG		0


const char *LuaProcess::KEY_PROCESS = "process_instance";

LuaProcess::LuaProcess(const char *scriptName, int telnetPort)
	: _cycle_timer_fd(-1),
	  _event_timer_fd(-1),
	  _timeout_timer_fd(-1),
	  _update_timer_fd(-1),
	  _telnet_listener_fd(-1),
	  _telnet_fd(-1),
	  _processName("elua"),
	  _cycleTime(0),
	  _scriptTime(0),
	  _timeHyst(2)
{
	strcpy(_scriptPath, scriptName);

	_L = luaL_newstate();

	Debug( "Lua state created" );

	// Set a registry key that is a pointer to ourself, so that library functions
	// written in C++ can find this object if they need to.
	lua_pushlightuserdata( _L, this );
	lua_setfield( _L, LUA_REGISTRYINDEX, KEY_PROCESS );

	// Open the standard libraries
	Debug( "opening standard libs" );
	luaL_openlibs( _L );

	Debug("opening custom libs");
	
	// Process lib 'proc'
	luaopen_process(_L);
	lua_setglobal(_L, "proc");

	// Log lib 'log'
	luaopen_log( _L );
	lua_setglobal(_L, "log");

	// Replace the normal Lua print with our own function to allow redirecting it
	// to things like Telnet sessions.
	lua_register( _L, "print", printFunction );
	
	// Clear the Lua stack
	lua_settop( _L, 0 );
	
	Debug( "telnet port setup" );
	if( telnetPort > 0 )
	{
		printf("Opening telnet port %d for process %s\n", telnetPort, _processName);
		Log("Opening telnet port %d for process %s", telnetPort, _processName);

		_telnet_listener_fd = openTelnet(telnetPort);
		if( _telnet_listener_fd < 0 )
		{
			LogError( "Failed to open telnet listener socket for port %d", telnetPort );
		}
	}

	// Cycle Timer - Used to call the Lua mainloop() function at desired intervals.
	_cycle_timer_fd = timerfd_create(CLOCK_MONOTONIC, 0);
	if(_cycle_timer_fd == -1)
	{
		LogError("Failed to create cycle timer");
	}

	// Event Timer - Used by the Lua proc lib for repeating timed event callbacks.
	_event_timer_fd = timerfd_create(CLOCK_MONOTONIC, 0);
	if( _event_timer_fd == -1 )
	{
		LogError( "Failed to create event timer" );
	}

	// Timeout Timer - Used by the Lua proc lib for setting a one-shot timeout even callback.
	_timeout_timer_fd = timerfd_create( CLOCK_MONOTONIC, TFD_NONBLOCK );
	if( _timeout_timer_fd == -1 )
	{
		LogError( "Failed to create timeout timer" );
	}

	// Update Timer - Sets the frequency at which we check for an updated Lua script.
	_update_timer_fd = timerfd_create( CLOCK_MONOTONIC, 0 );
	if( _update_timer_fd == -1 )
	{
		LogError( "Failed to create update timer" );
	}
	
	// Check for program updates every 5 seconds.
	setTimer( _update_timer_fd, 5, true );
}


LuaProcess::~LuaProcess()
{
}


/**
 * Run the Lua process loop.
 *
 * @note This will **not** return unless it fails.
 *
 */
int LuaProcess::run()
{
	// int rc;
	
	// This Lua script is fundamental, and always loaded at the start.
	// It does NOT get re-loaded if it changes.
	Debug( "Loading the foundation.lua script" );
	int rc = loadScript( "foundation.lua" );
	if (rc)
	{
		exit(EXIT_FAILURE);
	}

	// Clear the Lua stack
	lua_settop( _L, 0 );

	// This will load the main process script.
	if( checkForUpdatedScript() != 0 )
	{
		return -1;
	}

	// The init event gets called the first time we load the script only.	
	if( findFunction( "setup" ) )
	{
		Debug( "Calling the Lua script 'setup' function");
		call( 0, 0 );
	}

	Debug( "Starting the main loop" );
	for(;;)
	{
		cycle();
	}
	
	// This never happens
	return 0;
}


/**
 * Perform one cycle of the runloop.
 *
 * This virtual function may be redefined in a subclass. In this case, this parent method
 * must be called by the subclass version.
 */
void LuaProcess::cycle()
{
	if( _cycleTime == 0 )
	{
		// No time delay being used, call the main loop as frequently as we can!
		callMainloop();
	}

	static const int NUM_POLL_ITEMS = 6;

	// The structure for two events
	static struct pollfd fds[NUM_POLL_ITEMS] = {
		{_event_timer_fd, POLLIN, 0},
		{_timeout_timer_fd, POLLIN, 0},
		{_update_timer_fd, POLLIN, 0},
		{_telnet_listener_fd, POLLIN, 0},
		{_cycle_timer_fd, POLLIN, 0},
		{0, POLLIN, 0}};

	int numpoll = NUM_POLL_ITEMS - 1;

	if (_telnet_fd != -1)
	{
		fds[4].fd = _telnet_fd;
		numpoll++;
	}

	int rc = poll( &fds[0], numpoll, 0 );	// Timeout is in ms, currently 0 for no timeout
	if( rc == -1 )
	{
		LogError( "Call to poll() failed" );
		exit( EXIT_FAILURE );
	}
	else if( rc == 0 )
	{
		// Timeout, no events occurred
	}
	else
	{
		// Got some events.
		if( fds[0].revents & POLLIN )
		{
#if EVENT_DEBUG
			Debug( "Event timer triggered" );
#endif
			fds[0].revents = 0;
			handleEventTimer();
		}

		if( fds[1].revents & POLLIN )
		{
#if EVENT_DEBUG
			Debug("Timeout timer triggered");
#endif
			fds[1].revents = 0;
			handleTimeoutTimer();
		}

		if (fds[2].revents & POLLIN)
		{
#if EVENT_DEBUG
			Debug("Update timer triggered");
#endif
			fds[2].revents = 0;
			handleUpdateTimer();
		}

		if (fds[3].revents & POLLIN)
		{
			// Telnet connection made from client - accept it.
			Debug("Telnet connection triggered");
			fds[3].revents = 0;
			handleTelnetConnection();
		}

		if (fds[4].revents & POLLIN)
		{
#if EVENT_DEBUG
			Debug("Cycle timer triggered");
#endif
			fds[4].revents = 0;
			handleCycleTimer();
		}

		// This must be at the end of the array, as it is not always used.
		if (fds[5].revents & POLLIN)
		{
#if EVENT_DEBUG
			Debug("Telnet data");
#endif
			fds[5].revents = 0;
			handleTelnetData();
		}
	}
}


void LuaProcess::callMainloop()
{
	if (findFunction("mainloop"))
	{
		call(0, 0);
	}
	else
	{
		LogError("No 'mainloop' function found. Process wrapper exiting.");
		exit(EXIT_FAILURE);
	}
}


void LuaProcess::handleCycleTimer()
{
	// Have to read the timer overflow count to "clear" it for the next call to poll()
	char tbuf[8];
	read(_cycle_timer_fd, tbuf, sizeof tbuf);

	callMainloop();
}

void LuaProcess::handleTelnetConnection()
{
	if( _telnet_fd != -1 )
	{
		// Already a connection
		LogWarning( "Telnet connection ignored, already one in progress" );
		return;
	}
	
	Log( "Telnet connection made" );
	_telnet_fd = acceptTelnet( _telnet_listener_fd );

	Debug( "Telnet accepted on socket %d\n", _telnet_fd );
	
	// Print a prompt on the telnet port.
	print( _processName );
	print( ">" );
}


void LuaProcess::handleTelnetData()
{
	char buf[256];
	int len = recv( _telnet_fd, buf, sizeof(buf)-1, 0 );
	if( len == -1 )
	{
		LogWarning( "Telnet recv returned error %d\n", len );
		close( _telnet_fd );	
		_telnet_fd = -1;
	}
	else if( len == 0 )
	{
		Log( "Telnet client closed the connection" );
		close( _telnet_fd );
		_telnet_fd = -1;
	}
	else
	{
		buf[len] = '\0';
		
#if 0
		printf( "Received %d '%s'\n", len, buf );
		for( int i=0; i<len; i++ )
		{
			printf( "  0x%02X", buf[i] );
		}
		printf( "\n" );

		const char *foo = "Foo! Bar!\n";

		int rc = send( _telnet_fd, foo, strlen(foo), 0 );
		if( rc == -1 )
		{
			LogError( "Telnet send returned error %d", rc );
			close( _telnet_fd );
			_telnet_fd = -1;
		}
#endif
		
		// Execute the line we received in the Lua state.
		int err = luaL_dostring( _L, buf );
		if( err )
		{
			print( lua_tostring( _L, -1 ) );
			lua_pop( _L, 1 );
			print( "\n" );
		}

		// Print a prompt on the telnet port.
		print( _processName );
		print( ">" );
	}
}


void LuaProcess::handleUpdateTimer()
{
	// Have to read the timer overflow count to "clear" it for the next call to poll()
	char tbuf[8];
	read( _update_timer_fd, tbuf, sizeof tbuf );

	checkForUpdatedScript();
}


void LuaProcess::handleEventTimer()
{
	// Have to read the timer overflow count to "clear" it for the next call to poll()
	char tbuf[8];
	read( _event_timer_fd, tbuf, sizeof tbuf );

	callEvent( "timer", NULL, 0 );
}


void LuaProcess::handleTimeoutTimer()
{
	// Have to read the timer overflow count to "clear" it for the next call to poll()
	char tbuf[8];
	read( _timeout_timer_fd, tbuf, sizeof tbuf );

	callEvent( "timeout", NULL, 0 );
}


int LuaProcess::loadScript( const char *name )
{
	int rc = luaL_loadfile( _L, name );
	if( rc )
	{
		const char *lastErrorString = lua_tostring(_L,-1);
		lua_pop( _L, 1 );
		LogError( "%s", lastErrorString );
		return rc;
	}	

	rc = lua_pcall( _L, 0, LUA_MULTRET, 0 );
	if( rc )
	{
		const char *lastErrorString = lua_tostring(_L,-1);
		lua_pop( _L, 1 );
		LogError( "%s", lastErrorString );
	}	

	return rc;
}


int LuaProcess::checkForUpdatedScript()
{
	struct stat sb;
	int err = stat( _scriptPath, &sb );
	if( err )
	{
		LogError( "Unable to stat script '%s'", _scriptPath );
		return err;
	}

	if( sb.st_mtime != _scriptTime )
	{
		// Looks modified
		if( (_scriptTime == 0) || (( time(NULL) - _timeHyst ) > sb.st_mtime) )
		{
			// And the modification time was a little in the past.
			// This is a hack to let an FTP operation complete before we try and re-load the file.
			_scriptTime = sb.st_mtime;

			Log( "Loading updated script '%s'", _scriptPath );
			int rc = loadScript( _scriptPath );
			if( rc )
			{
				exit( EXIT_FAILURE );
			}
		}
	}
	
	return 0;
}


/*
 These functions are special:
 event_handler()
 once_handler()
 
 All other events are distributed via the Lua code that implements the event_handler() function.
 */

/**
 * This version will check for aliases and call them as well.
 */
void LuaProcess::callEvent( const char *name, const void *data, int size )
{
// 	printf( "call event %s\n", name );
	if( findFunction( "event_handler" ) )
	{
		// Function exists
		lua_pushstring( _L, name);
		
		if( data )
		{
			lua_pushlstring( _L, (const char*)data, size );
			// Stack is now: ... [error-func]  [func-to-call]  [data]  <-- Top
		}
		
		int argc = data ? 2 : 1;
		
		call( argc, 0 );
	}	
}


/**
 * Call a function on the stack. This also expects any arguments to be there as well.
 *
 * stack:  [func] [args...] <-- Top
 */
void LuaProcess::call( int numArgs, int numRets )
{
// 		printf( "On entry to call() stack size is %d, and argc is %d\n", lua_gettop( _L ), numArgs );

		// Tuck our error handler *under* the function on the stack
		lua_pushcfunction( _L, errorHandler );
		lua_insert( _L, -(numArgs+2) );

		// Stack is now: ... [error-func]  [func-to-call] [args...] <-- Top

		// The last argument to pcall is the index of the error handler
		int err = lua_pcall( _L, numArgs, 0, -(numArgs+2) );
		if( err )
		{
			LogError( "Event handler failed: %s", lua_tostring(_L,-1) );
			exit(EXIT_FAILURE);
			// lua_pop( _L, 1 );
		}

		lua_pop( _L, 1 );		// error handler

// 		printf( "On exit from call() stack size is %d\n", lua_gettop( _L ) );
}



/**
 * Find function and leave it the top of the Lua stack.
 *
 * @param name The name of the function
 * @return true if the function was found
 */
bool LuaProcess::findFunction( const char *name )
{
	lua_getglobal( _L, name );

	if( ! lua_isfunction( _L, -1 ) )
	{
		// Not a function
		lua_pop( _L, 1 );
		return false;
	}

	return true;
}


void LuaProcess::setCycleTime( double t )
{
	_cycleTime = t;
	setTimer( _cycle_timer_fd, t, true );
}


double LuaProcess::getCycleTime()
{
	return _cycleTime;
}


void LuaProcess::setEventTimer(double t)
{
	setTimer(_event_timer_fd, t, true);
}


void LuaProcess::setTimeoutTimer( double t )
{
	// Clear the timer. We do this before reading an re-setting the timer just in case
	// the new time is very brief. This avoids missing a trigger if it would have
	// elapsed *before* we had the chance to read it.
	setTimer( _timeout_timer_fd, 0, false );

	// Read the timer just in case it has already triggered.
	// Not sure if setting a timer to zero does this or not - this may be unneccessary?
	// The timer MUST have been created with the TFD_NONBLOCK flag!
	char tbuf[8];
	read( _timeout_timer_fd, tbuf, sizeof tbuf );

	// Now set the new time.
	setTimer( _timeout_timer_fd, t, false );
}


void LuaProcess::clearTimeoutTimer()
{
	setTimer( _timeout_timer_fd, 0, false );

	// Read the timer just in case it has already triggered.
	// Not sure if setting a timer to zero does this or not - this may be unneccessary?
	// The timer MUST have been created with the TFD_NONBLOCK flag!
	char tbuf[8];
	read( _timeout_timer_fd, tbuf, sizeof tbuf );
}


void LuaProcess::setTimer( int fd, double t, bool repeat )
{
	double intpart;
	double fracpart = modf( t, &intpart );
	time_t secs = intpart;
	long nsecs = fracpart * 1000000000.0;

	Debug( "Timer %d set to %ld . %ld\n", fd, secs, nsecs );

	struct itimerspec its;
	its.it_value.tv_sec = secs;
	its.it_value.tv_nsec = nsecs;
	its.it_interval.tv_sec = repeat ? its.it_value.tv_sec : 0;
	its.it_interval.tv_nsec = repeat ? its.it_value.tv_nsec : 0;

	if( timerfd_settime( fd, 0, &its, NULL ) == -1 )
	{
		LogError( "timerfd_settime() failed for timer %d", fd );
	}
}


double LuaProcess::getEventTimer() const
{
	struct itimerspec its;
	timerfd_gettime( _event_timer_fd, &its );

	double t = its.it_interval.tv_sec + ( 1000000000.0 / its.it_value.tv_nsec );
	return t;
}


/**
 Our version of the Lua print() function winds up calling this to output the text.
 This will send it to the appropriate place, which may include a Telnet session.
 */
void LuaProcess::print( const char *s )
{
	if( _telnet_fd != -1 )
	{
		// Telnet session connected, send print output there.
		int rc = send( _telnet_fd, s, strlen(s), 0 );
		if( rc == -1 )
		{
			LogError( "Telnet send returned error %d", rc );
			close( _telnet_fd );
			_telnet_fd = -1;
		}
	}
	else
	{
		// No telnet session underway, send to standard out.
		fprintf( stdout, "%s", s );
	}
}


/**
 This is a Lua function that we register to replace the normal Lua print function.
 
 It will call the print() method of the LuaProcess instance.
 
 class static
 */
int LuaProcess::printFunction( lua_State *L )
{
	// Get the pointer to our process class instance
	lua_getfield( L, LUA_REGISTRYINDEX, LuaProcess::KEY_PROCESS );
	LuaProcess *proc = (LuaProcess*) lua_touserdata( L, -1 );
	lua_pop( L, 1 );


	int n = lua_gettop( L );

	lua_getglobal(L, "tostring");

	for( int i=1; i<=n; i++ )
	{
		lua_pushvalue( L, -1 );  /* function to be called */
		lua_pushvalue( L, i );   /* value to print */

		lua_call( L, 1, 1 );

		const char *s = lua_tostring( L, -1 );  /* get result */
		if( s == NULL )
		{
			return luaL_error( L, LUA_QL( "tostring") " must return a string to " LUA_QL("print") );
		}

		if( i > 1 )
		{
			// Tabs go between multiple arguments to print
			proc->print( "\t" );
		}

		proc->print( s );
		lua_pop(L, 1);  /* pop result */
	}

	proc->print( "\n" );
	
	return 0;
}
