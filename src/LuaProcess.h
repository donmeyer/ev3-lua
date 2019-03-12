// LuaProcess.h
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//

#ifndef LUAPROCESS_H
#define LUAPROCESS_H  1

#include <time.h>
#include <limits.h>


struct lua_State;


/**
 * Encapsulates a Lua state.
 *
 *	Created: 26-Mar-2013
 *	Author: Donald Meyer
 */

class LuaProcess {
public:
	LuaProcess( const char *scriptName, int telnetPort );
	~LuaProcess();

	int run();

	void setCycleTime(double secs);
	double getCycleTime();

	void setEventTimer(double secs);
	double getEventTimer() const;

	void setTimeoutTimer( double secs );
	void clearTimeoutTimer();
	
protected:
	bool findFunction( const char *name );
	void callEvent( const char *name, const void *data, int size );
	void call( int numArgs, int numRets );

	int loadScript( const char *name );
	int checkForUpdatedScript();

	void callMainloop();

	void handleCycleTimer();
	void handleTimeoutTimer();
	void handleEventTimer();
	void handleUpdateTimer();
	void handleEventMsg();
	void handleTelnetConnection();
	void handleTelnetData();

	virtual void cycle();
		
	void print( const char *s );

private:
	LuaProcess( const LuaProcess &foo );
	const LuaProcess& operator=( const LuaProcess &rhs );
		// These are declared here only to prevent them from being used.

	void setTimer( int fd, double t, bool repeat );

	static int printFunction( lua_State *L );

	//
	//		Data members
	//

public:
	static const char *KEY_PROCESS;

protected:
	lua_State * _L;

	/// The application cycle timer for calling the mainloop.
	int _cycle_timer_fd;

	/// The default event timer.
	int _event_timer_fd;
	
	/// The timeout event timer.
	int _timeout_timer_fd;
	
	// Timer for checking to see if the script has updated
	int _update_timer_fd;

	/// The telnet socket that we listen on for incoming client connections.
	int _telnet_listener_fd;
	
	/// The telnet socket that represents a client connection. (one allowed at a time)
	int _telnet_fd;
	
private:
	/// Full path to the script.
	char _scriptPath[PATH_MAX];
	
	const char *_processName;

	/// Cycle time
	double _cycleTime;

	/// The time the script was last modified. Used to detect script updates.
	time_t _scriptTime;
	
	/// Wait this many seconds after a script's modification time before reloading it.
	time_t _timeHyst;
};

#endif
