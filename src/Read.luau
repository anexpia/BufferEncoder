--!native
--!optimize 2

--[[ ## made by anexpia •…• ## ]]

local Datatypes = require(script.Parent.ReadDatatypes)
local Types = require(script.Parent.Types)
local Settings = require(script.Parent.Settings)

local readreference = buffer[`readu{Settings.referencebitsize}`]
local referencesize = Settings.referencebitsize // 8

--[[
Decodes the buffer created by encoder.write()
parameters should be consistent with encoder.write().
]]
return function(buff: buffer, readstart: number?, references: { any }?, shiftby: number?): { [any]: any }
	local cursor = readstart or 0
	local isdoingdeduplication = false

	do
		local firstbyte = buffer.readu8(buff, cursor)
		if shiftby then
			firstbyte = (firstbyte - shiftby) % 128
		end

		if firstbyte == 101 then
			return {}
		elseif firstbyte > 1 then
			error(`expected '0', '1', or '101' for first byte, got {firstbyte}`)
		end

		isdoingdeduplication = firstbyte == 0
	end

	local deduplicationtable
	local currenttable = {}
	local maintable = currenttable

	local formedtables = {currenttable}
	local formedcount = 0

	local lastwasdictkey = false
	local dictkey = nil
	local currentindex = 0

	local info: Types.decodeinfo = {
		stringform = nil,
		deduplicationtable = nil :: any,
		tables = formedtables,
	}

	while cursor <= (buffer.len(buff) - 1) do
		local byte = buffer.readu8(buff, cursor)
		cursor += 1

		local isdictkey = byte > 127
		if isdictkey then
			byte = (255 - byte)
		end

		if shiftby then
			byte = (byte - shiftby) % 128
		end

		local value: any

		local func = Datatypes[byte]
		if func then
			value, cursor = func(buff, byte, cursor, info)
		elseif byte == 1 then 
			formedcount += 1

			currenttable = formedtables[formedcount]
			if currenttable == nil then
				currenttable = {}
				formedtables[formedcount] = currenttable
			end

			currentindex = 0
			isdictkey = false
			dictkey = nil

			continue
		elseif byte == 0 then
			if isdoingdeduplication then
				isdoingdeduplication = false

				currenttable = {}
				deduplicationtable = currenttable
				info.deduplicationtable = deduplicationtable

				continue
			else
				return maintable
			end
		elseif byte == 50 then -- references
			local index = readreference(buff, cursor)
			cursor += referencesize
			
			value = (references :: { any })[index]
		elseif byte == 101 then value = {}
		elseif byte == 100 then
			-- can never be dict key
			if lastwasdictkey then lastwasdictkey = false 
			else currentindex += 1 end 

			continue
		else
			error(`{byte} is not a type byte`)
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
			currenttable[currentindex] = value
		end
	end

	error("buffer is not terminated with zero byte", 0)
end
