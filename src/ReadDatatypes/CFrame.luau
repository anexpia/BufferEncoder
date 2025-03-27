--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)
local Miscellaneous = require(Module.Miscellaneous)

type datatypedecodinginfo = Types.datatypedecodinginfo

local cframebyte = 17

return {
    [cframebyte] = Miscellaneous.readCFrame
 
} :: datatypedecodinginfo