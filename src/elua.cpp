// luaproc.cpp
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <fcntl.h> 

#include <lua.hpp>

#include "LuaProcess.h"
#include "log.h"

#include "telnet.h"


static void handleOpt( const char *arg );



static int telnetPort = 0;		// default is none
static const char *scriptName = NULL;


// luaproc [opts] <script>
int main( int argc, const char **argv )
{	
	Log( "Lua EV3 Environment running!" );
// 	telnet();
	
	for( int i=1; i<argc; i++ )
	{
		handleOpt( argv[i] );
	}

	if( scriptName == NULL )
	{
		LogError( "Error - no Lua script name argument - exiting" );
		exit( -1 );
	}
	
	Debug( "Creating Lua process object" );
	LuaProcess *proc = new LuaProcess( scriptName, telnetPort );

	Debug( "Running Lua process" );
	if( proc->run() != 0 )
	{
		LogError( "Failed to run" );
	}
	
	return 0;
} 


static void handleOpt( const char *arg )
{
	if( arg[0] == '-' )
	{
		// dash option
		const char *opt = &arg[1];
		
		if( strcmp( opt, "d" ) == 0 )
		{
			enableDebug( true );
		}
		else if( opt[0] == 't' )
		{
			telnetPort = atoi( &opt[1] );
		}
	}
	else
	{
		// Script name if not an option
		if( scriptName != NULL )
		{
			LogError( "Error - can only be one script name argument - exiting" );
			exit( -1 );		
		}

		scriptName = arg;
	}
}