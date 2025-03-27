--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local udim2byte = 27
local writebytesign

return {
    [udim2byte] = @native function(buff: buffer, byte: number, cursor: number): (UDim2, number)
        local xscale = buffer.readf32(buff, cursor)
        local xoffset = buffer.readi32(buff, cursor + 4)
        local yscale = buffer.readf32(buff, cursor + 8)
        local yoffset = buffer.readi32(buff, cursor + 12)
        
        return UDim2.new(xscale, xoffset, yscale, yoffset), cursor + 16
    end;

} :: datatypedecodinginfo