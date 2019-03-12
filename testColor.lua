-- testColor.lua
--
-- Assumes a touch sensor as well


ev3 = require 'ev3'


t = ev3.TouchSensor:new()


print("\n\n-- Color --")

color = ev3.ColorSensor:new()

print(color)
print(color.connected)
print(color.address)
print(color.mode)
print(color.modes)


print( "Waiting for color value >50. Touch to take reading.")
color.mode = ev3.ColorSensor.MODE_REFLECTED
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
