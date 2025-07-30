local Encoder = script.Parent

-- explanation for each of the settings exists in the main module
local t = {
    color3always6bytes = false;
    rbxenum_behavior = "full" :: "full" | "compact";

    serverclientsyncing = false;
    sanitize_nanandinf = false;
}

for att, value in Encoder:GetAttributes() do 
    if t[att] ~= nil then
        if type(value) == type(t[att]) then t[att] = value
        else warn(`[BUFFERENCODER] {typeof(value)} is not a valid type for the setting {att}`) end
    end
end

return t