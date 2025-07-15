--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)
local Miscellaneous = require(Module.Miscellaneous)
type datatypedecodinginfo = Types.datatypedecodinginfo

local readf16 = Miscellaneous.readf16

local numberbyte = 22
local writebytesign

local uI16_max = (2 ^ 16) - 1

return {            
	[numberbyte] = @native function(buff: buffer, byte: number, cursor: number): (NumberSequence, number)
		local length = buffer.readu8(buff, cursor); cursor += 1
		local tbl = table.create(length)
		
		for i = 1, length do 
			local time = math.clamp(buffer.readu16(buff, cursor) / uI16_max, 0, 1)
			local value = buffer.readf32(buff, cursor + 2)
			local envelope = readf16(buff, cursor + 6); cursor += 8
			
			tbl[i] = NumberSequenceKeypoint.new(time, value, envelope)
		end
		
		return NumberSequence.new(tbl), cursor
	end;
} :: datatypedecodinginfo