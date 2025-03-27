--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local udimbyte = 26
local writebytesign

return {
    [udimbyte] = @native function(buff: buffer, byte: number, cursor: number): (UDim, number)
        local scale = buffer.readf32(buff, cursor)
        local offset = buffer.readi32(buff, cursor + 4)

        return UDim.new(scale, offset), cursor + 8
    end;

} :: datatypedecodinginfo