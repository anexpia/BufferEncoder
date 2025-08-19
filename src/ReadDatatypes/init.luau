--[[ 
	## made by anexpia •…• ## 

	originally this also had write functions for each datatype
	but i found that it was slower than having if conditions

	so now it only contains read functions and thats it
]]

local bytetofunction = {}
local bytetodatatype = {}

for _, t in script:GetChildren() do
	local name = t.Name
	if t.Name == "template" then continue end

	for num, func in require(t) do
		if bytetodatatype[num] then
			warn(`The modules {name} and {bytetodatatype[num]} are using the same byte {num}`)
			continue
		end

		bytetofunction[num] = func
		bytetodatatype[num] = name
	end
end

table.clear(bytetodatatype)
bytetodatatype = nil :: any

local enumbyte = 19
local enumitembyte = 20

--                            math.huge           -math.huge             nan
local f106, f107, f108 = bytetofunction[106], bytetofunction[107], bytetofunction[108]
local f103 = bytetofunction[103] -- returns 0

function bytetofunction.adjustforsettings(enumbehavior, sanitize_nanandinf: boolean?)
	bytetofunction[enumbyte] = enumbehavior.decodeEnum 
	bytetofunction[enumitembyte] = enumbehavior.decodeEnumItem

	if sanitize_nanandinf then 
		for i = 106, 108 do 
			bytetofunction[i] = f103
		end
	else 
		bytetofunction[106], bytetofunction[107], bytetofunction[108] = f106, f107, f108
	end

end

return bytetofunction
