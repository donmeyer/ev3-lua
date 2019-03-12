// luatools.h
//
// BeagleBone Home Automation
//
// Copyright (c) 2013 by Donald T. Meyer, Stormgate Software.
//

#ifndef LUA_TOOLS_H
#define LUA_TOOLS_H  1

struct lua_State;


void requireField( lua_State *L, const char *key, int type );

bool hasField( lua_State *L, const char *key, int type );

int errorHandler( lua_State *L );

void dumpstack( lua_State *L, const char *message);


#endif
