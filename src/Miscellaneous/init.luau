--!native
--!optimize 2

-- quaternion stuff from https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894/105?u=anexpia
-- modified a bit to be more performant when encoding 

local Settings = require(script.Parent.Settings)
local floatencoder = require(script.floatencoder)

local SanitizingEnabled = Settings.sanitize_nanandinf

local FP_EPSILON = 1e-6
local I16_PRECISION = 32767                 -- int16 range { -32,786, 32,767 }
local BUFF_CFRAME_SIZE_NO_ID = (3*4) + (2*1 + 3*2)  -- i.e. 3x f32, 2x u8 and 3x i16
local BUFF_CFRAME_SIZE_WITH_ID = (3*4) + 1  -- i.e. 3x f32, 1x u8

local cframe_ToAxisAngle = CFrame.identity.ToAxisAngle
local cframe_GetComponents = CFrame.identity.GetComponents	

local function getNormalisedQuaternion(cframe: CFrame)
	local axis_shadowed, angle = cframe_ToAxisAngle(cframe)
	local ha = angle / 2

	local axis: vector = if vector.magnitude(axis_shadowed) > FP_EPSILON then vector.normalize(axis_shadowed) else (Vector3.xAxis :: any)
	axis *= math.sin(ha)
	
	local w = math.cos(ha)
	local length = math.sqrt(vector.dot(axis, axis) + w*w)
	
	if length < FP_EPSILON then 
		return 0, 0, 0, 1 
	end
	
	axis /= length
	return axis.x, axis.y, axis.z, w / length
end

local function compressQuaternion(cframe)
	local qx, qy, qz, qw = getNormalisedQuaternion(cframe)

	local index = -1
	local value = -math.huge

	local sign
	for i = 1, 4, 1 do
		local val = select(i, qx, qy, qz, qw)
		local abs = math.abs(val)
		if abs > value then
			index = i
			value = abs
			sign = val
		end
	end
	sign = sign >= 0 and 1 or -1

	local v0, v1, v2
	if index == 1 then
		v0 = math.floor(qy * sign * I16_PRECISION + 0.5)
		v1 = math.floor(qz * sign * I16_PRECISION + 0.5)
		v2 = math.floor(qw * sign * I16_PRECISION + 0.5)
	elseif index == 2 then
		v0 = math.floor(qx * sign * I16_PRECISION + 0.5)
		v1 = math.floor(qz * sign * I16_PRECISION + 0.5)
		v2 = math.floor(qw * sign * I16_PRECISION + 0.5)
	elseif index == 3 then
		v0 = math.floor(qx * sign * I16_PRECISION + 0.5)
		v1 = math.floor(qy * sign * I16_PRECISION + 0.5)
		v2 = math.floor(qw * sign * I16_PRECISION + 0.5)
	elseif index == 4 then
		v0 = math.floor(qx * sign * I16_PRECISION + 0.5)
		v1 = math.floor(qy * sign * I16_PRECISION + 0.5)
		v2 = math.floor(qz * sign * I16_PRECISION + 0.5)
	end

	return index, v0, v1, v2
end

local function decompressQuaternion(index, v0, v1, v2)
	v0 /= I16_PRECISION
	v1 /= I16_PRECISION
	v2 /= I16_PRECISION

	local d = math.sqrt(1 - (v0*v0 + v1*v1 + v2*v2))
	if index == 1 then
		return d, v0, v1, v2
	elseif index == 2 then
		return v0, d, v1, v2
	elseif index == 3 then
		return v0, v1, d, v2
	end

	return v0, v1, v2, d
end

--/This is how roblox stores rotations in rbxl binary files, so might as well use it here
local CFRAME_ROTATION_IDS_WRITE = {
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 1,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0"] = 2,
	["\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 3,
	["\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0"] = 4,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 5,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 6,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63"] = 7,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 8,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0"] = 9,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0"] = 10,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0"] = 11,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128"] = 12,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191"] = 13,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128"] = 14,
	["\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 15,
	["\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128"] = 16,
	["\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63"] = 17,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0"] = 18,
	["\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191"] = 19,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0"] = 20,
	["\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0"] = 21,
	["\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0"] = 22,
	["\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0"] = 23,
	["\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128"] = 24,
}

