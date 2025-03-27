--!native
--!optimize 2

--[[ 
	## made by anexpia •…• ## 

	i dont think you can actually call this a float number converter but
	if it works, its fine
]]

local function convert(num: number, bitcount: number, precisionbits: number)
	local significandbits = (bitcount - precisionbits) - 1
	local intlimit = (2^significandbits - 1)
	
	local sign = if num < 0 then 0b1 else 0b0
	local int, fraction = math.modf(math.abs(num))
	if int > intlimit then int = intlimit end 
	-- ^ erroring is bad for encoder so removed error and replaced it with that

	local wholebits, decimalbits = 32 - bit32.countlz(int), 0

	local decimal = 0
	if fraction > 0 and wholebits < significandbits then
		decimalbits = math.min(significandbits - wholebits, (2^precisionbits) - 1)
		
		for i = 1, decimalbits do 
			local result, remainder = math.modf(fraction * 2)
			fraction = remainder 

			if result == 1 then decimal += 2 ^ (i-1) end
			if remainder == 0 then decimalbits = i; break end
		end
	end

	local significand = bit32.bor(decimal, bit32.lshift(int, decimalbits))
	return bit32.bor(sign, decimalbits * 2, bit32.lshift(significand, 1 + precisionbits))
end

local function deconvert(num, bitcount: number, precisionbits: number)
	local significandbits = (bitcount - precisionbits) - 1
	
	local sign, decimalbits = bit32.extract(num, 0), bit32.extract(num, 1, precisionbits)
	local wholenumber, decimal = 0, 0
	
	if decimalbits == 0 then
		wholenumber = bit32.extract(num, 1 + precisionbits, significandbits)
	else 
		local offset = 1 + precisionbits
		for i = 1, decimalbits do 
			decimal += bit32.extract(num, offset + (i-1)) * 2^(-i)
		end

		if decimalbits < significandbits then
			wholenumber = bit32.extract(num, offset + decimalbits, significandbits - decimalbits)
		end
	end

	return ((-1) ^ sign) * (wholenumber + decimal)
end

local function convert_unsigned(num: number, bitcount: number, precisionbits: number)
	local significandbits = (bitcount - precisionbits) 
	local intlimit = (2^significandbits - 1)

	local int, fraction = math.modf(math.abs(num))
	if int > intlimit then int = intlimit end
	-- ^ erroring is bad for encoder so removed error and replaced it with that
	
	local wholebits, decimalbits = 32 - bit32.countlz(int), 0

	local decimal = 0
	if fraction > 0 and wholebits < significandbits then
		decimalbits = math.min(significandbits - wholebits, (2^precisionbits) - 1)

		for i = 1, decimalbits do 
			local result, remainder = math.modf(fraction * 2)
			fraction = remainder 

			if result == 1 then decimal += 2 ^ (i-1) end
			if remainder == 0 then decimalbits = i; break end
		end
	end

	local significand = bit32.bor(decimal, bit32.lshift(int, decimalbits))
	return bit32.bor(decimalbits, bit32.lshift(significand, precisionbits))
end

local function deconvert_unsigned(num, bitcount: number, precisionbits: number)
	local significandbits = (bitcount - precisionbits) 

	local decimalbits = bit32.extract(num, 0, precisionbits)
	local wholenumber, decimal = 0, 0

	if decimalbits == 0 then
		wholenumber = bit32.extract(num, precisionbits, significandbits)
	else 
		for i = 1, decimalbits do 
			decimal += bit32.extract(num, precisionbits + (i-1)) * 2^(-i)
		end

		if decimalbits < significandbits then
			wholenumber = bit32.extract(num, precisionbits + decimalbits, significandbits - decimalbits)
		end
	end

	return (wholenumber + decimal)
end


return {
	convert = convert;
	deconvert = deconvert;
	convert_unsigned = convert_unsigned;
	deconvert_unsigned = deconvert_unsigned;
}
