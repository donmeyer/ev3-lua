

diag = require( "diag" )

ev3 = require "ev3"

-- Make the Device class visibile via a new definition using the obscure global name we
-- create in the ev3 module to support unit tests.
local Device = ev3.ev3_device_class_for_unit_tests
local Motor = ev3.Motor
local InfraredSensor = ev3.InfraredSensor


--
-- Tests
---

diag.register_table( Device, "Device" )
diag.register_table( Motor, "Motor" )

print( "Make a motor instance")
m = ev3.Motor:new( 'D' )

diag.register_table( m, "m instance" )

print("")
print( "--- Table class Device")
diag.dump_table(Device)

print( "--- Table class Motor")
diag.dump_table(Motor)

print( "--- Table instance m")
diag.dump_table(m)

print("---------------")

print( "These are found in parent metatables")
print(Motor.DEVICE_ROOT)
print( "attr " .. tostring(m.attributes))
print(m.DEVICE_ROOT)
print(m.DEVICE_CLASS)
print(m.RUN_FOREVER)

print( "These are direct members")
print(Device.DEVICE_ROOT)
print(Motor.attributes)
print(Motor.RUN_FOREVER)
print(m.port)

print("---------------")

print( "speed_sp=" .. m.speed_sp )

print("\nset rats")
m.rats = 5

print("get rats")
print( m.rats )

print("set mice")
m.mice = 123
print("get mice")
print(m.mice)

print( "count_per_rot=" .. m.count_per_rot )

m.speed_sp = 99

m.duty_cycle_sp = 75

-- print( "read foo" )
-- print(m.foo)

-- This call expects a function back from the __index metamethod.
-- print("call run forever")
-- m:run_forever()



-- pair = "name = Anna"
-- _, _, key, value = string.find(pair, "(%a+)%s*=%s*(%a+)")
-- print(key, value, "foo bars")  --> name  Anna

print("\n\n-- Infrared --")
ir = InfraredSensor:new()
print(ir)
print(ir.connected)
print(ir.address)
print(ir.mode)
print(ir.modes)

ir.mode = InfraredSensor.MODE_PROX

print(ir.mode)
print(ir.cache__mode)

ir.sensorFoo()
ir.deviceFoo()