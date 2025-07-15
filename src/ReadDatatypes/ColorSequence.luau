--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local colorbyte = 25

local uI16_max = (2 ^ 16) - 1

return {            
    [colorbyte] = @native function(buff: buffer, byte: number, cursor: number): (ColorSequence, number)
		local length = buffer.readu8(buff, cursor); cursor += 1
		local tbl = table.create(length)

		for i = 1, length do 
			local time = math.clamp(buffer.readu16(buff, cursor) / uI16_max, 0, 1)
			local r, g, b = buffer.readu8(buff, cursor + 2), buffer.readu8(buff, cursor + 3), buffer.readu8(buff, cursor + 4); cursor += 5
		
			tbl[i] = ColorSequenceKeypoint.new(time, Color3.fromRGB(r, g, b))
		end
		
		return ColorSequence.new(tbl), cursor
	end;
} :: datatypedecodinginfo