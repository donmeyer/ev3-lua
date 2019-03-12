-- cotest2.lua
--
-- This expects to be called from the normal elua application.

function setup()
    co1 = coroutine.create(sub1)
    co2 = coroutine.create(sub2)

    count = 0
end


function mainloop()
    -- print( "Running main")

    -- while true do
        print( "resume sub1")
        stat, a, b = coroutine.resume( co1 )
        print( "sub1 ->", stat, a, b )
        if stat == false then
            print( "sub1 all done" )
            co1 = coroutine.create(sub1)
            count = 0
            -- proc.exit()
        end

        print( "resume sub2")
        stat, a, b = coroutine.resume( co2 )
        print( "sub2 ->", stat, a, b )
    -- end
end


function sub1()
    while count < 3 do
        count = count + 1
        print( "tick", count )
        print("yield sub1")
        -- coroutine.yield("x")
        proc.sleep(1)
        proc.my_yield("x")
    end
    print( "sub1 returning")
end


function sub2()
    while true do
        print("SUB 2 yield")
        -- coroutine.yield("y")
        proc.sleep(1)
        proc.my_yield("y")
    end
end
