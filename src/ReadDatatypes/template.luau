--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local templatebyte = -1
local writebytesign

return {
    [templatebyte] = @native function(buff: buffer, byte: number, cursor: number): (any, number, boolean?)
        error('Byte read function should be changed for the template.', 0)
    end;

} :: datatypedecodinginfo