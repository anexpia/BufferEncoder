--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent
local ByteToValue = require(Module.Enums).bytetovalue
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local tblu8byte = 51
local tblu16byte = 52
local tblu32byte = 53
local dedupu8byte = 54
local dedupu16byte = 55
local dedupu32byte = 56

local customvaluebyte = 99
local nilbyte = 100
local emptytablebyte = 101

@native
local function readtable(buff: buffer, byte: number, cursor: number, info: Types.decodeinfo)
    local index 
			
    if byte == tblu8byte then index = buffer.readu8(buff, cursor); cursor += 1
    elseif byte == tblu16byte then index = buffer.readu16(buff, cursor); cursor += 2
    else index = buffer.readu32(buff, cursor); cursor += 4 end
    
    local formedtables = info.tables
    local f = formedtables[index]

    if f then return f, cursor
    else 
        local value = {}
        formedtables[index] = value

        return value, cursor
    end
end

@native
local function readdeduplicate(buff: buffer, byte: number, cursor: number, info: Types.decodeinfo)
    local index 
			
    if byte == dedupu8byte then index = buffer.readu8(buff, cursor); cursor += 1
    elseif byte == dedupu16byte then index = buffer.readu16(buff, cursor); cursor += 2
    else index = buffer.readu32(buff, cursor); cursor += 4 end
    
    return info.deduplicationtable[index], cursor
end

local t = {
    [tblu8byte] = readtable;
    [tblu16byte] = readtable;
    [tblu32byte] = readtable;

    [dedupu8byte] = readdeduplicate;
    [dedupu16byte] = readdeduplicate;
    [dedupu32byte] = readdeduplicate;

    [customvaluebyte] = @native function(buff: buffer, byte: number, cursor: number)
		return ByteToValue[-buffer.readu8(buff, cursor)], cursor
    end,

--[[[nilbyte] = function(buff: buffer, byte: number, cursor: number): (any, number)
        return nil, cursor
    end;

    [emptytablebyte] = function(buff: buffer, byte: number, cursor: number): (any, number)
        return {}, cursor
    end;]]
} :: datatypedecodinginfo

-- doing those here so theres no cost for indexing ByteToValue
for byte, v in ByteToValue do 
    if byte > 0 then
        -- this runs somehow faster with native .... ok i guess
        t[byte] = @native function(buff, byte, cursor) return v, cursor end
    end
end

return t