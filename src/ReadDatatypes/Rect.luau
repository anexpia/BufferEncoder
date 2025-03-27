--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local rectbyte = 28
local writebytesign

return {
    [rectbyte] = @native function(buff: buffer, byte: number, cursor: number): (Rect, number)
        local xmin = buffer.readf32(buff, cursor)
        local ymin = buffer.readf32(buff, cursor + 4)
        local xmax = buffer.readf32(buff, cursor + 8)
        local ymax = buffer.readf32(buff, cursor + 12)

        return Rect.new(xmin, ymin, xmax, ymax), cursor + 16
    end;
} :: datatypedecodinginfo