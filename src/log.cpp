// log.cpp
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//


#include <stdarg.h>
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include <stdlib.h>
#include <pwd.h>

#include "log.h"
#include "LogFile.h"



static bool inited = false;
static bool debugEnabled = false;

static void send( const char *msg );
static void init();

static LogFile *mainLog;
static LogFile *errorLog;



void enableDebug( bool enabled )
{
	debugEnabled = enabled;
}


void LogPrint( char type, const char *file, int line, const char *fmt, ... )
{
	va_list	args;
	va_start( args, fmt );

	char body[LOG_MSG_BUFSIZE];
	vsprintf( body, fmt, args );
	
	char buf[LOG_MSG_BUFSIZE];
	sprintf( buf, "%c[%d:%s:%d] %s", type, getpid(), file, line, body );
		
	send( buf );
	
	va_end( args );
}


void LogPrint( char type, const char *location, const char *body )
{
	char buf[LOG_MSG_BUFSIZE];
	sprintf( buf, "%c[%d:%s] %s", type, getpid(), location, body );
		
	send( buf );
}


void DebugPrint( const char *file, int line, const char *fmt, ... )
{
	if( debugEnabled == false )
	{
		return;
	}
	
	if( ! inited )
	{
		init();
	}

	va_list	args;
	va_start( args, fmt );

	char buf[LOG_MSG_BUFSIZE];
	vsprintf( buf, fmt, args );
	
// 	send( 'I', file, line, buf );
	printf( "+++ [%d:%s:%d] %s\n", getpid(), file, line, buf );
	
	va_end( args );
}



static void send( const char *msg )
{
	if( ! inited )
	{
		init();
	}
	
	time_t t = time(NULL);
	struct tm tm;
	localtime_r( &t, &tm );
	char tbuf[80];
	strftime( tbuf, sizeof tbuf, "%F %T", &tm );

	// Everything goes to the main log

	if( debugEnabled )
	{
		printf( "Log: %s %s\n", tbuf, &msg[1] );
	}

	size_t len = fprintf( mainLog->getFile(), "%s %s\n", tbuf, &msg[1] );
	fflush( mainLog->getFile() );
	mainLog->track( len );

	if( msg[0] == 'E' )
	{
		fprintf( stderr, "*** %s\n", &msg[1] );
		
		// Errors go to the error log as well.
		size_t len = fprintf( errorLog->getFile(), "%s %s\n", tbuf, &msg[1] );
		fflush( errorLog->getFile() );
		errorLog->track( len );
	}
}


static void init()
{
	// Find the home directory
	const char *homedir = getenv("HOME");
	if( homedir == NULL )
	{
		uid_t uid = getuid();
		struct passwd *pw = getpwuid(uid);
		if( pw == NULL )
		{
			printf( "Failed to find home dir for logs\n" );
			exit( EXIT_FAILURE );
		}

		homedir = pw->pw_dir;
	}

	mainLog = new LogFile( homedir, LOGFILE_NAME, NUM_LOGFILES, MAX_LOGFILE_SIZE );
	errorLog = new LogFile( homedir, ERROR_LOGFILE_NAME, NUM_ERROR_LOGFILES, MAX_ERROR_LOGFILE_SIZE );

	mainLog->open();
	errorLog->open();

	inited = true;
}
