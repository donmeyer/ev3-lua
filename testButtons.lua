-- testButtons.lua
--


ev3 = require 'ev3'


print("\n\n-- Buttons --")

while true do
    b = ev3.readButtons()
    print( "Button read", b )
end