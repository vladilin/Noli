extends Object

# Robust CSV parser for Godot 4.x, handles commas, newlines, and quotes in fields
func parse(text: String) -> Array:
	var rows = []
	var row = []
	var field = ""
	var in_quotes = false
	var i = 0
	while i < text.length():
		var c = text[i]
		if in_quotes:
			if c == '"':
				if i + 1 < text.length() and text[i + 1] == '"':
					field += '"'  # Escaped quote
					i += 1
				else:
					in_quotes = false
			else:
				field += c
		else:
			if c == '"':
				in_quotes = true
			elif c == ',':
				row.append(field)
				field = ""
			elif c == '\n' or c == '\r':
				if field != "" or row.size() > 0:
					row.append(field)
					rows.append(row)
					row = []
					field = ""
				# Handle \r\n (Windows newlines)
				if c == '\r' and i + 1 < text.length() and text[i + 1] == '\n':
					i += 1
			else:
				field += c
		i += 1
	if field != "" or row.size() > 0:
		row.append(field)
		rows.append(row)
	return rows
