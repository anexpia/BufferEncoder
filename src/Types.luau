type table = { [any]: any }
export type encodeinfo = {
	scanned: { [table]: number },
	scancount: number,

	deduplicatedcount: number,
	deduplicatedlookup: { [any]: number | boolean }, 
	deduplicatedarray: { any },

	referencecount: number?,
	referenceadded: { [any]: number }, 
	referencelist: { any },
	
	allocatedsize: number;
}

export type decodeinfo = {
    bufferstring: string?;
	deduplicationtable: { any };
	tables:  { table }
}

export type datatypedecodinginfo = {
	[number]: (buff: buffer, byte: number, cursor: number, info: decodeinfo) -> any,

}

return 0
