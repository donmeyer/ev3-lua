-- shell_tools.lua


-- Displays all of the functions and variables defined
function words()
	local seen={}

	function dump(t,i)
		seen[t]=true
		for k,v in pairs(t) do
			print(string.format("%s%s  (%s)",i,k,type(v)))
			--print(i,k)
			if type(v)=="table" and not seen[v] then
				dump(v,i.."\t")
			end
		end
	end

	dump( _G, "" )
end



-- Displays all of the functions and variables defined for a given table
function voc(tt)
	local seen={}

	function dump(t,i)
		seen[t]=true
		for k,v in pairs(t) do
			print(i,k)
			if type(v)=="table" and not seen[v] then
				dump(v,i.."\t")
			end
		end
	end

	dump( tt, "" )
end


-- Displays all of the functions and variables defined for a given table
function dumptable(tt)
	local seen={}
	
	function dump(t,i)
		--print( "..........." )
		seen[t]=true
		for k,v in pairs(t) do
			mt = getmetatable(v)
--			if mt then
--				print( "Metatable!" )
--				dumptable(mt)
--				print( "v==================v" )
--			end
			if type(v)=="table" and not seen[v] then
				print(i..k,"(TABLE)")
				print(i.."{")
				dump(v,i.."\t")
				print(i.."}")
			else
				print( string.format( "%s%s  (%s)  %s", i, k, type(v), tostring(v) ) )
			end
		end
	end

	dump( tt, "" )
end


function dtab(tt)
	for k,v in pairs(tt) do
		print( string.format( "%s  (%s)  %s", k, type(v), tostring(v) ) )
	end
end


function tab(tt)
	for k,v in pairs(tt) do
		print( string.format( "%s  (%s)", k, type(v) ) )
	end
end


function tablekeys2string( t )
	s = ""
	for k,v in pairs(t) do
		s = s .. k .. " "
	end
	return s
end
