--!native
--!optimize 2

-- quaternion stuff from https://devforum.roblox.com/t/introducing-luau-buffer-type-beta/2724894/105?u=anexpia
-- modified a bit to be more performant when encoding 

local Types = require(script.Parent.Types)
local floatencoder = require(script.floatencoder)

local FP_EPSILON = 1e-6
local I16_PRECISION = 32767                 -- int16 range { -32,786, 32,767 }
local BUFF_CFRAME_SIZE = (3*4) + (1 + 3*2)  -- i.e. 3x f32, 1x u8 and 3x i16

local cframe_ToAxisAngle = CFrame.identity.ToAxisAngle

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

local function write(buf: buffer, offset: number, input: CFrame)
	local pos = input.Position

	buffer.writef32(buf, offset, pos.X)
	buffer.writef32(buf, offset + 4, pos.Y)
	buffer.writef32(buf, offset + 8, pos.Z)

	local qi, q0, q1, q2 = compressQuaternion(input)
	buffer.writeu8(buf, offset + 12, qi)
	buffer.writei16(buf, offset + 13, q0)
	buffer.writei16(buf, offset + 15, q1)
	buffer.writei16(buf, offset + 17, q2)
end

local function read(buf: buffer, byte: number, offset: number, info: Types.ReadSettings): (CFrame, number)
	local x = buffer.readf32(buf, offset)
	local y = buffer.readf32(buf, offset + 4)
	local z = buffer.readf32(buf, offset + 8)

	if info.sanitize_nanandinf then
		if (x / x) ~= 1 then x = 0 end
		if (y / y) ~= 1 then y = 0 end
		if (z / z) ~= 1 then z = 0 end
	end

	local qi = buffer.readu8(buf, offset + 12)
	local q0 = buffer.readi16(buf, offset + 13)
	local q1 = buffer.readi16(buf, offset + 15)
	local q2 = buffer.readi16(buf, offset + 17)

	local qx, qy, qz, qw = decompressQuaternion(qi, q0, q1, q2)
	return CFrame.new(x, y, z, qx, qy, qz, qw), offset + BUFF_CFRAME_SIZE
end

return {
	readCFrame = read,
	writeCFrame = write,

	cframesize = BUFF_CFRAME_SIZE,
	
	writef16 = floatencoder.writef16;
	readf16 = floatencoder.readf16;
}