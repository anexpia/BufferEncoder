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
	[u8numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
		return buffer.readu8(buff, cursor), cursor + 1
	end;
	[n_u8numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
		return -buffer.readu8(buff, cursor), cursor + 1
	end;

	[u16numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
		return buffer.readu16(buff, cursor), cursor + 2, true
	end;
	[n_u16numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
		return -buffer.readu16(buff, cursor), cursor + 2, true
	end;

	[u32numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
		return buffer.readu32(buff, cursor), cursor + 4, true
	end;
	[n_u32numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
		return -buffer.readu32(buff, cursor), cursor + 4, true
	end;
}

if Settings.sanitize_nanandinf then
	t[floatnumbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
		local n = buffer.readf64(buff, cursor)
		return if (n / n) ~= 1 then 0 else n, cursor + 8, true
	end
else 
	t[floatnumbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
		return buffer.readf64(buff, cursor), cursor + 8, true
	end
end

return t  