-- testBattery.lua
--


ev3 = require 'ev3'


print("\n\n-- Battery --")

print( "Voltage", ev3.battery.voltage )
print( "Min Voltage", ev3.battery.minVoltage )
print( "Max Voltage", ev3.battery.maxVoltage )
print( "Current", ev3.battery.current )
print( "Is Li-ion", ev3.battery:isLithiumIon() )

