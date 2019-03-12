-- Run by the hacked elua application that calls sub1 and sub2 directly.

count = 0

function sub1()
    -- while count < 3 do
    while true do
        count = count + 1
        print( "tick", count )
        print("yield sub1")
        -- coroutine.yield("x")
        proc.sleep(1)
        proc.my_yield()
    end
    print( "sub1 returning")
end


function sub2()
    while true do
        proc.sleep(2)
        print("SUB 2 yield")
        -- coroutine.yield("x")
        proc.my_yield()
        print( "New after yield!!!!!!! yowza" )
    end
end

So we need to have the coroutines actually terminate and then have them re-created and see if that
    uses the re-loaded versions. And does it reload all of them at once or staggered as they terminate?