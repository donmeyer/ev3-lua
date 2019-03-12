-- ev3.lua
--
--
-- Classes
--
--    Device (abstract)
--      |- Motor
--      |- Sensor (abstract)
--           |- TouchSensor
--           |- InfraredSensor
--           |- ColorSensor
--           |- GyroSensor
--           |- UltrasonicSensor
--
--
-- Attributes
--
-- <access><type>:<path>
--
-- Access:
--   R = Read-only
--   W = Write-only
--   C = Command Write (has no type field, and content is the command string itself)
--   X = Shadow the value when set as "shadow__<name>"
--       These should ONLY be for values that are never changed by the device itself!
--
-- Type:
--   i = Integer
--   s = String
--   l = List (returned as an array?)



--
-- Declare everything that this module needs from outside
--

-- Libraries
local string = string
local io = io
local os = os
local math = math

-- Functions
local assert = assert
local getmetatable = getmetatable
local setmetatable = setmetatable
local rawget = rawget
local rawset = rawset
local tostring = tostring
local tonumber = tonumber

-- local print = print

-- Cut off external access
_ENV = nil


---------------------------------------------------------------------


local debugEnabled = false

local function debug( ... )
    if debugEnabled then
        print(...)
    end
end



---------------------------------------------------------------------
--
--               Device class  (abstract)
--
---------------------------------------------------------------------

local Device = {}

Device.DEVICE_ROOT = "/sys/class"
-- Device.DEVICE_ROOT = "/Users/don/Dropbox/_ev3_fake/class"
-- Device.DEVICE_ROOT = "/Users/i852942/Dropbox/_ev3_fake/class"

-- Set true to convert the space-separated lists (e.g. 'commands') into tables
-- with each item being the key and the value being 'true'.
Device.lists_as_tables = false

-- These are not actually used by the Device class, they are here to be merged
-- in to the child class's attribute tables.
Device.attributes = {
    address = "Rs:address",
    commands = "Rl:commands",
    driver_name = "Rs:driver_name",
}


function Device:new( o )
    -- debug( "+ Device new" )
    -- debug( "+ self is " .. table_desc(self) )
    -- debug( "+ table arg o is " .. table_desc(o) )

    o = o or {}        -- Create table if the user didn't give one
    -- debug( "+ table for the new instance is " .. table_desc(o) )

	setmetatable( o, self )
    self.__index = self

    -- Set the index metamethods for any device class that descend directly from Device (e.g. Motor)
    o.__index = Device.handleIndex
    o.__newindex = Device.handleNewIndex
    o.__tostring = Device.tostring

	return o
end


-- Find the device
--
-- class - the device class, e.g. "tacho-motor"
-- name - the base name, e.g. "motor". This gets a device number appended.
-- driver - optional driver name to match
-- input_flag - True if the port is an input, false if output
-- port - The desired port. String A-D for outputs and numeric 1-4 for inputs.
--
-- Returns the device path or will assert if can't find desired device.
function Device:search_device( class, name, driver, input_flag, port )
    -- Find the motor (if any) on the given port.
    -- The address will be 'outC' etc.
    if port then
        if input_flag then
            assert( port >= 1 and port <= 4, "Input Port must be 1-4")
            port = "in" .. port
        else
            assert( string.match(port,"[ABCD]"), "Output Port must be 'A', 'B', 'C', or 'D'")
            port = "out" .. port
        end
    end

    for i=0, 3 do
        -- Search through all 4 possible devices looking for a match.
        local path = Device.DEVICE_ROOT .. "/" .. class .. "/" .. name .. tostring(i)
        local addr_path = path .. "/address"
        debug("Search - Try path: " .. addr_path)
        local f = io.open( addr_path, "r" )
        if f then
            local value = f:read()
            debug("address is '" .. value .. "' port is " .. tostring(port) )
            io.close(f)

            if port == nil or port == value then
                -- Found the general device. Is it the specifc one? (i.e. driver matches)
                local drv_path = path .. "/driver_name"
                debug("Search - Try driver name path: " .. drv_path)
                local f = io.open( drv_path, "r" )
                assert( f, "Failed to open driver name file: " .. drv_path )
                local value = f:read()
                debug("driver name is '" .. value .. "' desired is " .. tostring(driver) )
                io.close(f)
                
                if driver == nil or value == driver then
                    -- Found the proper device
                    return path
                -- else
                    -- if port then
                    --     assert( false, "Device found at specified port " .. port .. ", but wrong type" )
                    -- end
                end
            end 
        end
    end

    -- assert( false, "No device found at port " .. port )
