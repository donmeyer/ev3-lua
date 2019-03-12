-- test.lua
--


ev3 = require 'ev3'


print("\n\n-- Touch --")

t = ev3.TouchSensor:new()

print( t)

print(t.value0)

cnt = 0
while t:isTouched() == false do
    cnt = cnt + 1
    -- print(ir.value0)
end
while t:isTouched() do end  -- Once per touch!

print( "Touched!")
print(cnt)



