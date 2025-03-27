--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local raybyte = 18
local writebytesign

return {
	[raybyte] = @native function(buff: buffer, byte: number, cursor: number): (Ray, number)
		local ox = buffer.readf32(buff, cursor); cursor += 4
		local oy = buffer.readf32(buff, cursor); cursor += 4
		local oz = buffer.readf32(buff, cursor); cursor += 4
		local dx = buffer.readf32(buff, cursor); cursor += 4
		local dy = buffer.readf32(buff, cursor); cursor += 4
		local dz = buffer.readf32(buff, cursor); cursor += 4

		return Ray.new(Vector3.new(ox, oy, oz), Vector3.new(dx, dy, dz)), cursor
	end;
} :: datatypedecodinginfo