end


-- Search the given table's metatable for an EV3 attribute
-- t - the table (object) to search, typically something like Motor
-- k - the attribute keyword
function Device:find_attribute( t, k )
    -- The metatable for a device instance will be that device's class.
    -- For example, the metatable for a motor instance will be the Motor class.
    -- This metatable is the object (table) that contains the attribute table for that device.
    local t = getmetatable(t)
    while t do
        -- Get the attribute table from the metatable
        local atab = rawget( t, "attributes" )
        if atab then
            -- debug( "Have attr table")
            local a = atab[k]
            if a then
                -- A valid EV3 attribute
                -- debug( "Found attribute")
                return a
            end
        end

        t = getmetatable(t)
    end

    return nil
end


-- Read an EV3 device attribute
--
-- t - table of the device object
-- a - the attribute in the format "RI:name"
function Device:read_attribute( t, attr )
    -- debug( "Read - attribute value: " .. attr )
    -- debug( "self=" .. table_desc(self))
    -- debug( "t=" .. table_desc(t))

    assert( t.device_path, "Attribute cannot be read, device is not connected" )

    -- Parse out the flags and key
    local flags, key = string.match( attr, "(%a+):(.+)" )
    -- debug(flags,key)
    -- debug( string.find(flags,"X"))

    -- Command?
    if string.find(flags,"C") then
        -- Commands are expected to be called as functions, so that's what we need to return
        -- so it can be executed.
        return function(...)
            -- debug( "Pow! " .. attr .. tostring(...) )
            -- Commands are special, we know the key and the table entry key is actually
            -- the value to write.
            -- We do this trickery to allow commands to look like class method calls
            -- of the format  m:foo()
            Device:set_attribute( t, "W:command", key )
        end
    elseif string.find(flags,"R") then
        -- Readable
        local skey = "shadow__" .. key
        local value = rawget( t, skey )   -- First see if we have a shadow value
        if value ~= nil then
            debug( "Shadow value found for " .. key )
            return value
        end

        -- No shadow, read it from the actual device
        local path = t.device_path .. "/" .. key
        --debug( "Open read file: '" .. path .. "'" )
        local f = io.open( path, "r" )
        assert( f, "Invalid attribute path" .. path )
        value = f:read()
        f:close()

        if string.find(flags,"i") then
            value = tonumber(value)
        end

        if Device.lists_as_tables and string.find(flags,"l") then
            -- Turn the space separated list into a table
            local t = {}
            for w in value:gmatch("[%a_%-]+") do
                t[w] = true
            end
            return t
        end

        return value
    elseif string.find(flags,"W") then
        error( "Error, can't read from write-only attribute " .. key )
    else
        error( "Invalid attribute specification" .. attr )
    end
end


-- 
-- t - table of the device object
-- attr - the attribute in the format "RWI:name"
-- v - value to set
function Device:set_attribute( t, attr, v )
    -- debug( "Set - attribute value " .. attr .. " to " .. tostring(v) )
    -- debug( "self=" .. table_desc(self))
    -- debug( "t=" .. table_desc(t))

    assert( t.device_path, "Attribute cannot be set, device is not connected" )

    local flags, key = string.match( attr, "(%a+):(.+)" )

    if string.find(flags,"W") then
        if string.find(flags,"i") then
            v = tostring(v)
        end

        local path = t.device_path .. "/" .. key
        debug( "Open write file: '" .. path .. "'" )
        local f = io.open( path, "w" )
        assert( f, "Invalid attribute path" .. path )
        debug( "Write: " .. tostring(v) )
        f:write(v)
        f:close()

        if string.find(flags,"X") then
            debug( "Cache attribute", key, v)
            local skey = "shadow__" .. key
            rawset( t, skey, v )
        end
    else
        error( "Error, can't write to read-only attribute " .. key )        
    end
end


