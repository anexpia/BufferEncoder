type anyTable = { [any]: any }

export type encodeinfo = {
	valuepositionlookup: anyTable;

	settings: WriteSettings,
	scanlist: { anyTable },
	referencelist: { any },
	
	allocatedsize: number;
}

export type decodeinfo = {
	sanitize_nanandinf: boolean?,

	references: { any }?;

	deduplicationtable: { any };
	tables: { anyTable };
}

export type WriteSettings = {
	allowdeduplication: boolean?,
	allowreferences: boolean?,
	shiftseed: number?,

	rbxenum_behavior: "full" | "compact" | nil,
	color3always6bytes: boolean?,
}

export type ReadSettings = {
	allowdeduplication: boolean?,
	references: { any }?,
	shiftseed: number?,

	rbxenum_behavior: "full" | "compact" | nil,
	sanitize_nanandinf: boolean?,
}

export type datatypedecodinginfo = {
	[number]: (buff: buffer, byte: number, cursor: number, info: decodeinfo) -> (any, number, boolean?),
}

return 0
