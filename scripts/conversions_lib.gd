class_name ConversionsLib
# Library for converting data

# Converts a Dictionary to a JSON string.
static func dictionary_to_json(dict: Dictionary) -> String:
	return JSON.stringify(dict)

# Converts a JSON string to a Dictionary.
static func json_to_dictionary(json_text: String) -> Dictionary:
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		printerr("Error while converting JSON: ", json.get_error_message())
		return {}
	return json.get_data()

# Converts a JSON string to an Array.
static func json_to_array(json_text: String) -> Array:
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		printerr("Error while converting JSON: ", json.get_error_message())
		return []
	return json.get_data()

# Converts a Vector2 to a string (e.g., "1024x576").
static func vector2_to_string(v: Vector2) -> String:
	return "{0}x{1}".format([v.x, v.y])
