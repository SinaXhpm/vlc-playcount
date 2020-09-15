FileName = "playcount.txt"
playcountfile=""
lastplay=0
function exportstring( s )
		s = string.format( "%q",s )
		s = string.gsub( s,"\\\n","\\n" )
		s = string.gsub( s,"\r","\\r" )
		s = string.gsub( s,string.char(26),"\"..string.char(26)..\"" )
		return s
end
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
function save2(  tbl,filename )
	local charS,charE = "   ","\n"
	local file,err
	if not filename then
		file =  { write = function( self,newstr ) self.str = self.str..newstr end, str = "" }
		charS,charE = "",""
	elseif filename == true or filename == 1 then
		charS,charE,file = "","",io.tmpfile()
	else
		file,err = io.open( filename, "w" )
		if err then return _,err end
	end
	local tables,lookup = { tbl },{ [tbl] = 1 }
	file:write( "return {"..charE )
	for idx,t in ipairs( tables ) do
		if filename and filename ~= true and filename ~= 1 then
			file:write( "-- Table: {"..idx.."}"..charE )
		end
		file:write( "{"..charE )
		local thandled = {}
		for i,v in ipairs( t ) do
			thandled[i] = true
			if type( v ) ~= "userdata" then
				if type( v ) == "table" then
					if not lookup[v] then
						table.insert( tables, v )
						lookup[v] = #tables
					end
					file:write( charS.."{"..lookup[v].."},"..charE )
				elseif type( v ) == "function" then
					file:write( charS.."loadstring("..exportstring(string.dump( v )).."),"..charE )
				else
					local value =  ( type( v ) == "string" and exportstring( v ) ) or tostring( v )
					file:write(  charS..value..","..charE )
				end
			end
		end
		for i,v in pairs( t ) do
			if (not thandled[i]) and type( v ) ~= "userdata" then
				if type( i ) == "table" then
					if not lookup[i] then
						table.insert( tables,i )
						lookup[i] = #tables
					end
					file:write( charS.."[{"..lookup[i].."}]=" )
				else
					local index = ( type( i ) == "string" and "["..exportstring( i ).."]" ) or string.format( "[%d]",i )
					file:write( charS..index.."=" )
				end
				if type( v ) == "table" then
					if not lookup[v] then
						table.insert( tables,v )
						lookup[v] = #tables
					end
					file:write( "{"..lookup[v].."},"..charE )
				elseif type( v ) == "function" then
					file:write( "loadstring("..exportstring(string.dump( v )).."),"..charE )
				else
					local value =  ( type( v ) == "string" and exportstring( v ) ) or tostring( v )
					file:write( value..","..charE )
				end
			end
		end
		file:write( "},"..charE )
	end
	file:write( "}" )
	if not filename then
		return file.str.."--|"
	elseif filename == true or filename == 1 then
		file:seek ( "set" )
		return file:read( "*a" ).."--|"
	else
		file:close()
		return 1
	end
end
function loadt( sfile )
	local tables, err, _
	if string.sub( sfile,-3,-1 ) == "--|" then
		tables,err = loadstring( sfile )
	else
		tables,err = loadfile( sfile )
	end
	if err then return _,err
	end
	tables = tables()
	for idx = 1,#tables do
		local tolinkv,tolinki = {},{}
		for i,v in pairs( tables[idx] ) do
			if type( v ) == "table" and tables[v[1]] then
				table.insert( tolinkv,{ i,tables[v[1]] } )
			end
			if type( i ) == "table" and tables[i[1]] then
				table.insert( tolinki,{ i,tables[i[1]] } )
			end
		end
		for _,v in ipairs( tolinkv ) do
			tables[idx][v[1]] = v[2]
		end
		for _,v in ipairs( tolinki ) do
			tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
		end
	end
	return tables[1]
end
function descriptor()
  return {
    title = "Play Count",
    version = "1",
    author = "SinaXhpm",
    url = "https://github.com/sinaxhpm/vlc-playcount",
    shortdesc = "Play Counter",
    description = "Count that how much you played a music or video and show it when you activate the extenstion also you can find it in your app data in playcount.txt file(dont change it just READ)",
    capabilities = { "input-listener" }
}
end
function activate()
  local slash = "/"
  if string.match(vlc.config.datadir(), "^(%a:.+)$") then
    slash = "\\"
  elseif string.find(vlc.config.datadir(), 'MacOS') then
    slash = "/"
  else
    slash = "/"
  end
  playcountfile = vlc.config.userdatadir() .. slash .. FileName
  kk = vlc.config.userdatadir() .. slash .. "io.txt"
  local file = io.open(playcountfile,"r")
  if file == nil then
  save2({},playcountfile)
  else 
  	local d = vlc.dialog( "i would playing inna if i was in your place :D" )
	d:add_label("Your Play Counts List ...")
	local dlist = d:add_list(0,0,50,50)
	 for i,v in pairs(loadt(playcountfile)) do
		dlist:add_value(i.." => "..v)
     end	
	 d:show()
  end
    io.close(file)
  return true
end
function meta_changed()
end
function input_changed()
    if vlc.input.is_playing() then
    local item = vlc.item or vlc.input.item()
    if item then
        local title =item:metas().filename:gsub(".mp3","")
        if title ~= nil and os.time() ~= lastplay then
		  local list = loadt(playcountfile)
		  lastplay=os.time()
		  if list[title] then 
			list[title]=list[title]+1
		  else
			list[title]=1
		  end
		  save2(list,playcountfile)
		  end
          return true
    end
  end
end