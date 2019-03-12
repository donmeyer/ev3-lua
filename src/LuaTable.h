// LuaTable.h
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//

#ifndef LUATABLE_H
#define LUATABLE_H  1

struct lua_State;


/**
 * Convenience class for accessing fields in a Lua table.
 *
 *	Created: 6-Apr-2013
 *	Author: Donald Meyer
 */

class LuaTable {
public:
	LuaTable( lua_State *L );
	LuaTable( lua_State *L, int tableIndex );

	bool getOptionalField( const char *key, int type );
	void getField( const char *key, int type );
	
private:
	lua_State *_L;
	int _tableIndex;
};


#endif