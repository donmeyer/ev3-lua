This is an unfinished set of Lua biundings for ev3dev.

(Mindstorms Robot running ev3dev)

The `src` directory contains the the C++ source for the `elua` executable. Various Lua test and development scripts are at the top level, as well as the EV3 bindings.

The `elua` executable is the program that will run a Lua script in the ELua environment.

The main feature is an environment that allows updating a _running_ Lua program. This is done by calling the main Lua function at a frequent rate.

The `robot1.lua` and `robot2.lua` are examples of this scheme.


## This is still very much NOT a final product!



# Support Files

* ev3.lua
* diag.lua
* shell_tools.lua

# Stand-Alone Scripts
_These get executed directly from the Lua interpreter `lua`_

* test*.lua
* ev3_unittests.lua


# Robot Process Scripts
_These are executed via the `elua` program_

* foundation.lua
* proctest.lua
* robot1.lua