-- Metatable __index function that searches for an attribute for the key and reads
-- then returns the value if found.
--
-- Note that this is NOT a class member, it does not and can not
-- have a 'self' argument.
function Device.handleIndex( t, k )
    -- debug( "\n(Snarf) Access to Device element " .. tostring(k) )
    -- debug( "self=" .. table_desc(self) ) -- this is Device class table (we need Motor instance table)
    -- debug( "t=" .. table_desc(t) ) -- this is Motor class table
    
    local attr = Device:find_attribute( t, k )
    if attr then
        return Device:read_attribute( t, attr )
    end

    -- If we get here, this is not an attribute. See if it's in the table
    local o = rawget( t, k )
    if o == nil then
        local mt = getmetatable(t)
        if mt ~= nil then
            -- See if the metatable (parent class) has the element.
            -- debug( "Look in parent class " .. table_desc(mt) )
            return mt[k]
        end
    end
    -- debug( "return t[k] = " .. tostring(o) )
    return o
end


-- Metatable __newindex function that searches for an attribute for the key and
-- writes the value if found.
--
-- Note that this is NOT a class member, it does not and can not
-- have a 'self' argument.
function Device.handleNewIndex( t,k, v )
    -- debug( "New value for Device element " .. tostring(k) )
    -- debug( "self=" .. tostring(self) ) -- this is Device class table (we need Motor instance table)
    -- debug( "t=" .. tostring(t) ) -- this is Motor class table

    local attr = Device:find_attribute( t, k )
    if attr then
        Device:set_attribute( t, attr, v )
        return
    else
        rawset( t, k, v )
    end
end

function Device.tostring(t)
    local driver = t.DRIVER or t.DEVICE_NAME
    if t.connected then
        return "(" .. driver .. ")  Connected " .. t.address .. "  " .. t.device_path
    else
        return "(" .. driver .. ")  Not Connected!"
    end
end


---------------------------------------------------------------------
--
--               Motor class
--
---------------------------------------------------------------------

-- print( "Create the Motor class" )
local Motor = Device:new()

-- print( "Motor class is " .. tostring(Motor) )

Motor.attributes = {
    count_per_rot = "Ri:count_per_rot",
    count_per_m = "Ri:count_per_m",
    full_travel_count = "Ri:full_travel_count",
    duty_cycle = "RWi:duty_cycle",    
    duty_cycle_sp = "RWi:duty_cycle_sp",
    polarity = "RWs:polarity",
    position = "RWi:position",
    hold_pid_kd = "RWi:hold_pid/Kd",
    hold_pid_ki = "RWi:hold_pid/Ki",
    hold_pid_kp = "RWi:hold_pid/Kp",
    max_speed = "Ri:max_speed",
    position_sp = "RWi:position_sp",
    speed = "Ri:speed",
    speed_sp = "RWi:speed_sp",
    ramp_up_speed = "RWi:ramp_up_speed",
    ramp_down_speed = "RWi:ramp_down_speed",
    speed_pid_kd = "RWi:speed_pid/Kd",
    speed_pid_ki = "RWi:speed_pid/Ki",
    speed_pid_kp = "RWi:speed_pid/Kp",
    state = "Rl:state",
    stop_action = "RWs:stop_action",
    time_sp = "RWi:time_sp",

    -- Commands
    run_forever = "C:run-forever",
    run_to_abs_pos = "C:run-to-abs-pos",
    run_to_rel_pos = "C:run-to-rel-pos",
    run_timed = "C:run-timed",
    run_direct = "C:run-direct",
    stop = "C:stop",
    reset = "C:reset"
}

Motor.DEVICE_CLASS = "tacho-motor"
Motor.DEVICE_NAME = "motor"
-- We don't use a driver name since each of the two tacho-motors uses
-- a different driver, and we don't care which.

Motor.STOP_ACTION_COAST = "coast"
Motor.STOP_ACTION_BRAKE = "brake"
Motor.STOP_ACTION_HOLD = "hold"

Motor.STATE_RUNNING = "running"
Motor.STATE_RAMPING = "ramping"
Motor.STATE_HOLDING = "holding"
Motor.STATE_OVERLOADED = "overloaded"
Motor.STATE_STALLED = "stalled"

Motor.POLARITY_NORMAL = "normal"
Motor.POLARITY_INVERSED = "inversed"

