--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent

local Settings = require(Module.Settings)
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local bufferu8byte = 12
local bufferu16byte = 13
local bufferu32byte = 14

@native
local function readbuffer(buff: buffer, byte: number, cursor: number, info: Types.decodeinfo): (buffer, number)
    local length 
			
    if byte == bufferu8byte then length = buffer.readu8(buff, cursor); cursor += 1
    elseif byte == bufferu16byte then length = buffer.readu16(buff, cursor); cursor += 2
    else length = buffer.readu32(buff, cursor); cursor += 4 end
    
    local value = buffer.create(length)
    buffer.copy(value, 0, buff, cursor, length)

    return value, cursor + length
end

return {
    [bufferu8byte] = readbuffer;
    [bufferu16byte] = readbuffer;
    [bufferu32byte] = readbuffer;
} :: datatypedecodinginfo