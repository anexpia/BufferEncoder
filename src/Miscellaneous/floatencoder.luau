--!native
--!optimize 2
--!strict

-- read float16 number from buffer
local function readf16(buff: buffer, cursor: number): number
	local n: number = buffer.readu16(buff, cursor)
	local mantissa: number, exponent: number, sign: number = bit32.extract(n, 0, 10), 
														 	 bit32.extract(n, 10, 5), 
															 bit32.extract(n, 15, 1)

	if mantissa == 0b0000000000 then
		if exponent == 0b00000 then return 0
		elseif exponent == 0b11111 then 
			return if sign == 1 then -math.huge else math.huge 
		end
	elseif exponent == 0b11111 then return 0/0 end 
	
	local value: number = ((mantissa / 1024) + 1) * 2 ^ (exponent - 15)

	if sign == 1 then return -value end 
	return value
end

-- write number as float16 into buffer
local function writef16(buff: buffer, cursor: number, value: number): ()
	if value == 0 then buffer.writeu16(buff, cursor, 0)
	elseif value >= 65520 then buffer.writeu16(buff, cursor, 0b0_11111_0000000000)
	elseif value <= -65520 then buffer.writeu16(buff, cursor, 0b1_11111_0000000000)
	elseif value ~= value then buffer.writeu16(buff, cursor, 0b0_11111_0000000001)
	else
		local sign: number = 0

		if value < 0 then 
			sign = 1 
			value = -value 
		end

		local mantissa: number, exponent: number = math.frexp(value)
		if exponent < -14 then -- safeguard against tiny exponents like -20
			buffer.writeu16(buff, cursor, 0)
			return 
		end

		buffer.writeu16(buff, cursor, bit32.bor((mantissa * 2048 - 1023.5), (exponent + 14) * 2^10, (sign) * 2^15))
	end
end


return {
	writef16 = writef16;
	readf16 = readf16;
}
