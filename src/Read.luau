--!native
--!optimize 2
--!nolint LocalShadow

--[[ ## made by anexpia •…• ## ]]

local Encoder = script.Parent

local Datatypes = require(Encoder.ReadDatatypes)
local RbxEnumEncoder = require(Encoder.RbxEnumEncoder)
local Settings = require(Encoder.Settings)
local Types = require(Encoder.Types)

type ReadSettings = Types.ReadSettings

local defaultwritingtable = {}

--[[
Decodes the buffer created by encoder.write()

<em>param</em> - buff : the buffer to decode
<em>param</em> - readstart : reading starts from the offset given.
<em>param</em> - readsettings : {
. <strong>allowdeduplication: boolean</strong> -- if the buffer was written with deduplication enabled
. <strong>references: {any}</strong> -- table of values that couldn't be encoded which is returned by encoder.write()
. <strong>shiftseed: number</strong> -- the type bytes of values are unshuffled using the seed.
. <strong>rbxenum_behavior: "full" | "compact"</strong> -- override for the default setting.
. <strong>sanitize_nanandinf: boolean</strong> -- override for the default setting.
}
]]
return function(buff: buffer, readstart: number?, readsettings: ReadSettings?): { [any]: any }
	local readsettings: ReadSettings = readsettings or Settings

	local shiftseed = readsettings.shiftseed
	local dedupenabled = readsettings.allowdeduplication

	local cursor = readstart or 0
	local isdoingdeduplication_old = false

	do
		local firstbyte = buffer.readu8(buff, cursor)
		if shiftseed then
			math.randomseed(shiftseed)
			firstbyte = (firstbyte - math.random(1, 127)) % 128
			math.randomseed(shiftseed)
		end

		if firstbyte == 101 then
			return {}
		elseif firstbyte > 1 then
			error(`expected '0', '1', or '101' for first byte, got {firstbyte}`)
		end

		isdoingdeduplication_old = firstbyte == 0
		if isdoingdeduplication_old then dedupenabled = false end
	end

	local enumbehavior = RbxEnumEncoder.getBehaviorFromSetting(readsettings)
	local sanitize_nanandinf = readsettings.sanitize_nanandinf
	if sanitize_nanandinf == nil then sanitize_nanandinf = Settings.sanitize_nanandinf end

	Datatypes.adjustforsettings(enumbehavior, sanitize_nanandinf)

	local deduplicationindex = 0
	local deduplicationtable = if dedupenabled then {} else nil
	local currenttable = {}
	local maintable = currenttable
	
	local writingtable = defaultwritingtable

	local formedtables = {currenttable}
	local formedcount = 0

	local lastwasdictkey = false
	local dictkey = nil
	local currentindex = 0

	local info: Types.decodeinfo = {
		sanitize_nanandinf = sanitize_nanandinf,
		references = readsettings.references,

		deduplicationtable = deduplicationtable,
		tables = formedtables,
	}

	while cursor <= (buffer.len(buff) - 1) do
		local byte = buffer.readu8(buff, cursor)
		cursor += 1

		local isdictkey = byte > 127
		if isdictkey then
			byte = (255 - byte)
		end

		if shiftseed then
			byte = (byte - math.random(1, 127)) % 128
		end

		local value: any, canbededuplicated: boolean?

		local func = Datatypes[byte]
		if func then
			value, cursor, canbededuplicated = func(buff, byte, cursor, info)
		elseif byte == 1 then 
			formedcount += 1
			
			if currentindex > 0 then
				table.move(writingtable, 1, currentindex, 1, currenttable)
				currentindex = 0
			end
			
			currenttable = formedtables[formedcount]
			if currenttable == nil then
				currenttable = {}
				formedtables[formedcount] = currenttable
			end

			lastwasdictkey = false
			dictkey = nil

			continue
		elseif byte == 0 then
			if isdoingdeduplication_old then
				isdoingdeduplication_old = false

				currenttable = {}
				deduplicationtable = currenttable
				info.deduplicationtable = deduplicationtable

				continue
			else
				if shiftseed then math.randomseed(os.time()) end
				
				if currentindex > 0 then
					table.move(writingtable, 1, currentindex, 1, currenttable)
				end
				
				table.clear(writingtable)
				return maintable
			end
		elseif byte == 101 then value = {}
		elseif byte ~= 4 then -- not nil
			error(`{byte} is not a type byte`)
		end

		if dedupenabled and canbededuplicated then
			deduplicationindex += 1
			deduplicationtable[deduplicationindex] = value
		end

		if lastwasdictkey then
			lastwasdictkey = false

			if dictkey ~= nil then
				currenttable[dictkey] = value
				dictkey = nil
			end
		elseif isdictkey then
			dictkey = value
			lastwasdictkey = true
		else
			currentindex += 1
			writingtable[currentindex] = value
		end
	end

	if shiftseed then math.randomseed(os.time()) end

	error("buffer is not terminated with '0' byte", 0)
end
