# BufferEncoder
A very efficient and simple-to-use encoder that turns tables into buffers.\
Unlike other buffer serializers, BufferEncoder doesn't require you to define the structure of the buffer, and it supports all datatypes you'd normally have in a table.

# Features

* Very optimized and space-efficient
* Supports mixed tables and cyclic tables
* Supports encoding every datatype that you'd realistically put in a table
* Can encode non-encodeable values into 2 bytes if registered beforehand
* Has simple encryption that relies on psuedo-random number generation
* Fully typed and functions have descriptions.

List of all datatypes that can be encoded are in [this module](https://github.com/anexpia/BufferEncoder/blob/main/src/init.luau)

# API
### Encoder.write(table, writestart, allowreferences, shiftseed) -> ( buffer, {any}? )
Converts the given `table` into a buffer\

If `writestart` is provided, table content writing will begin from `writestart`\
If `allowreferences` is enabled, It will return a table containing all the datatypes it was unable to encode\
The returned table can be used in **Encoder.read()** to be read again when decoding the buffer.\
If `shiftseed` is enabled, It will shift the byte used for the type of the value by a random value acquired using the seed\

---
### Encoder.read(buffer, readstart, references, shiftseed) -> { [any]: any }
Converts the given `buffer` back into a table\
Parameters should be consistent with **Encoder.write()** so that you don't encounter bugs\

---
### Encoder.enums.register<T>(name, value: T?) -> T | userdata
Registers `value` to be encoded, even if it is normally not encode-able\
If value is not provided, it returns userdata created using **newproxy()**\

The byte used to register the name value pair is synced with the client, so the same value can be sent between client & server via a remote if the value is defined to be the same on both ends

> [!CAUTION]
> This errors if the value is already registered and for certain values such as booleans, 0, 1, -1, "", math.huge, and NaN

---
### Encoder.enums.remove(name)
Removes the name value pair from the custom value registry

# Settings
Settings can be changed by either changing them directly in the 'Settings' module or by adding the setting as an attribute in the module with the value you want

* rbxenum_behavior ("compact" or "full") - Changes how enumitems are encoded, defaults to 'false'.\
Exact details of what each type does are inside [this module](https://github.com/anexpia/BufferEncoder/blob/main/src/init.luau)
* color3always6bytes (boolean) - Sets whether Color3s are always encoded as float16 values, defaults to **false**.
* stringsalwayslengthbound (boolean) - Disables encoding strings as zero-terminated strings if enabled, defaults to **true**
* referencebitsize (number: 8, 16, or 32) - Defines how many bits are used to save position of references in the table, defaults to **8**
* serverclientsyncing (boolean) - Determines whether to sync EnumItems and custom values from server to client, defaults to **false**

# License
BufferEncoder is licensed under the [GPL-3.0 License](https://github.com/anexpia/BufferEncoder/blob/main/LICENSE).

