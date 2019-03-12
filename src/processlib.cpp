// processlib.cpp
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//

#include <stdlib.h>
#include <time.h>
#include <math.h>

#include <lua.hpp>

#include "LuaProcess.h"
#include "log.h"


/**
 *
 * @param L
 *
 * @return int
 */
static int setCycleTime( lua_State *L )
{
	lua_Number n = luaL_checknumber( L, 1 );

	lua_getfield( L, LUA_REGISTRYINDEX, LuaProcess::KEY_PROCESS );
	LuaProcess *proc = (LuaProcess*) lua_touserdata( L, -1 );

	proc->setCycleTime( n );

	return 0;
}


static int getCycleTime( lua_State *L )
{
	lua_getfield( L, LUA_REGISTRYINDEX, LuaProcess::KEY_PROCESS );
	LuaProcess *proc = (LuaProcess*) lua_touserdata( L, -1 );
	lua_pushnumber( L, proc->getCycleTime() );
	return 1;
}


/**
 *
 * @param L
 *
 * @return int
 */
static int setTimer(lua_State *L)
{
	lua_Number n = luaL_checknumber(L, 1);

	lua_getfield(L, LUA_REGISTRYINDEX, LuaProcess::KEY_PROCESS);
	LuaProcess *proc = (LuaProcess *)lua_touserdata(L, -1);

	proc->setEventTimer(n);

	return 0;
}

static int getTimer(lua_State *L)
{
	lua_getfield(L, LUA_REGISTRYINDEX, LuaProcess::KEY_PROCESS);
	LuaProcess *proc = (LuaProcess *)lua_touserdata(L, -1);
	lua_pushnumber(L, proc->getEventTimer());
	return 1;
}

/**
 *
 * @param L
 *
 * @return int
 */
static int setTimeoutTimer( lua_State *L )
{
	lua_Number n = luaL_checknumber( L, 1 );

	lua_getfield( L, LUA_REGISTRYINDEX, LuaProcess::KEY_PROCESS );
	LuaProcess *proc = (LuaProcess*) lua_touserdata( L, -1 );

	proc->setTimeoutTimer( n );

	return 0;
}


/**
 *
 * @param L
 *
 * @return int
 */
static int clearTimeoutTimer( lua_State *L )
{
	lua_getfield( L, LUA_REGISTRYINDEX, LuaProcess::KEY_PROCESS );
	LuaProcess *proc = (LuaProcess*) lua_touserdata( L, -1 );

	proc->clearTimeoutTimer();

	return 0;
}


/**
 *
 * @param L
 *
 * @return int
 */
static int procSleep(lua_State *L)
{
	lua_Number n = luaL_checknumber(L, 1);

	lua_getfield(L, LUA_REGISTRYINDEX, LuaProcess::KEY_PROCESS);
	// LuaProcess *proc = (LuaProcess *)lua_touserdata(L, -1);

	double intpart;
	double fracpart = modf(n, &intpart);
	time_t secs = intpart;
	long nsecs = fracpart * 1000000000.0;

	// Debug("Timer %d set to %ld . %ld\n", fd, secs, nsecs);

	struct timespec ts;
	ts.tv_sec = secs;
	ts.tv_nsec = nsecs;

	nanosleep(&ts,NULL);

	return 0;
}


/**
 *
 * @param L
 *
 * @return int
 */
static int exitProcess(lua_State *L)
{
	int rc = EXIT_SUCCESS;

	if( lua_gettop(L) > 0 )
	{
		lua_Number n = luaL_checknumber(L, 1);
		rc = (int)n;
	}

	luaL_where(L, 1);
	const char *where = lua_tostring(L, -1);

	char buf[64];
	sprintf( buf, "Exiting with return code %d", rc );
	LogPrint('I', where, buf);

	exit(rc);

	return 0;
}

static const luaL_Reg funcs[] = {
	{"set_cycle_time", setCycleTime},
	{"get_cycle_time", getCycleTime},

	{"set_timer", setTimer},
	{"get_timer", getTimer},

	{"set_timeout", setTimeoutTimer},
	{"clear_timeout", clearTimeoutTimer},

	{ "sleep", procSleep },
	
	{"exit", exitProcess},

	{NULL, NULL}};

// This will be called by the Lua process to initialize the library.
int luaopen_process( lua_State *L )
{
	luaL_newlib( L, funcs );
	return 1;
}