-- Motor.__index = Device.handleIndex
-- Motor.__newindex = Device.handleNewIndex


function Motor:new( port )
    -- debug( "+ Motor new, port= " .. tostring(port) )
    -- debug( "+ self is " .. table_desc(self) )

    local o = {}
	setmetatable( o, self )
    o.device_path = Device:search_device( self.DEVICE_CLASS, self.DEVICE_NAME, nil, false, port )
    o.connected = o.device_path ~= nil

    return o
end

-- Returns true if the state is running, ramping, overloaded, or stalled
function Motor:isRunning()
    local state = self.state
    if Device.lists_as_tables then
        return state[self.STATE_RUNNING]
            or state[self.STATE_RAMPING]
            or state[self.STATE_OVERLOADED]
            or state[self.STATE_STALLED]
    else
        return (state:find(self.STATE_RUNNING)
            or state:find(self.STATE_RAMPING)
            or state:find(self.STATE_OVERLOADED)
            or state:find(self.STATE_STALLED)) ~= nil
    end        
end

-- Returns true if the motor is holding
function Motor:isHolding()
    if Device.lists_as_tables then
        return self.state[self.STATE_HOLDING]
    else
        return state:find(self.STATE_HOLDING) ~= nil
    end        
end

-- Returns true if the motor is not stalled or overloaded
function Motor:isOk()
    local state = self.state
    if Device.lists_as_tables then
        return not (state[self.STATE_OVERLOADED] or state[self.STATE_STALLED] )
    else
        return not( state:find(self.STATE_OVERLOADED) or state:find(self.STATE_STALLED) )
    end        
end



---------------------------------------------------------------------
--
--               Sensor class (abstract)
--
---------------------------------------------------------------------

local Sensor = Device:new()

Sensor.attributes = {
    bin_data = "Rs:bin_data",
    bin_data_format = "Rs:bin_data_format",
    direct = "RWs:direct",  -- Think this is a string?
    decimals = "Ri:decimals",
    fw_version = "Rs:fw_version",
    mode = "RWXs:mode",
    modes = "Rl:modes",
    num_values = "Ri:num_values",
    poll_ms = "RWi:poll_ms",
    units = "Rs:units",
    text_value = "Rs:text_value",

    value0 = "Ri:value0",
    value1 = "Ri:value1",
    value2 = "Ri:value2",
    value3 = "Ri:value3",
    value4 = "Ri:value4",
    value5 = "Ri:value5",
    value6 = "Ri:value6",
    value7 = "Ri:value7",
    value8 = "Ri:value8",
    value9 = "Ri:value9"
}

Sensor.DEVICE_CLASS = "lego-sensor"
Sensor.DEVICE_NAME = "sensor"


function Sensor:new()
    local o = {}
    setmetatable( o, self )

    -- Set the Device class methods for accessing table items into the metatable of any
    -- device that is created from the Sensor class.
    o.__index = self.__index
    o.__newindex = self.__newindex
    o.__tostring = self.__tostring
    -- o.__index = Device.handleIndex
    -- o.__newindex = Device.handleNewIndex

    return o
end

function Sensor:sensorFoo()
    print( "Sensor Foo")
end

function Device:deviceFoo()
    print( "Device Foo")
end


---------------------------------------------------------------------
--
--               TouchSensor class
--
---------------------------------------------------------------------

local TouchSensor = Sensor:new()

TouchSensor.attributes = {
}

TouchSensor.DEVICE_CLASS = Sensor.DEVICE_CLASS
TouchSensor.DEVICE_NAME = Sensor.DEVICE_NAME
TouchSensor.DRIVER = "lego-ev3-touch"

-- Set the Device class methods for accessing table items into the metatable.
-- TouchSensor.__index = Device.handleIndex
-- TouchSensor.__newindex = Device.handleNewIndex

-- Sensor.__tostring = function(t)
--     if t.connected then
--         return "(" .. t.DRIVER .. ")  " .. tostring(t.connected) .. "  " .. t.address .. "  " .. t.device_path
--     else
--         return "(" .. t.DRIVER .. ")  Not Connected!"
--     end
-- end


