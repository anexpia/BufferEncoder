--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local brickcolorbyte = 30

return {
    [brickcolorbyte] = @native function(buff: buffer, byte: number, cursor: number): (BrickColor, number)
        return BrickColor.new(buffer.readu16(buff, cursor)), cursor + 2
    end;
} :: datatypedecodinginfo