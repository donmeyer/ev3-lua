-- testIR.lua
--
-- Assumes a touch sensor as well


ev3 = require 'ev3'


t = ev3.TouchSensor:new()


print("\n\n-- Infrared --")

ir = ev3.InfraredSensor:new()

print(ir)
print(ir.connected)
print(ir.address)
print(ir.mode)
print(ir.modes)

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


print( "Now let's test the IR remote!" )

ir.mode = ir.MODE_REMOTE

while not t:isTouched() do
    -- v = ir.value1
    -- if v ~= 0 then
    --     print( v )
    -- end

    -- Channel number is 1-4. If not given or invalid, uses channel 1.
    v = ir:readRemote(1)
    if v then
        print( v )
    end
end


print( "\n\n Beacon Mode. Turn the beacon off to exit." )

ir.mode = ir.MODE_SEEK

while true do
    -- h = ir.value0
    -- d = ir.value1
    h,d = ir:seek() -- Default to channel 1
    print( h, d )
    if not h then
        print( "No beacon detected")
        break
    end
end
