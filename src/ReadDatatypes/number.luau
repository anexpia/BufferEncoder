--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)
local Enums = require(Module.Enums)

local bytetovalue = Enums.bytetovalue

type datatypedecodinginfo = Types.datatypedecodinginfo

local nanbyte = 108

local u8numbyte = 5
local n_u8numbyte = 8

local u16numbyte = 6
local n_u16numbyte = 9

local u32numbyte = 7
local n_u32numbyte = 10

local floatnumbyte = 11

local writebytesign

local t = {
	[u8numbyte] = @native function(buff: buffer, byte: number, cursor: number): (any, number)
		return buffer.readu8(buff, cursor), cursor + 1
	end;
	[n_u8numbyte] = @native function(buff: buffer, byte: number, cursor: number): (any, number)
		return -buffer.readu8(buff, cursor), cursor + 1
	end;

	[u16numbyte] = @native function(buff: buffer, byte: number, cursor: number): (any, number)
		return buffer.readu16(buff, cursor), cursor + 2
	end;
	[n_u16numbyte] = @native function(buff: buffer, byte: number, cursor: number): (any, number)
		return -buffer.readu16(buff, cursor), cursor + 2
	end;

	[u32numbyte] = @native function(buff: buffer, byte: number, cursor: number): (any, number)
		return buffer.readu32(buff, cursor), cursor + 4
	end;
	[n_u32numbyte] = @native function(buff: buffer, byte: number, cursor: number): (any, number)
		return -buffer.readu32(buff, cursor), cursor + 4
	end;

	[floatnumbyte] = @native function(buff: buffer, byte: number, cursor: number): (any, number)
		return buffer.readf64(buff, cursor), cursor + 8
	end;
}

t.readnumber_compact = @native function(buff: buffer, byte: number, cursor: number): (number, number)
	if byte == 11 then
		return buffer.readf32(buff, cursor), cursor + 4
	else 
		local func = t[byte]
		if func then return func(buff, byte, cursor) end 

		local value = bytetovalue[byte]
		if value then return value, cursor end

		error(`{byte} is not a correct number byte`)
	end
end

return t 