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
    [vectorbyte] = @native function(buff: buffer, byte: number, cursor: number): (vector, number)
        local x = buffer.readf32(buff, cursor)
        local y = buffer.readf32(buff, cursor + 4)
        local z = buffer.readf32(buff, cursor + 8)

        return vector.create(x, y, z), cursor + 12
    end;

    [vectorint16byte] = @native function(buff: buffer, byte: number, cursor: number): (Vector3int16, number)
        local x = buffer.readi16(buff, cursor)
        local y = buffer.readi16(buff, cursor + 2)
        local z = buffer.readi16(buff, cursor + 4)

        return Vector3int16.new(x, y, z), cursor + 6
    end;
} :: datatypedecodinginfo