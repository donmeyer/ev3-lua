-- proctest.lua




-- Perform the initial program setup.
--
-- This is called only *once* when the application first starts.
-- Subsequent reloads of the main Lua script will not cause this to run.
--
function setup()
	-- Variables defined here will survive a script reload.
	-- Note that if new "permanent" variables are needed, the Lua state must be restarted,
	-- a script update will not be sufficient.

	log.print( "Script setup() function running" )

    count = 0
	
--	x = proc.get_timer()
--	print( "Timer started out at", x )

    proc.set_timer( 10 )
    
    proc.set_timeout( 13 )

end


-- Handle process events
--
-- Currently there are two events generated by the p;rocess wrapper:
--   timer - 
--   timeout - 
--
function event_handler( name, data )
    if name == "timer" then
        log.print( "Timer fired " .. count )
    end

    if name == "timeout" then
        log.print( "Timeout fired " .. count )
    end
end


-- The program main loop.
--
-- This is called continuously as the program runs.
-- Note that this MUST return as often as possible to allow other events such as 'timer'
-- and script reloads to occur.
--
function mainloop()
    -- print( "mainloop entered" )
    count = count + 1
    if (count % 100) == 0 then
        print( count )
    end

    if count == 500 then
        proc.set_cycle_time( 0.5 )
    end
    
    if count > 550 then
        print( "All done!" )
        proc.exit(0)
    end
end
