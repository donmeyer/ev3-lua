-- robot2.lua
--
-- Co-routines


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

    touch = ev3.TouchSensor:new()

    count = 0

    motor_co = coroutine.create(motor_routine)
    sensor_co = coroutine.create(sensor_routine)

    motor_cmd = nil
end


function event_handler( name, data )
    if name == "timer" then
        log.print( "Timer fired " .. count )
    end

    if name == "timeout" then
        log.print( "Timeout fired " .. count )
    end
end



function mainloop()
    count = count + 1

    coroutine.resume( sensor_co )

    -- Run the motor command coroutine. We don't check for return values as this
    -- routine will never terminate.
    coroutine.resume( motor_co )
end



function sensor_routine()
    while true do
        dist = ir:readDistance()
        -- print( dist )
        if dist < 30 then
            motor_cmd = "backup"
        else
            motor_cmd = "forward"
        end

        if touch:isTouched() then
            motor_cmd = "stop"
            -- Wait for the command to be complete
            while motor_cmd do
                coroutine.yield()
            end
            proc.exit()    
        end

        coroutine.yield()
    end
end

problem is if we back up and still sensor < 30 we just stop moving

-- Set up a coroutine that is responsible for executing all motor commands.
-- Looks at the motor_cmd variable to tell what command to run next.
function motor_routine()
    local cur_cmd = ""
    while true do
        if motor_cmd and ( motor_cmd ~= cur_cmd ) then
            -- new command
            print( "New command", motor_cmd )
            cur_cmd = motor_cmd
            if motor_cmd == "forward" then
                runForward()
            elseif motor_cmd == "backup" then
                print( "Backing up...")
                backup()
            elseif motor_cmd == "stop" then
                for n,m in ipairs(motors) do
                    m:stop()
                end
            end

            motor_cmd = nil
        end

        coroutine.yield()
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
    print( "Waiting for motors to finish moving")
    for n,m in ipairs(motors) do
        -- Wait for the motor to finish moving
        while m:isRunning() do
            coroutine.yield()
        end
    end
    print( "motors done moving" )
end
