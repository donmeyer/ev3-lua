-- test.lua
--


ev3 = require 'ev3'


m = ev3.Motor:new( 'D' )
m2 = ev3.Motor:new('C' )

print(m)
print(m2)

print(m.connected, m2.connected)

-- print(m._path)
print("Driver name: " .. m.driver_name)
print("Device path: ".. m.device_path)
print("Address: ".. m.address)

print(m.speed_pid_kd)

print(m.state)

print( "--- Commands ---")
print(m.commands)

print("Count per rot: " .. tostring(m.count_per_rot))

m.time_sp=1000
m.speed_sp=200
m.stop_action=m.STOP_ACTION_HOLD

print(m.stop_action)

m2.time_sp=1000
m2.speed_sp=-200
m2.stop_action=m2.STOP_ACTION_HOLD

m:run_timed()

-- m.speed_sp=-200

m2:run_timed()

print("Get state")
-- while 1 do
--     print(m.state)
-- end
print(m:isRunning(),m2:isRunning())
print(m.state,m2.state)
-- print(m.state)
-- print(m.state)
-- print(m.state)
-- print(m:isRunning())

while m:isRunning() do end  -- Wait for the motor to finish moving
while m2:isRunning() do end  -- Wait for the motor to finish moving

print( "Move back" )

m.speed_sp=-200
m2.speed_sp=200

m:run_timed()
m2:run_timed()

while m:isRunning() do end  -- Wait for the motor to finish moving
while m2:isRunning() do end  -- Wait for the motor to finish moving

-- Should have a little delay here to let the robot settle before we release the motors,
-- but standard Lua has no such function.

m.stop_action=m.STOP_ACTION_COAST
m2.stop_action=m2.STOP_ACTION_COAST

-- Even though we change the stop action, it won't take effect until we give a command.
-- The stop command works for this, and it has no other impact since already stopped.
m:stop()
m2:stop()

print( "Motors done moving")
