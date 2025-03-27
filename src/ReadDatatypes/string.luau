--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local stringsalwayslengthbound = Settings.stringsalwayslengthbound

local stringzeroterminatedbyte = 4
local stringu8byte = 41
local stringu16byte = 42
local stringu32byte = 43

local writebytesign

return {
	[stringzeroterminatedbyte] = @native function(buff: buffer, byte: number, cursor: number, info): (string, number)
		local stringform = info.bufferstring
		if not stringform then 
			stringform = buffer.tostring(buff)
			info.bufferstring = stringform
		end
		
		cursor += 1
		local jumpto = string.find(stringform, "\0", cursor, true)

		if jumpto then return string.sub(stringform, cursor, jumpto - 1), jumpto
		else error("couldn't find next zero byte for while reading zero-terminated string") end	
	end;

	[stringu8byte] = @native function(buff: buffer, byte: number, cursor: number): (string, number)
		local length = buffer.readu8(buff, cursor); cursor += 1
		return buffer.readstring(buff, cursor, length), cursor + length
	end;

	[stringu16byte] = @native function(buff: buffer, byte: number, cursor: number): (string, number)
		local length = buffer.readu16(buff, cursor); cursor += 2
		return buffer.readstring(buff, cursor, length), cursor + length
	end;

	[stringu32byte] = @native function(buff: buffer, byte: number, cursor: number): (string, number)
		local length = buffer.readu32(buff, cursor); cursor += 4
		return buffer.readstring(buff, cursor, length), cursor + length
	end;

} :: datatypedecodinginfo