function TouchSensor:new( port )
    local o = {}

    -- Set the TouchSensor class (table) as the metatable for our new sensor object `o`.
    setmetatable( o, self )

    o.device_path = Device:search_device( self.DEVICE_CLASS, self.DEVICE_NAME, self.DRIVER, true, port )
    o.connected = o.device_path ~= nil

    return o
end

function TouchSensor:isTouched()
    return self.value0 == 1
end



---------------------------------------------------------------------
--
--               InfraredSensor class
--
---------------------------------------------------------------------

local InfraredSensor = Sensor:new()

InfraredSensor.attributes = {
}

InfraredSensor.DEVICE_CLASS = Sensor.DEVICE_CLASS
InfraredSensor.DEVICE_NAME = Sensor.DEVICE_NAME
InfraredSensor.DRIVER = "lego-ev3-ir"

InfraredSensor.MODE_PROX = "IR-PROX"
InfraredSensor.MODE_SEEK = "IR-SEEK"
InfraredSensor.MODE_REMOTE = "IR-REMOTE"
InfraredSensor.MODE_REM_A = "IR-REM-A"
InfraredSensor.MODE_S_ALT = "IR-S-ALT"
InfraredSensor.MODE_CAL = "IR-CAL"


local ir_remote_tab = {
    "red-up",   -- 1
    "red-down",
    "blue-up",
    "blue-down",
    "red-up blue-up", -- 5
    "red-up blue-down",
    "red-down blue-up",
    "red-down blue-down",
    "beacon",
    "red-up red-down", -- 10
    "blue-up blue-down"
}

-- InfraredSensor.__index = Device.handleIndex
-- InfraredSensor.__newindex = Device.handleNewIndex


function InfraredSensor:new( port )
    local o = {}
	setmetatable( o, self )
    o.device_path = Device:search_device( self.DEVICE_CLASS, self.DEVICE_NAME, self.DRIVER, true, port )
    o.connected = o.device_path ~= nil

    return o
end


-- InfraredSensor.__tostring = function(t)
--     if t.connected then
--         return "(" .. t.DRIVER .. ")  Connected " .. t.address .. "  " .. t.device_path
--     else
--         return "(" .. t.DRIVER .. ")  Not Connected!"
--     end
-- end


function InfraredSensor:readDistance()
    assert( self.mode == self.MODE_PROX, "Mode must be MODE_PROX to read the distance" )
    return self.value0
end

-- Num is the channel. Defaults to channel 1
function InfraredSensor:readRemote(num)
    assert( self.mode == self.MODE_REMOTE, "Mode must be MODE_REMOTE to read the remote" )
    local v
    if num == 1 then
        v = self.value0
    elseif num == 2 then
        v = self.value1
    elseif num == 3 then
        v = self.value2
    elseif num == 4 then
        v = self.value3
    else
        v = self.value0
    end

    return ir_remote_tab[v]
end


-- Num is the channel. Defaults to channel 1
function InfraredSensor:seek(num)
    assert( self.mode == self.MODE_SEEK, "Mode must be MODE_SEEK to seek the beacon" )
    local h,d
    if num == 1 then
        h = self.value0
        d = self.value1
    elseif num == 2 then
        h = self.value2
        d = self.value3
    elseif num == 3 then
        h = self.value4
        d = self.value5
    elseif num == 4 then
        h = self.value6
        d = self.value7
    else
        h = self.value0
        d = self.value1
    end

    if d == -128 then
        -- No beacon
        return
    end

    return h, d
end

---------------------------------------------------------------------
--
--               UltrasonicSensor class
--
---------------------------------------------------------------------

local UltrasonicSensor = Sensor:new()

UltrasonicSensor.attributes = {
}

UltrasonicSensor.DEVICE_CLASS = Sensor.DEVICE_CLASS
UltrasonicSensor.DEVICE_NAME = Sensor.DEVICE_NAME
UltrasonicSensor.DRIVER = "lego-ev3-us"

UltrasonicSensor.MODE_DIST_CM = "US-DIST-CM"
UltrasonicSensor.MODE_DIST_IN = "US-DIST-IN"
UltrasonicSensor.MODE_LISTEN = "US-LISTEN"
UltrasonicSensor.MODE_SI_CM = "US-SI-CM"
UltrasonicSensor.MODE_SI_IN = "US-SI-IN"
UltrasonicSensor.MODE_DC_CM = "US-DC-CM"
UltrasonicSensor.MODE_DC_IN = "US-DC-IN"


