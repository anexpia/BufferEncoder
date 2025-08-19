<img src="icon.png" alt="Icon of BufferEncoder" width="200" height="200">

# BufferEncoder
A very efficient and simple-to-use encoder that turns tables into buffers.\
Unlike other buffer serializers, BufferEncoder doesn't require you to define the structure of the buffer, and it supports all datatypes you'd normally have in a table.

# Features

* Very optimized and space-efficient
* Supports any type of table (array, dictionary, mixed), cyclic tables, and any value for keys in dictionaries
* Supports encoding every datatype that you'd realistically put in a table
* Can encode non-encodeable values into 2 bytes if registered beforehand using **encoder.enums.register()**
* Deduplicates repeated tables, strings, numbers, vectors, and enumitems
* Has simple encryption that relies on psuedo-random number generation
* Fully typed

List of all datatypes that can be encoded are in [this module](src/init.luau)

# API
### Encoder.write(table, writestart, writesettings) -> ( buffer, {any}? )
Converts the given `table` into a buffer\
If `writestart` is provided, table content writing will begin from the number provided in the buffer

`writesettings` fields: {
-    **allowdeduplication: boolean** -- attempt to deduplicate repeated values if enabled to reduce buffer size
-    **allowreferences: boolean** -- if enabled, return a table containing the values it couldn't encode alongside the buffer.
-    **shiftseed: number** -- the type bytes of values are shuffled using the seed.
-    **rbxenum_behavior: "full" | "compact"** -- override for the default setting in settings module.
-    **color3always6bytes: boolean** -- override for the default setting in settings module.

}

> [!WARNING]
> If you really need to securely encrypt your buffer, do not rely on the shiftseed field of writesettings.

---
### Encoder.read(buffer, readstart, readsettings) -> { [any]: any }
Converts the given `buffer` back into a table\
Parameters should be consistent with **Encoder.write()** so that you don't encounter bugs

`readsettings` fields: {
-    **allowdeduplication: boolean** -- if the buffer was written with deduplication enabled, **this must be enabled.**
-    **references: {any}** -- table of values that couldn't be encoded which is returned by encoder.write()
-    **shiftseed: number** -- the type bytes of values are unshuffled using the seed.
-    **rbxenum_behavior: "full" | "compact"** -- override for the default setting in settings module.
-    **sanitize_nanandinf: boolean** -- override for the default setting in settings module.

}

---
### Encoder.enums.register(name, value) -> any
Registers `value` to be encoded, even if it is normally not encode-able\
If value is not provided, it returns userdata created using **newproxy()**

The byte used to register the name value pair is synced with the client, so the same value can be sent between client & server via a remote if the value is defined to be the same on both ends

> [!CAUTION]
> This errors if the value is already registered and for certain values such as booleans, 0, 1, -1, "", math.huge, and NaN

---
### Encoder.enums.remove(name)
Removes the name value pair from the custom value registry

# Settings
Settings can be changed by either changing them directly in the 'Settings' module or by adding the setting as an attribute in the module with the value you want

* rbxenum_behavior ("compact" or "full") - Changes how enumitems are encoded, defaults to **'full'**.\
Exact details of what each type does are inside [this module](src/init.luau)
* color3always6bytes (boolean) - Sets whether Color3s are always encoded as float16 values, defaults to **false**.
* serverclientsyncing (boolean) - Determines whether to sync EnumItems and custom values from server to client, defaults to **false**
* sanitize_nanandinf (boolean) - Determines whether to turn NaN and math.huge into 0 when reading buffer content, defaults to **false**\
*This only sanitizes them for Numbers, Vectors, Rays, and CFrames.*

# License
BufferEncoder is licensed under the [GPL-3.0 License](LICENSE).

