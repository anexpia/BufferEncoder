--!optimize 2

--[[
	## made by anexpia •…• ##

	assigns values to specific bytes so that they can be encoded
	this is mainly for sending values that cannot be encoded from server to client
	like newproxy() objects, or other unique values like tables that you want to be the same everytime
	they're sent in a remote.

	you probably don't need to use this most of the time, but the option exists and its helpful when
	its actually needed
]]


local RS = game:GetService("RunService")

local Settings = require(script.Parent.Settings)

local SyncingEnabled = Settings.serverclientsyncing
local IsSyncOrigin = if SyncingEnabled then RS:IsServer() else true

local nametovalue: {[string]: any} = {}
local bytetovalue: {[number]: any} = {
	[2] = true,
	[3] = false,
	[102] = "",
	[103] = 0,
	[104] = 1,
	[105] = -1,
	[106] = math.huge,
	[107] = -math.huge,
	[108] = 0 / 0,
}

local valuetobyte: {[any]: number} = {
	[true] = 2,
	[false] = 3,
	[""] = 102,
	[0] = 103,
	[1] = 104,
	[-1] = 105,
	[math.huge] = 106,
	[-math.huge] = 107,
	-- no nan since nan will error if in table
}

local freebytes
local currentposition = 0

local function sanitizename(name)
	if type(name) ~= "string" then
		error(`expected name to be a string, got {typeof(name)}`, 0)
	end
	if name == "" then
		error("name should not be an empty string", 0)
	end

	return string.gsub(name, "[^%w_]", "_") -- turn everything that isnt %w and _ into _
end

-- Removes the value associated with 'name' from byte registry.
local function removename(name: string)
	name = sanitizename(name)

	local value = nametovalue[name]

	if value then
		local oldbyte = valuetobyte[value]
		valuetobyte[value] = nil

		if bytetovalue[oldbyte] == value then
			bytetovalue[oldbyte] = nil
		end

		if IsSyncOrigin then
			table.insert(freebytes, oldbyte)
			nametovalue[name] = nil -- not done on client because this is called whenever the attribute is changed, and current value is needed
			
			if SyncingEnabled then
				script:SetAttribute(name, nil)
			end
		end
	end
end

if not IsSyncOrigin then
	local function attributechanged(name, byte)
		removename(name)

		byte = byte or script:GetAttribute(name)

		if byte then
			local value = nametovalue[name]

			if not value then
				value = newproxy()
				nametovalue[name] = value
			end

			valuetobyte[value] = byte
			bytetovalue[byte] = value
		else
			nametovalue[name] = nil
		end
	end

	script.AttributeChanged:Connect(attributechanged)
	for name, value in script:GetAttributes() do
		attributechanged(name, value)
	end
else
	freebytes = {}
end

return {
	bytetovalue = bytetovalue,
	nametovalue = nametovalue,

	valuetobyte = valuetobyte,

	--[[
	Assigns 2 bytes to the name and returns the value that is encoded as the byte.
	Registered names are synced from server to client.
	]]
	register = function(name: string, predefined: any?): any
		name = sanitizename(name)

		if valuetobyte[predefined] then
			error(`cannot define {name} with the value {predefined} as the value is already defined`, 0)
		end

		if nametovalue[name] then
			if predefined then
				local oldvalue = nametovalue[name]
				local byte = valuetobyte[oldvalue]

				nametovalue[name] = predefined

				if byte then
					valuetobyte[oldvalue] = nil
					valuetobyte[predefined] = byte
					bytetovalue[byte] = predefined
				end
			end

			return nametovalue[name]
		end

		local v = predefined or newproxy()

		if IsSyncOrigin then
			local byte = table.remove(freebytes)

			if not byte then
				byte = currentposition - 1
				currentposition = byte
			end

			nametovalue[name] = v
			valuetobyte[v] = byte
			bytetovalue[byte] = v

			if SyncingEnabled then
				script:SetAttribute(name, byte)
			end
		else
			nametovalue[name] = v
		end

		return v
	end,

	remove = removename,
}
