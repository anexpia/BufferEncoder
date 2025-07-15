--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local contentbyte = 33
local fontbyte = 34
local writebytesign

local FromValue = (Enum.FontWeight :: any).FromValue -- localizing it to silence errors 😭

return {
    [contentbyte] = @native function(buff: buffer, byte: number, cursor: number): (Content, number)
		local length = buffer.readu8(buff, cursor); cursor += 1

		if length == 0 then 
			return Content.none, cursor
		elseif length == 1 then
			local num = buffer.readf64(buff, cursor)
			return Content.fromAssetId(num), cursor + 8
		else
			length -= 1
			
			local uri = buffer.readstring(buff, cursor, length)
			return Content.fromUri(uri), cursor + length
		end
	end;

	[fontbyte] = @native function(buff: buffer, byte: number, cursor: number): (Font, number)
		local length = buffer.readu8(buff, cursor); cursor += 1

		if length == 0 then 
			local num = buffer.readf64(buff, cursor); cursor += 8

			local weightv, stylev = buffer.readu16(buff, cursor), buffer.readu8(buff, cursor + 2)
			return Font.fromId(num, FromValue(Enum.FontWeight, weightv), FromValue(Enum.FontStyle, stylev)), cursor + 3
		else
			length -= 1
			local familyname = buffer.readstring(buff, cursor, length); cursor += length
			if familyname == "" then familyname = "Arimo" end 

			local weightv, stylev = buffer.readu16(buff, cursor), buffer.readu8(buff, cursor + 2)
			-- not using FromName because familyname can be empty
			return Font.new(`rbxasset://fonts/families/{familyname}.json`, FromValue(Enum.FontWeight, weightv), FromValue(Enum.FontStyle, stylev)), cursor + 3
		end
	end;
} :: datatypedecodinginfo