type table = { [any]: any }
export type encodeinfo = {
	valuepositionlookup: {[any]: any};

	scanlist: { {[any]: any} },
	scancount: number,

	deduplicatedcount: number,
	deduplicatedlookup: { [any]: number | boolean }, 
	deduplicatedarray: { any },

	referencecount: number?,
	referencelist: { any },
	
	allocatedsize: number;
	currentsize: number;
}

export type decodeinfo = {
    bufferstring: string?;
	deduplicationtable: { any };
	references: { any }?;
	tables:  { table };

	didrefwarn: boolean?;
}

export type datatypedecodinginfo = {
	[number]: (buff: buffer, byte: number, cursor: number, info: decodeinfo) -> any,

}

return 0
