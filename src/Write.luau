--!native
--!optimize 2
--!nolint LocalShadow 

--[[ ## made by anexpia •…• ## ]]

-- [[ byte tags, if negative then its a dict key ]]
-- 0 -> at end: terminate, at start: deduplication table
-- 1 -> stop and start new table
-- 2 -> boolean: true
-- 3 -> boolean: false
-- 4 -> nil
-- 5 to 11 -> number
-- 12 to 14 -> buffer
-- 15 -> v3 (3 f32)
-- 16 -> v2 (2 f32)
-- 17 -> cframe 
-- 18 -> ray (6 f32)
-- 19 -> enum < polymorphic - depends on setting 'rbxenum_behavior' >
-- 20 -> enumitem < polymorphic - depends on setting 'rbxenum_behavior' >
-- 21 -> numberrange (2 f32)
-- 22 -> numbersequence
-- 23 -> color3 (u8)
-- 24 -> color3 (f16)
-- 25 -> colorsequence
-- 26 -> udim (1 int32 1 f32)
-- 27 -> udim2 (2 int32 2 f32)
-- 28 -> rect (4 f32)
-- 29 -> physicalproperties (really long)
-- 30 -> brickcolor (int16)
-- 31 -> vector3int16 (3 i16)
-- 32 -> vector2int16 (2 i16)
-- 33 -> content (depends)
-- 34 -> font (depends)
-- 35 -> datetime (f64)

-- 51 -> table position (u8)
-- 52 -> table position (u16)
-- 53 -> table position (u32)
-- 54 -> u8 length string
-- 55 -> u16 length string
-- 56 -> u32 length string
-- 57 -> value deduplicate (u8)
-- 58 -> value deduplicate (u16)
-- 59 -> value deduplicate (u32)
-- 60 -> reference (u8)
-- 61 -- reference (u16)
-- 62 -- reference (u32)

-- 99 -> 2 byte custom value || <99> <-index>

-- 101 -> empty table
-- 102 -> empty string
-- 103 -> 0
-- 104 -> 1
-- 105 -> -1
-- 106 -> math.huge
-- 107 -> -math.huge
-- 108 -> nan

local uI16_max = (2 ^ 16) - 1

local Enums = require(script.Parent.Enums)
local Miscellaneous = require(script.Parent.Miscellaneous)
local RbxEnumEncoder = require(script.Parent.RbxEnumEncoder)
local Settings = require(script.Parent.Settings)
local Types = require(script.Parent.Types)

type encodeinfo = Types.encodeinfo
type WriteSettings = Types.WriteSettings

local valuetobyte = Enums.valuetobyte

local writef16 = Miscellaneous.writef16
local writeCFrame = Miscellaneous.writeCFrame
local CFrameSize = Miscellaneous.cframesize

-- shift the byte associated with a value/datatype by the number given
local tryshift = function(v: number, shiftseed: number?): number
	if shiftseed then return (v + math.random(1, 127)) % 128
	else return v end
end

-- write the byte associated with a given value or datatype
local function writebytesign(buff: buffer, cursor: number, value: number, isdict: boolean?, shiftseed: number?)
	if shiftseed then value = (value + math.random(1, 127)) % 128 end
	if isdict then value = 255 - value end

	buffer.writeu8(buff, cursor, value)
end

-- expand the size of the writingbuffer
local function expandbuffertosize(buff: buffer, newsize: number, info: encodeinfo): buffer
	if newsize > info.allocatedsize then
		newsize //= 1/1.375
		info.allocatedsize = newsize 

		local newbuff = buffer.create(newsize)
		buffer.copy(newbuff, 0, buff)

		return newbuff
	end

	return buff
end

-- write every value into the buffer
local function write(
	buff: buffer,
	cursor: number,
	info: encodeinfo
): (buffer, number)

	local writesettings = info.settings

	local shiftseed: number?, dedupallowed = writesettings.shiftseed, writesettings.allowdeduplication
	local color3always6bytes = writesettings.color3always6bytes
	if color3always6bytes == nil then color3always6bytes = Settings.color3always6bytes end

	local enumbehavior, enumbehaviortype = RbxEnumEncoder.getBehaviorFromSetting(writesettings)
	local fullrbxenum: boolean = enumbehaviortype == 'full'

	local scancount: number = 1
	local deduplicatedcount: number = 0
	local referencecount: number = 0

	local valuepositionlookup = info.valuepositionlookup

	local scanlist = info.scanlist
	local referencelist = info.referencelist

	for _, tbl in scanlist do 
		buff = expandbuffertosize(buff, cursor + 1, info)
		writebytesign(buff, cursor, 1, nil, shiftseed); cursor += 1

		local arraywritelength: number = rawlen(tbl)
		local isdoingdict: boolean = arraywritelength == 0

		local iternum: number = if isdoingdict then 2 else 1	
		local lastkey: number = 0
		for k, v in next, tbl do 
			if (not isdoingdict) then
				local diff: number = (k - lastkey) - 1

				if diff > 0 then
					buff = expandbuffertosize(buff, cursor + diff, info)
					if shiftseed then
						for i = 0, diff - 1 do 
							buffer.writeu8(buff, cursor + i, (4 + math.random(1, 127)) % 128)
						end
					else buffer.fill(buff, cursor, 4, diff) end
					cursor += diff
				end

				lastkey = k 
			end

			for i = 1, iternum do 
				local isdict: boolean = isdoingdict and i == 1
				local value: any = if isdict then k else v

				local valuebyte: number? = valuetobyte[value]
				if valuebyte then
					if valuebyte <= 0 then
						buff = expandbuffertosize(buff, cursor + 2, info)
						writebytesign(buff, cursor, 99, isdict, shiftseed)
						buffer.writeu8(buff, cursor + 1, -valuebyte); cursor += 2
					else
						buff = expandbuffertosize(buff, cursor + 1, info)
						writebytesign(buff, cursor, valuebyte, isdict, shiftseed); cursor += 1
					end

					continue
				end

				local t: string = typeof(value)
				local candeduplicate: boolean = dedupallowed and (t == 'string' or t == 'Vector3' or t == 'number' or (fullrbxenum and (t == 'EnumItem' or t == 'Enum')))

				if candeduplicate then
					if value ~= value then
						-- nan shouldnt be deduplicated, whether in a vector or as a number

						if t == 'number' then
							buff = expandbuffertosize(buff, cursor + 1, info)
							writebytesign(buff, cursor, 108, isdict, shiftseed); cursor += 1
						else 
							local value: Vector3 = value
							-- vector in this case

							buff = expandbuffertosize(buff, cursor + 13, info)

							writebytesign(buff, cursor, 15, isdict, shiftseed); cursor += 1
							buffer.writef32(buff, cursor, value.X); cursor += 4
							buffer.writef32(buff, cursor, value.Y); cursor += 4
							buffer.writef32(buff, cursor, value.Z); cursor += 4
						end

						continue
					end

					if t == 'number' then
						local value: number = value
						-- numbers below 256 that arent float values shouldnt be deduplicated

						local abs = math.abs(value)
						if not (abs > 0xFF or abs % 1 ~= 0) then
							-- encoding here to avoid rechecking later
							buff = expandbuffertosize(buff, cursor + 5, info)

							writebytesign(buff, cursor, if value < 0 then 8 else 5, isdict, shiftseed)
							buffer.writeu8(buff, cursor + 1, abs); cursor += 2

							continue
						end
					end

					local added: number? = valuepositionlookup[value]

					if added then
						if added <= 0xFF then -- u8
							buff = expandbuffertosize(buff, cursor + 2, info)
							writebytesign(buff, cursor, 57, isdict, shiftseed)
							buffer.writeu8(buff, cursor + 1, added); cursor += 2
						elseif added <= 0xFFFF then -- u16
							buff = expandbuffertosize(buff, cursor + 3, info)
							writebytesign(buff, cursor, 58, isdict, shiftseed)
							buffer.writeu16(buff, cursor + 1, added); cursor += 3
						else -- u32
							buff = expandbuffertosize(buff, cursor + 5, info)
							writebytesign(buff, cursor, 59, isdict, shiftseed)
							buffer.writeu32(buff, cursor + 1, added); cursor += 5
						end

						continue
					else 
						deduplicatedcount += 1
						valuepositionlookup[value] = deduplicatedcount
					end
				end

				if t == "nil" then
					buff = expandbuffertosize(buff, cursor + 1, info)
					writebytesign(buff, cursor, 4, isdict, shiftseed); cursor += 1
				elseif t == "number" then
					local value: number = value

					if value ~= value then
						buff = expandbuffertosize(buff, cursor + 1, info)
						writebytesign(buff, cursor, 108, isdict, shiftseed); cursor += 1
					else
						local abs = math.abs(value)
						if (value % 1) ~= 0 or abs > 0xFFFFFFFF then -- float64
							buff = expandbuffertosize(buff, cursor + 9, info)

							writebytesign(buff, cursor, 11, isdict, shiftseed)
							buffer.writef64(buff, cursor + 1, value); cursor += 9
						else
							local offset = if value < 0 then 3 else 0

							if abs <= 0xFF then -- uint8
								buff = expandbuffertosize(buff, cursor + 2, info)

								writebytesign(buff, cursor, 5 + offset, isdict, shiftseed)
								buffer.writeu8(buff, cursor + 1, abs); cursor += 2
							elseif abs <= 0xFFFF then -- uint16
								buff = expandbuffertosize(buff, cursor + 3, info)

								writebytesign(buff, cursor, 6 + offset, isdict, shiftseed)
								buffer.writeu16(buff, cursor + 1, abs); cursor += 3
							else
								buff = expandbuffertosize(buff, cursor + 5, info)

								writebytesign(buff, cursor, 7 + offset, isdict, shiftseed)
								buffer.writeu32(buff, cursor + 1, abs); cursor += 5
							end
						end
					end
				elseif t == "string" then
					local value: string = value
					local len: number = #value 

					if len <= 0xFF then -- not zero-terminated since no benefit in making it zero-terminated
						buff = expandbuffertosize(buff, cursor + len + 2, info)

						writebytesign(buff, cursor, 54, isdict, shiftseed)
						buffer.writeu8(buff, cursor + 1, len); cursor += 2
					elseif len <= 0xFFFF then
						buff = expandbuffertosize(buff, cursor + len + 3, info)

						writebytesign(buff, cursor, 55, isdict, shiftseed)
						buffer.writeu16(buff, cursor + 1, len); cursor += 3
					else
						buff = expandbuffertosize(buff, cursor + len + 5, info)

						writebytesign(buff, cursor, 56, isdict, shiftseed)
						buffer.writeu32(buff, cursor + 1, len); cursor += 5
					end

					buffer.writestring(buff, cursor, value); cursor += len
				elseif t == "table" then
					local value: {[any]: any} = value
					local scanpos: number? = valuepositionlookup[value]
					if (not scanpos) and (next(value) ~= nil) then
						scanpos = scancount + 1
						scancount = scanpos :: any
						valuepositionlookup[value] = scanpos
						scanlist[scanpos] = value
					end

					if scanpos then
						if scanpos <= 0xFF then
							buff = expandbuffertosize(buff, cursor + 2, info)

							writebytesign(buff, cursor, 51, isdict, shiftseed)
							buffer.writeu8(buff, cursor + 1, scanpos); cursor += 2
						elseif scanpos <= 0xFFFF then
							buff = expandbuffertosize(buff, cursor + 3, info)

							writebytesign(buff, cursor, 52, isdict, shiftseed)
							buffer.writeu16(buff, cursor + 1, scanpos); cursor += 3
						else
							buff = expandbuffertosize(buff, cursor + 5, info)

							writebytesign(buff, cursor, 53, isdict, shiftseed)
							buffer.writeu32(buff, cursor + 1, scanpos); cursor += 5
						end
					else
						buff = expandbuffertosize(buff, cursor + 1, info)

						writebytesign(buff, cursor, 101, isdict, shiftseed); cursor += 1
					end
				elseif t == "buffer" then
					local value: buffer = value
					local length: number = buffer.len(value)

					if length <= 0xFF then
						buff = expandbuffertosize(buff, cursor + 2 + length, info)

						writebytesign(buff, cursor, 12, isdict, shiftseed)
						buffer.writeu8(buff, cursor + 1, length)
						cursor += 2
					elseif length <= 0xFFFF then
						buff = expandbuffertosize(buff, cursor + 3 + length, info)

						writebytesign(buff, cursor, 13, isdict, shiftseed)
						buffer.writeu16(buff, cursor + 1, length)
						cursor += 3
					else
						buff = expandbuffertosize(buff, cursor + 5 + length, info)

						writebytesign(buff, cursor, 14, isdict, shiftseed)
						buffer.writeu32(buff, cursor + 1, length)
						cursor += 5
					end

					buffer.copy(buff, cursor, value)
					cursor += length
				elseif t == "Vector3" then
					local value: Vector3 = value
					buff = expandbuffertosize(buff, cursor + 13, info)

					writebytesign(buff, cursor, 15, isdict, shiftseed); cursor += 1
					buffer.writef32(buff, cursor, value.X); cursor += 4
					buffer.writef32(buff, cursor, value.Y); cursor += 4
					buffer.writef32(buff, cursor, value.Z); cursor += 4
				elseif t == "Vector2" then
					local value: Vector2 = value
					buff = expandbuffertosize(buff, cursor + 9, info)

					writebytesign(buff, cursor, 16, isdict, shiftseed); cursor += 1
					buffer.writef32(buff, cursor, value.X); cursor += 4
					buffer.writef32(buff, cursor, value.Y); cursor += 4
				elseif t == "CFrame" then
					local value: CFrame = value
					buff = expandbuffertosize(buff, cursor + CFrameSize + 1, info)

					writebytesign(buff, cursor, 17, isdict, shiftseed); cursor += 1
					writeCFrame(buff, cursor, value); cursor += CFrameSize
				elseif t == "Ray" then
					local value: Ray = value
					buff = expandbuffertosize(buff, cursor + 25, info)

					writebytesign(buff, cursor, 18, isdict, shiftseed); cursor += 1

					local pos: Vector3, dir: Vector3 = value.Origin, value.Direction
					buffer.writef32(buff, cursor, pos.X); cursor += 4
					buffer.writef32(buff, cursor, pos.Y); cursor += 4
					buffer.writef32(buff, cursor, pos.Z); cursor += 4
					buffer.writef32(buff, cursor, dir.X); cursor += 4
					buffer.writef32(buff, cursor, dir.Y); cursor += 4
					buffer.writef32(buff, cursor, dir.Z); cursor += 4
				elseif t == "Enum" then
					local value: Enum = value
					local size: number = 3 -- <u8> 19 | <u16> position
					if fullrbxenum then 
						size = 2 + #RbxEnumEncoder.enumitem_to_type[value] 
						-- <u8> byte | <u8> length | string
					end 

					buff = expandbuffertosize(buff, cursor + size, info)
					writebytesign(buff, cursor, 19, isdict, shiftseed)
					cursor = enumbehavior.encodeEnum(buff, cursor + 1, value)
				elseif t == "EnumItem" then
					local value: EnumItem = value
					local size: number = 3 -- <u8> 20 | <u16> position
					if fullrbxenum then 
						size = 4 + #RbxEnumEncoder.enumitem_to_type[value] 
						-- <u8> 20 | <u8> length | string | <u16> value
					end

					buff = expandbuffertosize(buff, cursor + size, info)

					writebytesign(buff, cursor, 20, isdict, shiftseed)
					cursor = enumbehavior.encodeEnumItem(buff, cursor + 1, value)
				elseif t == "NumberRange" then
					local value: NumberRange = value
					buff = expandbuffertosize(buff, cursor + 9, info)
					writebytesign(buff, cursor, 21, isdict, shiftseed); cursor += 1

					buffer.writef32(buff, cursor, value.Min); cursor += 4
					buffer.writef32(buff, cursor, value.Max); cursor += 4
				elseif t == "NumberSequence" then
					local value: NumberSequence = value
					local keypoints: {NumberSequenceKeypoint} = value.Keypoints

					buff = expandbuffertosize(buff, cursor + 2 + #keypoints * 8, info)

					writebytesign(buff, cursor, 22, isdict, shiftseed);
					buffer.writeu8(buff, cursor + 1, #keypoints); cursor += 2

					for _, k in keypoints do
						buffer.writeu16(buff, cursor, math.round(k.Time * uI16_max))
						buffer.writef32(buff, cursor + 2, k.Value)
						
						writef16(buff, cursor + 6, k.Envelope); cursor += 8
					end
				elseif t == "Color3" then
					local value: Color3 = value
					local r: number, g: number, b: number = value.R, value.G, value.B

					if color3always6bytes or (math.max(r, g, b) > 1 or math.min(r, g, b) < 0) then
						buff = expandbuffertosize(buff, cursor + 7, info)

						-- one or more of values is out of 1 byte limit, so this encodes as 2 bytes each
						writebytesign(buff, cursor, 24, isdict, shiftseed)
						writef16(buff, cursor + 1, r)
						writef16(buff, cursor + 3, g)
						writef16(buff, cursor + 5, b)
						cursor += 7
					else
						buff = expandbuffertosize(buff, cursor + 4, info)

						writebytesign(buff, cursor, 23, isdict, shiftseed)
						buffer.writeu8(buff, cursor + 1, math.round(r * 255))
						buffer.writeu8(buff, cursor + 2, math.round(g * 255))
						buffer.writeu8(buff, cursor + 3, math.round(b * 255))
						cursor += 4
					end
				elseif t == "ColorSequence" then
					local value: ColorSequence = value
					local keypoints: {ColorSequenceKeypoint} = value.Keypoints

					buff = expandbuffertosize(buff, cursor + 2 + #keypoints * 5, info)

					writebytesign(buff, cursor, 25, isdict, shiftseed)
					buffer.writeu8(buff, cursor + 1, #keypoints); cursor += 2

					for _, k in keypoints do
						local color = k.Value

						-- colors in colorsequences are always limited to 0-1
						buffer.writeu16(buff, cursor, math.round(k.Time * uI16_max))
						buffer.writeu8(buff, cursor + 2, math.round(color.R * 255))
						buffer.writeu8(buff, cursor + 3, math.round(color.G * 255))
						buffer.writeu8(buff, cursor + 4, math.round(color.B * 255))
						cursor += 5
					end
				elseif t == "UDim" then
					local value: UDim = value
					buff = expandbuffertosize(buff, cursor + 9, info)
					writebytesign(buff, cursor, 26, isdict, shiftseed)

					buffer.writef32(buff, cursor + 1, value.Scale)
					buffer.writei32(buff, cursor + 5, value.Offset)
					cursor += 9
				elseif t == "UDim2" then
					local value: UDim2 = value
					buff = expandbuffertosize(buff, cursor + 17, info)
					local x: UDim, y: UDim = value.X, value.Y

					writebytesign(buff, cursor, 27, isdict, shiftseed)

					buffer.writef32(buff, cursor + 1, x.Scale)
					buffer.writei32(buff, cursor + 5, x.Offset)
					buffer.writef32(buff, cursor + 9, y.Scale)
					buffer.writei32(buff, cursor + 13, y.Offset)
					cursor += 17
				elseif t == "Rect" then
					local value: Rect = value
					buff = expandbuffertosize(buff, cursor + 17, info)
					local min: Vector2, max: Vector2 = value.Min, value.Max

					writebytesign(buff, cursor, 28, isdict, shiftseed)

					buffer.writef32(buff, cursor + 1, min.X)
					buffer.writef32(buff, cursor + 5, min.Y)
					buffer.writef32(buff, cursor + 9, max.X)
					buffer.writef32(buff, cursor + 13, max.Y)
					cursor += 17
				elseif t == "PhysicalProperties" then
					local value: PhysicalProperties = value
					buff = expandbuffertosize(buff, cursor + 21, info)
					writebytesign(buff, cursor, 29, isdict, shiftseed)

					buffer.writef32(buff, cursor + 1, value.Density)
					buffer.writef32(buff, cursor + 5, value.Friction)
					buffer.writef32(buff, cursor + 9, value.Elasticity)
					buffer.writef32(buff, cursor + 13, value.FrictionWeight)
					buffer.writef32(buff, cursor + 17, value.ElasticityWeight)
					cursor += 21
				elseif t == "BrickColor" then
					local value: BrickColor = value
					buff = expandbuffertosize(buff, cursor + 3, info)
					writebytesign(buff, cursor, 30, isdict, shiftseed)
					buffer.writeu16(buff, cursor + 1, value.Number)
					cursor += 3
				elseif t == "Vector3int16" then
					local value: Vector3int16 = value
					buff = expandbuffertosize(buff, cursor + 7, info)
					writebytesign(buff, cursor, 31, isdict, shiftseed)
					buffer.writei16(buff, cursor + 1, value.X)
					buffer.writei16(buff, cursor + 3, value.Y)
					buffer.writei16(buff, cursor + 5, value.Z)
					cursor += 7
				elseif t == "Vector2int16" then
					local value: Vector2int16 = value
					buff = expandbuffertosize(buff, cursor + 5, info)
					writebytesign(buff, cursor, 32, isdict, shiftseed)
					buffer.writei16(buff, cursor + 1, value.X)
					buffer.writei16(buff, cursor + 3, value.Y)
					cursor += 5
				elseif t == "Content" then
					local value: Content = value

					if value.SourceType == Enum.ContentSourceType.Uri then
						local uri: string = value.Uri :: string
						local num: string? = string.match(uri, "%d+$")

						if num then
							buff = expandbuffertosize(buff, cursor + 10, info)
							writebytesign(buff, cursor, 33, isdict, shiftseed)
							buffer.writeu8(buff, cursor + 1, 1)
							buffer.writef64(buff, cursor + 2, tonumber(num) :: number)
							cursor += 10
						else
							-- im going to make a guess and say that the content links are NOT going past 254 bytes in length 😨
							local len: number = #uri
							if len > 254 then
								error("content uri length cannot be more than 254 bytes.", 0)
							end

							buff = expandbuffertosize(buff, cursor + 2 + len, info)
							writebytesign(buff, cursor, 33, isdict, shiftseed)
							buffer.writeu8(buff, cursor + 1, len + 1); cursor += 2
							buffer.writestring(buff, cursor , uri)

							cursor += len
						end

						continue
					else 
						buff = expandbuffertosize(buff, cursor + 2, info)
						writebytesign(buff, cursor, 33, isdict, shiftseed)
						buffer.writeu8(buff, cursor + 1, 0); cursor += 2
					end

				elseif t == "Font" then
					local value: Font = value

					local family: string = value.Family
					local num: string? = string.match(family, "%d+$")

					if num then
						buff = expandbuffertosize(buff, cursor + 13, info)

						writebytesign(buff, cursor, 34, isdict, shiftseed)
						buffer.writeu8(buff, cursor + 1, 0)
						buffer.writef64(buff, cursor + 2, tonumber(num) :: number)

						cursor += 10
					else
						local familyname: string = string.match(family, "/(%w+).json$") or ""
						local length: number = #familyname

						-- same here
						if length > 254 then
							error("font name length cannot be more than 254 bytes.", 0)
						end

						buff = expandbuffertosize(buff, cursor + 5 + length, info)
						writebytesign(buff, cursor, 34, isdict, shiftseed)
						buffer.writeu8(buff, cursor + 1, length + 1); cursor += 2
						buffer.writestring(buff, cursor, familyname)

						cursor += length
					end

					buffer.writeu16(buff, cursor, RbxEnumEncoder.enumitem_to_value[value.Weight])
					buffer.writeu8(buff, cursor + 2, RbxEnumEncoder.enumitem_to_value[value.Style]); cursor += 3
				elseif t == "DateTime" then
					local value: DateTime = value

					buff = expandbuffertosize(buff, cursor + 9, info)
					writebytesign(buff, cursor, 35, isdict, shiftseed)
					buffer.writef64(buff, cursor + 1, value.UnixTimestampMillis); cursor += 9
				else
					if referencelist then
						local referenceposition: number = valuepositionlookup[value]

						if not referenceposition then
							referenceposition = referencecount + 1

							referencecount = referenceposition :: any
							valuepositionlookup[value] = referenceposition
							referencelist[referenceposition] = value
						end

						if referenceposition <= 0xFF then
							buff = expandbuffertosize(buff, cursor + 2, info)
							writebytesign(buff, cursor, 60, isdict, shiftseed)
							buffer.writeu8(buff, cursor + 1, referenceposition); cursor += 2
						elseif referenceposition <= 0xFFFF then
							buff = expandbuffertosize(buff, cursor + 3, info)
							writebytesign(buff, cursor, 61, isdict, shiftseed)
							buffer.writeu16(buff, cursor + 1, referenceposition); cursor += 3
						else 
							buff = expandbuffertosize(buff, cursor + 5, info)
							writebytesign(buff, cursor, 62, isdict, shiftseed)
							buffer.writeu32(buff, cursor + 1, referenceposition); cursor += 5
						end
					elseif isdict then break
					else 
						buff = expandbuffertosize(buff, cursor + 1, info)
						writebytesign(buff, cursor, 4, isdict, shiftseed); cursor += 1 
					end
				end

			end	

			if k == arraywritelength then iternum = 2; isdoingdict = true end
		end
	end

	return buff, cursor
end


local writingbuffer = buffer.create(256)
local writingbuffersize = 256

type BenchmarkerProfiler = {
	Begin: (name: string) -> nil;
	End: () -> nil;
}

--[[
returns the table given encoded as a buffer, and the size of buffer

<em>param</em> - value : the table to encode
<em>param</em> - writeoffset : writing starts from the offset given.
<em>param</em> - writesettings : {
. <strong>allowdeduplication: boolean</strong> -- attempt to deduplicate repeated values if enabled to reduce buffer size
. <strong>allowreferences: boolean</strong> -- if enabled, return a table containing the values it couldn't encode alongside the buffer.
. <strong>shiftseed: number</strong> -- the type bytes of values are shuffled using the seed.
. <strong>rbxenum_behavior: "full" | "compact"</strong> -- override for the default setting.
. <strong>color3always6bytes: boolean</strong> -- override for the default setting.
}
]]
return function(
	value: { [any]: any },
	writeoffset: number?,
	writesettings: WriteSettings?,
	Profiler: BenchmarkerProfiler?
): (buffer, { any }?)
	if type(value) == "table" then

		local writesettings: WriteSettings = writesettings or (Settings :: any)
		local shiftseed = writesettings.shiftseed

		if shiftseed then math.randomseed(shiftseed) end
		local referencelist = if writesettings.allowreferences then {} else nil

		if next(value) == nil then
			local b = buffer.create(1)
			buffer.writeu8(b, 0, tryshift(101, shiftseed))

			if shiftseed then math.randomseed(os.time()) end

			return b, referencelist
		end

		local cursor: number = writeoffset or 0

		local info: encodeinfo = {
			valuepositionlookup = {[value] = 1},
			scanlist = {value},

			referencelist = referencelist,
			settings = writesettings,
			allocatedsize = writingbuffersize;
		}

		local buff = writingbuffer

		if Profiler then
			Profiler.Begin("Write")
		end

		buff, cursor = write(buff, cursor, info)

		buff = expandbuffertosize(buff, cursor + 1, info)
		writebytesign(buff, cursor, 0, nil, shiftseed)

		if Profiler then
			Profiler.End()
			Profiler.Begin("Finish")
		end

		writingbuffer = buff
		writingbuffersize = info.allocatedsize

		local truncatedbuffer = buffer.create(cursor + 2)
		buffer.copy(truncatedbuffer, 0, buff, 0, cursor + 1)

		if shiftseed then math.randomseed(os.time()) end

		if Profiler then
			Profiler.End()
		end

		return truncatedbuffer, referencelist
	else
		error(`Expected a table to be encoded into a buffer, got {typeof(value)}`, 0)
	end
end
