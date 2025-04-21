--!optimize 2

--[[ 
	## made by anexpia •…• ## 

	this has 2 behaviors currently.
	>  "full"
		encodes the enums as <19> <u8 length> <string>
		enumitems are <20> <u8 length> <string> <u16 value> 

		* encoded values are deduplicated, so if the same enum & enumitem are encoded multiple times
		it will not cost the same to encode it each time

	> "compact" *default behavior*
		this should ONLY BE USED for sending the enums & enumitems between remotes!!!
		the order of the enum & enumitem table is not guaranteed to be consistent between
		every version and such you will definitely encounter bugs if you use this for saving data

		* no deduplication since there's no benefit, as this saves as 3 bytes
]]

local RS = game:GetService("RunService")
local Settings = require(script.Parent.Settings)

local enumitem_to_type = {}
local enumitem_to_value = {}


local exposed = {
	enumitem_to_type = enumitem_to_type;
	enumitem_to_value = enumitem_to_value;
}

for _, enum in Enum:GetEnums() do 
	local n = tostring(enum)

	enumitem_to_type[enum] = n
	
	for _, enumitem in enum:GetEnumItems() do 
		enumitem_to_type[enumitem] = n
		enumitem_to_value[enumitem] = enumitem.Value 
	end
end

-- encode enums as <19> <u8 length> <string>
-- encode enumitems as <20> <u8 length> <string> <u16 value>
if Settings.rbxenum_behavior == "full" then
	local nametoenum = {}
	for _, v in Enum:GetEnums() do
		nametoenum[tostring(v)] = v
	end
	-- this is to avoid erroring due to version mismatch when decoding

	local enum_FromValue = (Enum.Material :: any).FromValue

	@native
	function exposed.encodeEnum(buf: buffer, offset: number, enum: Enum): number
		local name = enumitem_to_type[enum]
		local length = #name

		buffer.writeu8(buf, offset, length); offset += 1
		buffer.writestring(buf, offset, name)

		return offset + length
	end

	@native
	function exposed.encodeEnumItem(buf: buffer, offset: number, enumitem: EnumItem): number
		offset = exposed.encodeEnum(buf, offset, enumitem :: any)
		buffer.writeu16(buf, offset, enumitem_to_value[enumitem])

		return offset + 2
	end

	@native
	function exposed.decodeEnum(buf: buffer, byte: number, cursor: number): (Enum, number, boolean?)
		local length = buffer.readu8(buf, cursor); cursor += 1
		local name = buffer.readstring(buf, cursor, length)

		return nametoenum[name], cursor + length, true
	end

	@native
	function exposed.decodeEnumItem(buf: buffer, byte: number, cursor: number): (EnumItem, number, boolean?)
		local enum, newcursor = exposed.decodeEnum(buf, byte, cursor)
		local value = buffer.readu16(buf, newcursor)

		return enum and enum_FromValue(enum, value), newcursor + 2, true
	end

	-- encode enums as <19> <u16 index>
	-- encode enumitems as <20> <u16 index>
	-- syncing table between client & server is necessary to avoid issues due to version mismatch
elseif Settings.rbxenum_behavior == "compact" then
	local enumarray: { Enum } = {}
	local enumitemarray: { EnumItem } = {}
	local valuelookup: { [any]: number } = {}

	local SyncingEnabled = Settings.serverclientsyncing
	local IsSyncOrigin = if SyncingEnabled then RS:IsServer() else true

	if IsSyncOrigin then
		local tosend1, tosend2

		if SyncingEnabled then
			tosend1, tosend2 = {}, {}
			local request: RemoteFunction = script:FindFirstChild("request")
	
			if request == nil then
				request = Instance.new("RemoteFunction")
				request.Name = "request"
				request.Parent = script
			end

			request.OnServerInvoke = function(player, v)
				return tosend1, tosend2
			end
		else 
			tosend1, tosend2 = nil, nil
		end

		do
			-- using tostring on index because the enum/enumitem may not exist
			-- which will lead to gaps getting created when syncing

			local enum_i, enumitem_i = 0, 0
			for _, k in Enum:GetEnums() do
				enum_i += 1
				enumarray[enum_i] = k
				valuelookup[k] = enum_i

				if tosend1 then tosend1[tostring(enum_i)] = k end

				for _, v in k:GetEnumItems() do
					enumitem_i += 1
					enumitemarray[enumitem_i] = v
					valuelookup[v] = enumitem_i

					if tosend2 then tosend2[tostring(enumitem_i)] = v end
				end
			end
		end
	else
		task.spawn(function()
			local request = script:WaitForChild("request")

			local function addtoarray(toarray, fromdict, todict)
				local lastnum = 0
				
				for k, v in fromdict do
					k = tonumber(k)
					toarray[k] = v
					valuelookup[v] = k

					lastnum = math.max(lastnum, k)
				end

				-- fill gaps
				for i = 1, lastnum do
					if toarray[i] == nil then toarray[i] = false end
				end
			end

			while true do
				local success, r1, r2 = pcall(request.InvokeServer, request)

				if success and r1 and r2 then
					addtoarray(enumarray, r1)
					addtoarray(enumitemarray, r2)

					break
				else
					task.wait(3)
				end
			end
		end)
	end

	@native
	function exposed.encodeEnum(buf: buffer, offset: number, value: Enum): number
		local position = valuelookup[value]
		buffer.writeu16(buf, offset, position or 0) 

		return offset + 2
	end

	exposed.encodeEnumItem = (exposed.encodeEnum :: any) :: (buf: buffer, offset: number, value: EnumItem) -> number

	@native
	function exposed.decodeEnum(buf: buffer, byte: number, cursor: number): (Enum, number)
		local position = buffer.readu16(buf, cursor)
		return enumarray[position], cursor + 2
	end

	@native
	function exposed.decodeEnumItem(buf: buffer, byte: number, cursor: number): (EnumItem, number)
		local position = buffer.readu16(buf, cursor)
		return enumitemarray[position], cursor + 2
	end
else
	error(`{Settings.rbxenum_behavior} is not a valid enum encoding behavior, options are ('full', 'compact')`, 0)
end

return exposed
