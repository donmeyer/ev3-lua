// loglib.cpp
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//

#include <string.h>
#include <lua.hpp>

#include "log.h"


/**
 * <message>
 *
 * @param L
 *
 * @return int
 */
static int info( lua_State *L )
{
	const char *s = luaL_checkstring( L, 1 );

	luaL_where( L, 1 );
	const char *where = lua_tostring( L, -1 );

	LogPrint( 'I', where, s );

	lua_pop( L, 1 );
		
	return 0;
}


/**
 * <message>
 *
 * @param L
 *
 * @return int
 */
static int warn( lua_State *L )
{
	const char *s = luaL_checkstring( L, 1 );

	luaL_where( L, 1 );
	const char *where = lua_tostring( L, -1 );

	LogPrint( 'W', where, s );

	lua_pop( L, 1 );
		
	return 0;
}


/**
 * <message>
 *
 * @param L
 *
 * @return int
 */
static int error( lua_State *L )
{
	const char *s = luaL_checkstring( L, 1 );

	luaL_where( L, 1 );
	const char *where = lua_tostring( L, -1 );

	LogPrint( 'E', where, s );

	lua_pop( L, 1 );
		
	return 0;
}


static const luaL_Reg funcs[] = {
	{ "print", info },
	{ "info", info },
	
	{ "warn", warn },
	
	{ "error", error },

	{ NULL, NULL }
};


// This will be called by the Lua process to initialize the library.
int luaopen_log( lua_State *L )
{
	luaL_newlib( L, funcs );
	return 1;
}
