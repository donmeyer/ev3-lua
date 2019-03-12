-- testSound.lua
--


ev3 = require 'ev3'


print("\n\n-- Sound --")

print( "beep")
ev3.beep()
print( "end beep\n" )

print( "beep 800")
ev3.beep( 800, 0.5 )
print( "end beep 800" )
