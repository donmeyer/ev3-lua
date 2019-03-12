-- diag.lua


-- Import Section
-- Declare everything that this module needs from outside
local string = string
local print = print
local getmetatable = getmetatable
local tostring = tostring
local pairs = pairs
local type = type

-- Cut off external access
_ENV = nil



--
-- Table debugging support
--
local table_names = {}

local function register_table(t,name)
    table_names[t] = name
end


local function table_desc(t)
    local name = table_names[t]
    if name == nil then
        return string.format( "(%s)", tostring(t) )
    end
    return string.format( "%s", name )
end


local function dump_table(tt)
    print("Table: " .. table_desc(tt) )
    print("Meta:  " .. table_desc( getmetatable(tt) ) )
	for k,v in pairs(tt) do
		print( string.format( "%s  (%s)  %s", k, type(v), tostring(v) ) )
    end
    print("")
end


return {
    register_table = register_table,
    table_desc = table_desc,
    dump_table = dump_table
}
