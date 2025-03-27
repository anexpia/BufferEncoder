--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)
local RbxEnumEncoder = require(Module.RbxEnumEncoder)

type datatypedecodinginfo = Types.datatypedecodinginfo

local enumbyte = 19
local enumitembyte = 20

return {
    [enumbyte] = RbxEnumEncoder.decodeEnum;
    [enumitembyte] = RbxEnumEncoder.decodeEnumItem;
} :: datatypedecodinginfo