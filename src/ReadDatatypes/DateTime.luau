--!nolint LocalUnused
--!nolint ImportUnused
--!optimize 2

local Module = script.Parent.Parent
local Types = require(Module.Types)

type datatypedecodinginfo = Types.datatypedecodinginfo

local datetimebyte = 35

return {
    [datetimebyte] = @native function(buff: buffer, byte: number, cursor: number): (DateTime, number)
        local unixmillis = buffer.readf64(buff, cursor)
        return DateTime.fromUnixTimestampMillis(unixmillis), cursor + 8
    end;

} :: datatypedecodinginfo