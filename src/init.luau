--[[ 
	## made by anexpia •…• ##
	
v---v---v---v---v---v currently supported types v---v---v---v---v---v

[x] -> datatype has deduplication 
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
	this toggles if color3 components are always saved as float16 numbers

> rbxenum_behavior: string ( 'full' | 'compact' ) >> default 'compact'
	this has 2 behaviors currently.

	>  "full"
		encodes the enums as <19> <u8 length> <string>
		enumitems are <20> <u8 length> <string> <u16 value> 

		this should be used for data saving as this guarantees the enumitems stay the same as long as roblox doesn't do anything weird
	
		* encoded values are deduplicated if allowed, so if the same enum & enumitem are encoded multiple times
		  it will not cost the same to encode it each time

	> "compact" *default behavior*
		this should ONLY BE USED for sending the enums & enumitems in temporary sessions!!! (like in remotes)
		the order of the enum & enumitem table is not guaranteed to be consistent between
		every session thus you will definitely encounter bugs if you use this for saving data

		* no deduplication since there's no benefit, as this saves both enums and enumitems as 3 bytes,

> serverclientsyncing: boolean
	determines whether to sync enumitems and custom values between client and server

> sanitize_nanandinf: boolean
	determines whether to turn NaN and math.huge into 0 when reading buffer content
	  this only sanitizes them for Numbers, Vectors, Rays, and CFrames
]]

return {
	read = require(script.Read);
	write = require(script.Write);
	enums = require(script.Enums)
}