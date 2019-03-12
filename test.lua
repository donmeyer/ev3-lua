-- test.lua
--
-- This is an example of using each sensor and motor class.
--
-- Tests Performed:
--      - Run two motors
--      - Wait for a touch sensor
--      - 

ev3 = require 'ev3'
-- require 'shell_tools'

print( "Let's go!" )

---------------------------------------------------------------------
-- Motor
---------------------------------------------------------------------

m = ev3.Motor:new( 'D' )
m2 = ev3.Motor:new('C' )

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

m.time_sp=2000
m.speed_sp=200
m.stop_action='hold'

print(m.stop_action)

m2.time_sp=2000
m2.speed_sp=-200
m2.stop_action='hold'

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

print( "Motors done moving")


---------------------------------------------------------------------
-- Front Panel Lights
---------------------------------------------------------------------

ev3.setLeftLED( 0.9, 0 )

---------------------------------------------------------------------
-- Touch
---------------------------------------------------------------------

print("\n\n-- Touch --")

t = ev3.TouchSensor:new(1)
print( "Touch sensor", t)

print(t.value0)

cnt = 0
while t:isTouched() == false do
    cnt = cnt + 1
    -- print(ir.value0)
end
while t:isTouched() do end  -- Once per touch!

print( "Touched!")
print(cnt)

ev3.setLeftLED( 0, 0.4 )


---------------------------------------------------------------------
-- Infrared
---------------------------------------------------------------------

print("\n\n-- Infrared --")
ir = ev3.InfraredSensor:new()
print(ir)
print(ir.connected)
print(ir.address)
print(ir.mode)
print(ir.modes)

-- ir.mode = ev3.InfraredSensor.MODE_PROX
ir.mode = ir.MODE_PROX

print( "Waiting for IR prox value <20. Touch to take reading.")
while true do
    if t:isTouched() then
        while t:isTouched() do end  -- Once per touch!
        dist = ir:readDistance()
        print( dist )
        if dist < 20 then
            break
        end
    end
end


---------------------------------------------------------------------
-- Color
---------------------------------------------------------------------

print("\n\n-- Color --")
color = ev3.ColorSensor:new()
print(color)
print(color.connected)
print(color.address)
print(color.mode)
print(color.modes)

print( "Waiting for color value >50. Touch to take reading.")
while true do
    if t:isTouched() then
        while t:isTouched() do end  -- Once per touch!
        local v = color:readReflectedIntensity()
        print( v )
        if v > 50 then
            break
        end
    end
end

print("Color mode, will display the current color when touched.")
print( "Ctrl-C to exit the script" )
color.mode = ev3.ColorSensor.MODE_COLOR

while true do
    if t:isTouched() then
        print( color:readColor() )
        while t:isTouched() do end
    end
end


---------------------------------------------------------------------
-- Ultrasonic
---------------------------------------------------------------------


---------------------------------------------------------------------
-- GyroSensor
---------------------------------------------------------------------

