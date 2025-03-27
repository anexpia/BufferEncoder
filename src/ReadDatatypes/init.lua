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

return bytetofunction
