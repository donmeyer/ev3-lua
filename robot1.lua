

ev3 = require 'ev3'

-- This is called only *once* when the application first starts.
-- Subsequent reloads of the main Lua script will not cause this to run.
function setup()
	-- Variables defined here will survive a script reload.
	-- Note that if new "permanent" variables are needed, the Lua state must be restarted,
	-- a script update will not be sufficient.

	log.print( "Robot script setup() function running" )
	
    proc.set_timer( 10 )
    
    proc.set_timeout( 13 )

    
    m1 = ev3.Motor:new( 'D' )
    m2 = ev3.Motor:new('C' )

    motors = { m1, m2 }

    for n,m in ipairs(motors) do
        print(m)
        m.stop_action=m.STOP_ACTION_HOLD
    end

    ir = ev3.InfraredSensor:new()
    print(ir)
    ir.mode = ir.MODE_PROX

    count = 0
end



function event_handler( name, data )
    if name == "timer" then
        log.print( "Timer fired " .. count )
    end

    if name == "timeout" then
        log.print( "Timeout fired " .. count )
    end
end



state = 'none'

function mainloop()
    count = count + 1
    
    if state == 'none' then
        print( "Run forward" )
        runForward()
        state = 'fwd'
    elseif state == 'fwd' then
        -- Check the IR sensor
        dist = ir:readDistance()
        -- print( dist )
        if dist < 30 then
            print( "Backing up...")
            backup()
            state = 'none'
        end
    end
end


function runForward()
    for n,m in ipairs(motors) do
        m.speed_sp=100
        m:run_forever()
    end
end


function backup()
    for n,m in ipairs(motors) do
        m:stop()
    end

    for n,m in ipairs(motors) do
        m.time_sp=1000
        m.speed_sp=-200
        m:run_timed()
    end

    waitForMotors()
end


function waitForMotors()
    for n,m in ipairs(motors) do
        while m:isRunning() do end  -- Wait for the motor to finish moving
    end
end
