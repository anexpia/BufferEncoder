--!optimize 2

--[[ 
	## made by anexpia •…• ## 
]]

local RS = game:GetService("RunService")
local Settings = require(script.Parent.Settings)
local SyncingEnabled = Settings.serverclientsyncing

local enumitem_to_type = {}
local enumitem_to_value = {}


local exposed = {
	enumitem_to_type = enumitem_to_type;
	enumitem_to_value = enumitem_to_value;

	compact = {},
	full = {},
}

for _, enum in Enum:GetEnums() do 
	local n = tostring(enum)

	enumitem_to_type[enum] = n
	
	for _, enumitem in enum:GetEnumItems() do 
		enumitem_to_type[enumitem] = n
		enumitem_to_value[enumitem] = enumitem.Value 
	end
end

do
	-- encode enums as <19> <u8 length> <string>
	-- encode enumitems as <20> <u8 length> <string> <u16 value>

	local full = exposed.full

	local nametoenum = {}
	for _, v in Enum:GetEnums() do
		nametoenum[tostring(v)] = v
	end
	-- this is to avoid erroring due to version mismatch when decoding

	local enum_FromValue = (Enum.Material :: any).FromValue

	@native
	function full.encodeEnum(buf: buffer, offset: number, enum: Enum): number
		local name = enumitem_to_type[enum]
		local length = #name

		buffer.writeu8(buf, offset, length); offset += 1
		buffer.writestring(buf, offset, name)

		return offset + length
	end

	@native
	function full.encodeEnumItem(buf: buffer, offset: number, enumitem: EnumItem): number
		offset = full.encodeEnum(buf, offset, enumitem :: any)
		buffer.writeu16(buf, offset, enumitem_to_value[enumitem])

		return offset + 2
	end

	@native
	function full.decodeEnum(buf: buffer, byte: number, cursor: number): (Enum, number, boolean?)
		local length = buffer.readu8(buf, cursor); cursor += 1
		local name = buffer.readstring(buf, cursor, length)

		return nametoenum[name], cursor + length, true
	end

	@native
	function full.decodeEnumItem(buf: buffer, byte: number, cursor: number): (EnumItem, number, boolean?)
		local enum, newcursor = full.decodeEnum(buf, byte, cursor)
		local value = buffer.readu16(buf, newcursor)

		return enum and enum_FromValue(enum, value), newcursor + 2, true
	end
end

do
	-- encode enums as <19> <u16 index>
	-- encode enumitems as <20> <u16 index>
	-- syncing table between client & server is necessary to avoid issues due to version mismatch

	local enumarray: { Enum } = {}
	local enumitemarray: { EnumItem } = {}
	local valuelookup: { [any]: number } = {}

	local compact = exposed.compact

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

			local function addtoarray(toarray, fromdict)
				for k, v in fromdict do
					k = tonumber(k)
					toarray[k] = v
					valuelookup[v] = k
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
	function compact.encodeEnum(buf: buffer, offset: number, value: Enum): number
		local position = valuelookup[value]
		buffer.writeu16(buf, offset, position or 0) 

		return offset + 2
	end

	compact.encodeEnumItem = (compact.encodeEnum :: any) :: (buf: buffer, offset: number, value: EnumItem) -> number

	@native
	function compact.decodeEnum(buf: buffer, byte: number, cursor: number): (Enum, number)
		local position = buffer.readu16(buf, cursor)
		return enumarray[position], cursor + 2
	end

	@native
	function compact.decodeEnumItem(buf: buffer, byte: number, cursor: number): (EnumItem, number)
		local position = buffer.readu16(buf, cursor)
		return enumitemarray[position], cursor + 2
	end
end

function exposed.getBehaviorFromSetting(operationsettings): (typeof(exposed.full), "full" | "compact")
	local value = operationsettings.rbxenum_behavior or Settings.rbxenum_behavior
	local enumbehavior = exposed[value]

	if enumbehavior == nil then 
		error(`{value} is an invalid value for rbx_enumbehavior, options are 'full' / 'compact'`, 0)
	end 

	return enumbehavior, value
end

return exposed
