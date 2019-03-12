# Makefile for the EV3 Lua Robot application


#----------------------------------------------------
# Platform Configuration
#----------------------------------------------------

# Possible values for 'os':
#	linux
#  mac

os=linux

CPATH=/usr/local/include
LIBRARY_PATH=/usr/local/lib

ifeq ($(os),mac)
# Mac OSX
PLAT_LDFLAGS=
LIB_OPTION= -bundle -undefined dynamic_lookup
else
# Default is Linux
# The -Wl,-E incantaion solves the symbol link problem for socket lib
PLAT_LDFLAGS=-Wl,-E
LIB_OPTION= -shared
endif

CC=g++
RM= rm -f

#----------------------------------------------------
#----------------------------------------------------

# Third-party libraries needed		
MYLIBS= -llua5.2

# System libraries needed
SYSLIBS= -ldl

#CC= g++
CPPFLAGS= -O2 -Wall  $(SYSCFLAGS) $(MYCFLAGS) -I$(CPATH) -I/usr/include/lua5.2

# The -Wl,-rpath -Wl,$(LIBRARY_PATH) incantation causes the 0MQ lib to be found?
LDFLAGS= $(SYSLDFLAGS) $(MYLDFLAGS) $(PLAT_LDFLAGS)
## -L$(LIBRARY_PATH)   -Wl,-rpath -Wl,$(LIBRARY_PATH)

LDLIBS= -lm $(SYSLIBS) $(MYLIBS)



#------------------------------------------------------------------------
#      Build Images
#------------------------------------------------------------------------

# Main program
MAIN_EXE= elua



#------------------------------------------------------------------------
#        Object Files
#------------------------------------------------------------------------

MAIN_H= luatools.cpp luatools.h  log.cpp log.h  utils.cpp utils.h  config.h


MAIN_O= elua.o  LuaProcess.o  processlib.o  telnet.o  loglib.o  utils.o  log.o  LogFile.o luatools.o


#------------------------------------------------------------------------
#       Targets & Rules
#------------------------------------------------------------------------

all:	$(MAIN_EXE)  install


$(MAIN_EXE):	$(MAIN_O)
#	$(CC)  $(LDFLAGS)  $(CORE_O)  $(LDLIBS)   -o $@



#$(LUA_PROCESS_LIBNAME):   $(LUA_PROCESS_O)
#	$(CC) $(CFLAGS) $(LIB_OPTION) -o $(LUA_PROCESS_LIBNAME) $(LUA_PROCESS_O)


#$(XBEE_TOOL_EXE):	$(XBEE_PROC_O)  $(CORE_O)


install:
	cp $(MAIN_EXE) ../$(MAIN_EXE)


clean:
	$(RM) *.o
	$(RM) $(MAIN_EXE)


echo:
	echo os=$(os)
	echo SYSCFLAGS=$(SYSCFLAGS)
	echo MYCFLAGS=$(MYCFLAGS)
	echo CFLAGS=$(CFLAGS)
	echo CPPFLAGS=$(CPPFLAGS)
	echo MYLDFLAGS=$(MYLDFLAGS)
	echo SYSLDFLAGS=$(SYSLDFLAGS)
	echo PLAT_LDFLAGS=$(PLAT_LDFLAGS)
	echo LDFLAGS=$(LDFLAGS)


#.cpp.o:
#	$(CC) $(CFLAGS) $@


#------------------------------------------------------------------------
#       Dependencies
#------------------------------------------------------------------------

ha.o:	ha.cpp ha.h  $(CORE_H)

log.o:   log.cpp  log.h  LogFile.h

LogFile.o:    LogFile.cpp  LogFile.h


luaproc.o:   luaproc.cpp  $(CORE_H)

luatools.o:		luatools.cpp luatools.h

LuaTable.o:		LuaTable.cpp LuaTable.h

telnet.o:		telnet.cpp telnet.h

utils.o:	utils.cpp  utils.h

