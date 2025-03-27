--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local vectorbyte = 16
local vectorint16byte = 32

local writebytesign

return {
    [vectorbyte] = @native function(buff: buffer, byte: number, cursor: number): (Vector2, number)
        local x = buffer.readf32(buff, cursor)
        local y = buffer.readf32(buff, cursor + 4)

        return Vector2.new(x, y), cursor + 8
    end;

    [vectorint16byte] = @native function(buff: buffer, byte: number, cursor: number): (Vector2int16, number)
        local x = buffer.readi16(buff, cursor)
        local y = buffer.readi16(buff, cursor + 2)

        return Vector2int16.new(x, y), cursor + 4
    end;
} :: datatypedecodinginfo