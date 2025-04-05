--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local stringu8byte = 54
local stringu16byte = 55
local stringu32byte = 56

local writebytesign

return {
	[stringu8byte] = @native function(buff: buffer, byte: number, cursor: number): (string, number, boolean?)
		local length = buffer.readu8(buff, cursor); cursor += 1
		return buffer.readstring(buff, cursor, length), cursor + length, true
	end;

	[stringu16byte] = @native function(buff: buffer, byte: number, cursor: number): (string, number, boolean?)
		local length = buffer.readu16(buff, cursor); cursor += 2
		return buffer.readstring(buff, cursor, length), cursor + length, true
	end;

	[stringu32byte] = @native function(buff: buffer, byte: number, cursor: number): (string, number, boolean?)
		local length = buffer.readu32(buff, cursor); cursor += 4
		return buffer.readstring(buff, cursor, length), cursor + length, true
	end;

} :: datatypedecodinginfo