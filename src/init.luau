--[[ 
	## made by anexpia •…• ##
	
v---v---v---v---v---v currently supported types v---v---v---v---v---v

[x] -> datatype have deduplication 
deduplication means that if the value exists in more than one table, it will be encoded only once
this reduces buffer size and time it takes to encode the value

luau types
	> string [x]
	> number [x]
	> boolean
	> nil
	> table
	> buffer
	> vector [x]

roblox types
	> Enum [x]? only if rbxenum_behavior is 'full'
	> EnumItem [x]? only if rbxenum_behavior is 'full'
	
	> BrickColor
	> Color3
	> ColorSequence
	> NumberSequence
	> NumberRange
	> CFrame
	> Ray
		
	> Vector3int16
	> Vector2
	> Vector2int16
	> Rect
	> UDim
	> UDim2
	> PhysicalProperties

	> Content
	> Font
	> DateTime

can also encode custom values into 2 bytes 
	> this is done by using enums.register(name, value)
	> value is optional, itll give you a newproxy() if you dont give it a value
	> max 255 values
	

v---v---v---v---v---v---v---v settings v---v---v---v---v---v---v---v

> color3always6bytes: boolean >> default false
	this toggles if color3s are always saved as float16 numbers

> rbxenum_behavior: string ( 'full' | 'compact' ) >> default 'compact'
	details on what this does are present in 'RbxEnumEncoder' script

> serverclientsyncing: boolean
	determines whether to sync enumitems and custom values between client and server
]]

return {
	read = require(script.Read);
	write = require(script.Write);
	enums = require(script.Enums)
}