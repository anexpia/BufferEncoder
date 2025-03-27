local Encoder = script.Parent

-- explanation for each of the settings exists in the main module
local t = {
    color3always6bytes = false;
    rbxenum_behavior = "compact" :: "full" | "compact";
	stringsalwayslengthbound = true;
	referencebitsize = 8;

    serverclientsyncing = false;
}

for att, value in Encoder:GetAttributes() do 
    if t[att] then
        if type(value) == type(t[att]) then t[att] = value
        else warn(`[BUFFERENCODER] {typeof(value)} is not a valid type for the setting {att}`) end
    end
end

local refsize = t.referencebitsize
if refsize ~= 8 and refsize ~= 16 and refsize ~= 32 then
	t.referencebitsize = 8 

	warn(`Reference size should be 8, 16, or 32 bits. resetting to 8.`)
end

return t