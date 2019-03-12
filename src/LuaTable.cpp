// LuaTable.cpp
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//



#include <unistd.h>
#include <string.h>

#include <lua.hpp>

#include "LuaTable.h"


/**
 * Table CTOR that expects the table to be on the top of the Lua stack
 */
LuaTable::LuaTable( lua_State *L )
:	_L( L )
{
	_tableIndex = lua_gettop( L );
}


/**
 * Table CTOR that allows specifying where the table is on the Lua stack
 */
LuaTable::LuaTable( lua_State *L, int tableIndex )
:	_L( L ),
	_tableIndex( tableIndex )
{
}


/**
 * Gets a required field from the table.
 *
 * If the table has the given field, check to see if it is the right type.
 * If the field is missing or the wrong type, throw a Lua error.
 */
void LuaTable::getField( const char *key, int type )
{
	if( getOptionalField( key, type ) == false )
	{
		luaL_error( _L, "Table field '%s' missing", key );
	}
}


/**
 * Gets an optional field from the table.
 *
 * If the table has the given field, check to see if it is the right type.
 * If so, return true.
 * If no field return false.
 * If has a field but it is the wrong type, throws an error.
 */
bool LuaTable::getOptionalField( const char *key, int type )
{
	lua_pushstring( _L, key );
	lua_gettable( _L, _tableIndex );
	if( lua_isnil( _L, -1 ) )
	{
		// That table member does not exist. Not necessarily an error.
		return false;
	}
	
	if( type != lua_type( _L, -1 ) )
	{
		// Has the field, but wrong type
		luaL_error( _L, "Wrong type for table field '%s'", key );
		lua_pop( _L, 1 );
		return false;
	}

	return true;
}