-- UltrasonicSensor.__index = Device.handleIndex
-- UltrasonicSensor.__newindex = Device.handleNewIndex


function UltrasonicSensor:new( port )
    local o = {}
    setmetatable( o, self )

    o.device_path = Device:search_device( self.DEVICE_CLASS, self.DEVICE_NAME, self.DRIVER, true, port )
    o.connected = o.device_path ~= nil

    return o
end


-- Returns the distance in the units set by the mode
function UltrasonicSensor:distance()
    return self.value0
end


-- Returns true for presence, false for none
function UltrasonicSensor:presence()
    return self.value0 == 1
end

---------------------------------------------------------------------
--
--               ColorSensor class
--
---------------------------------------------------------------------

local ColorSensor = Sensor:new()

ColorSensor.attributes = {
}

ColorSensor.DEVICE_CLASS = Sensor.DEVICE_CLASS
ColorSensor.DEVICE_NAME = Sensor.DEVICE_NAME
ColorSensor.DRIVER = "lego-ev3-color"

ColorSensor.MODE_REFLECTED = "COL-REFLECT"
ColorSensor.MODE_AMBIENT = "COL-AMBIENT"
ColorSensor.MODE_COLOR = "COL-COLOR"
ColorSensor.MODE_RAW_REFLECTED = "REF-RAW"
ColorSensor.MODE_RGB = "RGB-RAW"
ColorSensor.MODE_CALIBRATION = "CAL"


-- ColorSensor.__index = Device.handleIndex
-- ColorSensor.__newindex = Device.handleNewIndex


function ColorSensor:new( port )
    local o = {}
	setmetatable( o, self )

    o.device_path = Device:search_device( self.DEVICE_CLASS, self.DEVICE_NAME, self.DRIVER, true, port )
    o.connected = o.device_path ~= nil

    return o
end


function ColorSensor:readReflectedIntensity()
    assert( self.mode == self.MODE_REFLECTED, "Mode must be MODE_REFLECTED" )
    return self.value0
end


function ColorSensor:readColor()
    assert( self.mode == self.MODE_COLOR, "Mode must be MODE_COLOR" )
    return self.value0
end



---------------------------------------------------------------------
--
--               GyroSensor class
--
---------------------------------------------------------------------

local GyroSensor = Sensor:new()

GyroSensor.attributes = {
}

GyroSensor.DEVICE_CLASS = Sensor.DEVICE_CLASS
GyroSensor.DEVICE_NAME = Sensor.DEVICE_NAME
GyroSensor.DRIVER = "lego-ev3-gyro"

GyroSensor.MODE_ANGLE = "GYRO-ANG"
GyroSensor.MODE_RATE = "GYRO-RATE"
GyroSensor.MODE_RAW = "GYRO-FAS"  -- Raw?
GyroSensor.MODE_ANGLE_AND_RATE = "GYRO-G&A"
GyroSensor.MODE_CALIBRATION = "GYRO-CAL"


-- GyroSensor.__index = Device.handleIndex
-- GyroSensor.__newindex = Device.handleNewIndex


function GyroSensor:new( port )
    local o = {}
	setmetatable( o, self )

    o.device_path = Device:search_device( self.DEVICE_CLASS, self.DEVICE_NAME, self.DRIVER, true, port )
    o.connected = o.device_path ~= nil

    return o
end



---------------------------------------------------------------------
--
--               LEDs
--
---------------------------------------------------------------------

local LED_PATH = "/sys/class/leds"


local function convertBrightness(brightness)
    assert( brightness >= 0 and brightness <= 1, "Brightness must be in the range 0-1" )
    return math.floor(255 * brightness)
end


local function setLEDBrightness( device, brightness )
    local v = convertBrightness(brightness)
    local path = LED_PATH .. device .. "/brightness"
    local f = io.open( path, "w" )
    assert( f, "Invalid attribute path" .. path )
    debug( "Write: " .. tostring(v) )
    f:write(v)
    f:close()
end


local function setLeftLED( red, green )
    setLEDBrightness( "/ev3:left:red:ev3dev", red )
    setLEDBrightness( "/ev3:left:green:ev3dev", green )
