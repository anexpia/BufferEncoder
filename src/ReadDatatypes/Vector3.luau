--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local vectorbyte = 15
local vectorint16byte = 31

local writebytesign

return {
    [vectorbyte] = @native function(buff: buffer, byte: number, cursor: number, info: Types.decodeinfo): (vector, number, boolean?)
        local x = buffer.readf32(buff, cursor)
        local y = buffer.readf32(buff, cursor + 4)
        local z = buffer.readf32(buff, cursor + 8)

        -- need to check if deduplication is possible as if nan exists, the vector
        -- cannot be deduplicated during writing process, thus would cause value positions to get shifted
        local candeduplicate = x == x and y == y and z == z

		if info.sanitize_nanandinf then
			if (x / x) ~= 1 then x = 0 end
			if (y / y) ~= 1 then y = 0 end
			if (z / z) ~= 1 then z = 0 end
        end

        return vector.create(x, y, z), cursor + 12, candeduplicate
    end;

    [vectorint16byte] = @native function(buff: buffer, byte: number, cursor: number): (Vector3int16, number)
        local x = buffer.readi16(buff, cursor)
        local y = buffer.readi16(buff, cursor + 2)
        local z = buffer.readi16(buff, cursor + 4)

        return Vector3int16.new(x, y, z), cursor + 6
    end;
} :: datatypedecodinginfo