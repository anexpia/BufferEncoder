type table = { [any]: any }
export type encodeinfo = {
	valuepositionlookup: {[any]: any};

	scanlist: { {[any]: any} },
	referencelist: { any },
	
	allocatedsize: number;
}

export type decodeinfo = {
    bufferstring: string?;
	deduplicationtable: { any };
	references: { any }?;
	tables:  { table };
}

export type datatypedecodinginfo = {
	[number]: (buff: buffer, byte: number, cursor: number, info: decodeinfo) -> (any, number, boolean?),

}

return 0