end

local function setRightLED( red, green )
    setLEDBrightness( "/ev3:right:red:ev3dev", red )
    setLEDBrightness( "/ev3:right:green:ev3dev", green )
end


---------------------------------------------------------------------
--
--               Battery & Power
--
---------------------------------------------------------------------

local battery = {}

setmetatable( battery, battery )

battery.PATH = "/sys/class/power_supply/legoev3-battery"

-- All attributes are numbers
battery.attributeList = {
    voltage = "voltage_now",
    maxVoltage = "voltage_max_design",
    minVoltage = "voltage_min_design",

    current = "current_now"
}


function battery:readValue(attribute)
    local path = self.PATH .. "/" .. attribute
    local f = io.open( path, "r" )
    assert( f, "Invalid attribute path" .. path )
    local value = f:read()
    f:close()
    return value
end    


battery.__index = function(t,k)
    local attrs = rawget( t, "attributeList" )
    local p = attrs[k]
    assert( p, "Invalid battery attribute" )
    local value = t:readValue(p)
    -- local path = t.PATH .. "/" .. p
    -- local f = io.open( path, "r" )
    -- assert( f, "Invalid attribute path" .. path )
    -- local value = f:read()
    -- f:close()

    value = tonumber(value)
    return value / 1000000  -- convert microvolts/amps to volts/amps
end

-- The technology is not a number, so we use a different way to read it.
-- TODO: Maybe we should allow both numbers and strings in the attribute table?
-- Or multiple tables...
function battery:isLithiumIon()
    local value = self:readValue("technology")
    return  value == "Li-ion"
end



---------------------------------------------------------------------
--
--               Sound
--
---------------------------------------------------------------------

-- Make a beep of the given frequency and duration.
--
-- Both arguments are optional.
-- Frequency defaults to 1000 Hz
-- Duration is in seconds. Defaults to 1 second.
local function beep( freq, duration )
    if duration == nil then
        duration = 1
    end

    if freq == nil then
        freq = 1000
    end

    duration = duration * 1000

    local cmd = "beep -f " .. tostring(freq) .. " -l " .. tostring(duration)
    os.execute( cmd )
end



---------------------------------------------------------------------
--
--               Buttons
--
---------------------------------------------------------------------

-- Returns code,state
local function readButtonpPacket()
    local path = "/dev/input/by-path/platform-gpio-keys.0-event"
    local f = io.open( path, "r" )
    assert( f, "Invalid attribute path" .. path )
    local buf = f:read(16)
    f:close()
    if #buf == 16 then
        -- Each press or release sends a 16-byte packet.
        -- 1-4   : Timestamp seconds
        -- 5-8   : Timestamp uS
        -- 9-10  : Type 
        -- 11-12 : Code, identifies the button
        -- 13-16 : Value (1=pressed, 0=released)

        -- local s = ""
        -- for c in buf:gmatch"." do
        --     s = s .. " " .. string.byte(c)
        -- end
        -- print(s)
        
        local b = string.byte(buf:sub(11))
        local state = string.byte(buf:sub(13))
        return b, state
    else
        return -1
    end
end


local function readButtonCode()
    while true do
        local b, s = readButtonpPacket()
        -- Wait for a press down (s==1), ignore releases
        if s == 1 then
            return b
        end
    end
end


local button_map = {
    [106] = "right",
    [105] = "left",
    [103] = "up",
    [108] = "down",
    [28] = "center",
    [14] = "back"
}

local function readButtons()
    local b = readButtonCode()
    local value = button_map[b]
    return value
end

---------------------------------------------------------------------
---------------------------------------------------------------------
---------------------------------------------------------------------

return {
    debugEnabled = debugEnabled,

    Motor = Motor,
    TouchSensor = TouchSensor,
    InfraredSensor = InfraredSensor,
    UltrasonicSensor = UltrasonicSensor,
    ColorSensor = ColorSensor,
    GyroSensor = GyroSensor,

    setLeftLED = setLeftLED,
    setRightLED = setRightLED,

    beep = beep,

    battery = battery,

    readButtons = readButtons,

    -- Make the device class available behind this obscure name for unit-test purposes.
    ev3_device_class_for_unit_tests = Device
}