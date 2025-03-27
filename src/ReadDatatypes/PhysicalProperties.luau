--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local physpropsbyte = 29
local writebytesign

return {
    [physpropsbyte] = @native function(buff: buffer, byte: number, cursor: number): (PhysicalProperties, number)
        local Density = buffer.readf32(buff, cursor)
        local Friction = buffer.readf32(buff, cursor + 4)
        local Elasticity = buffer.readf32(buff, cursor + 8)
        local FrictionWeight = buffer.readf32(buff, cursor + 12)
        local ElasticityWeight = buffer.readf32(buff, cursor + 16)
        
        return PhysicalProperties.new(Density, Friction, Elasticity, FrictionWeight, ElasticityWeight),
            cursor + 20
    end;
} :: datatypedecodinginfo