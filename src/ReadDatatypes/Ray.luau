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
	[raybyte] = @native function(buff: buffer, byte: number, cursor: number, info: Types.decodeinfo): (Ray, number)
		local ox = buffer.readf32(buff, cursor); cursor += 4
		local oy = buffer.readf32(buff, cursor); cursor += 4
		local oz = buffer.readf32(buff, cursor); cursor += 4
		local dx = buffer.readf32(buff, cursor); cursor += 4
		local dy = buffer.readf32(buff, cursor); cursor += 4
		local dz = buffer.readf32(buff, cursor); cursor += 4

		if info.sanitize_nanandinf then
            if (ox / ox) ~= 1 then ox = 0 end
            if (oy / oy) ~= 1 then oy = 0 end
            if (oz / oz) ~= 1 then oz = 0 end
			if (dx / dx) ~= 1 then dx = 0 end
            if (dy / dy) ~= 1 then dy = 0 end
            if (dz / dz) ~= 1 then dz = 0 end
        end

		return Ray.new(Vector3.new(ox, oy, oz), Vector3.new(dx, dy, dz)), cursor
	end;
} :: datatypedecodinginfo