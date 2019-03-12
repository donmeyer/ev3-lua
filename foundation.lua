-- foundation.lua
--
-- This script is always loaded for the Lua instance.
-- It does NOT get re-loaded if it (or any of the modules it imports) changes.


log.info "Loading the foundation script"

-- Events comes first because other things may need to register for events
-- events = require "event_mgr"


-- Global functions handy when using an interactive shell
require "shell_tools"


