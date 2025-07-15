--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)
local Miscellaneous = require(Module.Miscellaneous)

local color3always6bytes = Settings.color3always6bytes
local readf16 = Miscellaneous.readf16

type datatypedecodinginfo = Types.datatypedecodinginfo

local u8colorbyte = 23
local f16colorbyte = 24

local writebytesign

return {
	[u8colorbyte] = @native function(buff: buffer, byte: number, cursor: number): (Color3, number)
		local r, g, b = buffer.readu8(buff, cursor), buffer.readu8(buff, cursor + 1), buffer.readu8(buff, cursor + 2)
		return Color3.fromRGB(r, g, b), cursor + 3
	end;

	[f16colorbyte] = @native function(buff: buffer, byte: number, cursor: number): (Color3, number)
		local r, g, b = readf16(buff, cursor), readf16(buff, cursor + 2), readf16(buff, cursor + 4)
		return Color3.new(r, g, b), cursor + 6
	end;
} :: datatypedecodinginfo