local CFRAME_ROTATION_IDS_READ = {
	"\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63",
	"\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0",
	"\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191",
	"\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0",
	"\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191",
	"\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0",
	"\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\63",
	"\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0",
	"\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\63\0\0\0\0\0\0\0\0",
	"\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0",
	"\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\63\0\0\0\0\0\0\0\0",
	"\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\128",
	"\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191",
	"\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128",
	"\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63",
	"\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128",
	"\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63",
	"\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0",
	"\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128\0\0\0\0\0\0\0\0\0\0\128\191",
	"\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0",
	"\0\0\0\0\0\0\128\63\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\191\0\0\128\191\0\0\0\0\0\0\0\0",
	"\0\0\0\0\0\0\0\0\0\0\128\63\0\0\0\0\0\0\128\63\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\0",
	"\0\0\0\0\0\0\128\191\0\0\0\0\0\0\0\0\0\0\0\0\0\0\128\63\0\0\128\191\0\0\0\0\0\0\0\0",
	"\0\0\0\0\0\0\0\0\0\0\128\191\0\0\0\0\0\0\128\191\0\0\0\128\0\0\128\191\0\0\0\0\0\0\0\128",
}

--/Gets the rotationID of a cframe if it can be compressed
local function canCompressCFrame(cframe: CFrame)
	local _,_,_ ,r00,r01,r02,r10,r11,r12,r20,r21,r22 = cframe_GetComponents(cframe)
	local rotationID = CFRAME_ROTATION_IDS_WRITE[string.pack("<fffffffff", r00, r01, r02, r10, r11, r12, r20, r21, r22)]
	return rotationID ~= nil, rotationID
end

local function write(buf: buffer, offset: number, input: CFrame, rotationID: number?)

	--/Split the cframe into its components
	local pos = input.Position

	buffer.writef32(buf, offset, pos.X)
	buffer.writef32(buf, offset + 4, pos.Y)
	buffer.writef32(buf, offset + 8, pos.Z)

	--/This is how roblox stores rotations in rbxl binary files, so might as well use it here (if it's not in the table we only gain 1 byte compared to previous implementation)
	if rotationID then
		--/WAHOO! We can use the rotationID to skip the quaternion compression (aka skipping 3x i16 and 1x u8 [7 bytes])
		buffer.writeu8(buf, offset + 12, rotationID)
	else
		--/If it's not in the table, we need to write a quaternion instead
		buffer.writeu8(buf, offset + 12, 0)
		
		--/Compress the rotation into a quaternion
		local qi, q0, q1, q2 = compressQuaternion(input)
		buffer.writeu8(buf, offset + 13, qi)
		buffer.writei16(buf, offset + 14, q0)
		buffer.writei16(buf, offset + 16, q1)
		buffer.writei16(buf, offset + 18, q2)
	end
end

local function read(buf: buffer, byte: number, offset: number): (CFrame, number)
	local x = buffer.readf32(buf, offset)
	local y = buffer.readf32(buf, offset + 4)
	local z = buffer.readf32(buf, offset + 8)

	if SanitizingEnabled then
		if (x / x) ~= 1 then x = 0 end
		if (y / y) ~= 1 then y = 0 end
		if (z / z) ~= 1 then z = 0 end
	end

	--/Read the rotationID
	local rotationID = buffer.readu8(buf, offset + 12)
	if rotationID == 0 then
		--/We need to read a quaternion since it's not in the table
		local qi = buffer.readu8(buf, offset + 13)
		local q0 = buffer.readi16(buf, offset + 14)
		local q1 = buffer.readi16(buf, offset + 16)
		local q2 = buffer.readi16(buf, offset + 18)

		local qx, qy, qz, qw = decompressQuaternion(qi, q0, q1, q2)
		return CFrame.new(x, y, z, qx, qy, qz, qw), offset + BUFF_CFRAME_SIZE_NO_ID
	end

	--/Failed to read rotationID, this is a fallback so it doesnt error but it should never happen unless its either corrupted or not a cframe
	local rotation = CFRAME_ROTATION_IDS_READ[rotationID]
	if not rotation then
		return CFrame.new(x, y, z), offset + BUFF_CFRAME_SIZE_WITH_ID
	end

	--/Unpack rotation (free 7 bytes compared to previous implementation :D)
	local r00, r01, r02, r10, r11, r12, r20, r21, r22 = string.unpack("<fffffffff", rotation)
	return CFrame.new(x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22), offset + BUFF_CFRAME_SIZE_WITH_ID

end

return {
	readCFrame = read,
	writeCFrame = write,
	canCompressCFrame = canCompressCFrame,

	cframesize_no_id = BUFF_CFRAME_SIZE_NO_ID,
	cframesize_with_id = BUFF_CFRAME_SIZE_WITH_ID,
	
	writef16 = floatencoder.writef16;
	readf16 = floatencoder.readf16;
}