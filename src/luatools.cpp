// luatools.cpp
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//



#include <unistd.h>
#include <string.h>
#include <lua.hpp>

#include "luatools.h"



/**
 * If the table on the top of the Lua stack has the given field
 * and check to see if it is the right type.
 * If the field is missing or the wrong type, throw a Lua error.
 */
void requireField( lua_State *L, const char *key, int type )
{
	if( hasField( L, key, type ) == false )
	{
		luaL_error( L, "Table field '%s' missing", key );
	}
}


/**
 * If the table on the top of the Lua stack has the given field
 * and check to see if it is the right type.
 * If so, return true.
 * If no field return false.
 * If has a field but it is the wrong type, throw an error.
 */
bool hasField( lua_State *L, const char *key, int type )
{
	lua_pushstring( L, key );
	lua_gettable( L, -2 );
	if( lua_isnil( L, -1 ) )
	{
		// That table member does not exist. Not necessarily an error.
		lua_pop( L, 1 );
		return false;
	}
	
	if( type != lua_type( L, -1 ) )
	{
		// Has the field, but wrong type
		luaL_error( L, "Wrong type for table field '%s'", key );
		return false;
	}

	return true;
}



/**
 * This can be used to get an error with the Lua location when doing a lua_pcall()
 */
int errorHandler( lua_State *L )
{
#if 0
	dumpstack( L, "Error handler stack" );

	printf( "errfunc says: %s", lua_tostring(L,-1) );

	luaL_where( L, 0 );
	const char *where = lua_tostring( L, -1 );
	printf( "Where 0 `%s`\n", where );

	luaL_where( L, 1 );
	where = lua_tostring( L, -1 );
	printf( "Where 1 `%s`\n", where );

	luaL_where( L, 2 );
	where = lua_tostring( L, -1 );
	printf( "Where 2 `%s`\n", where );
#endif

	luaL_where( L, 2 );
	const char *where = lua_tostring( L, -1 );

	char buf[256];
	sprintf( buf, "%s%s", where, lua_tostring(L,-2) );

	lua_pushstring( L, buf );
	return 1;
}


void dumpstack( lua_State *L, const char *message)
{
  int i;
  int top=lua_gettop(L);
  printf("dumpstack -- %s\n",message);
  for (i=1; i<=top; i++) {
    printf("%d\t%s\t",i,luaL_typename(L,i));
    switch (lua_type(L, i)) {
      case LUA_TNUMBER:
        printf("%g\n",lua_tonumber(L,i));
        break;
      case LUA_TSTRING:
        printf("%s\n",lua_tostring(L,i));
        break;
      case LUA_TBOOLEAN:
        printf("%s\n", (lua_toboolean(L, i) ? "true" : "false"));
        break;
      case LUA_TNIL:
        printf("%s\n", "nil");
        break;
      default:
        printf("%p\n",lua_topointer(L,i));
        break;
    }
  }
  printf("dumpstack -- END\n");
}
