--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local numberbyte = 21
local writebytesign

return {
    [numberbyte] = @native function(buff: buffer, byte: number, cursor: number): (NumberRange, number)
        local min = buffer.readf32(buff, cursor)
        local max = buffer.readf32(buff, cursor + 4)

        return NumberRange.new(min, max), cursor + 8
    end;
} :: datatypedecodinginfo