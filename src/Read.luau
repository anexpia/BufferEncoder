--!native
--!optimize 2

--[[ ## made by anexpia •…• ## ]]

local Datatypes = require(script.Parent.ReadDatatypes)
local Types = require(script.Parent.Types)

--[[
Decodes the buffer created by encoder.write()
parameters should be consistent with encoder.write().
]]

local defaultwritingtable = {}
return function(buff: buffer, readstart: number?, references: { any }?, dedupenabled: boolean?, shiftseed: number?): { [any]: any }
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
		stringform = nil,
		deduplicationtable = deduplicationtable,
		references = references,
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

	error("buffer is not terminated with zero byte", 0)
end
