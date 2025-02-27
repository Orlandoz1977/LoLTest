class_name FileImportLib
# Library for importing files

enum File_Types {JSON}

# Converts file data to a Dictionary.
static func file_to_dictionary(file_path: String, file_type: int) -> Dictionary:
	assert(file_type in File_Types.values(), "Invalid file type")
	var file_content = file_to_string(file_path)
	if file_type == File_Types.JSON:
		return json_to_dictionary(file_content)
	return {}

# Converts file data to an Array.
static func file_to_array(file_path: String, file_type: int) -> Array:
	assert(file_type in File_Types.values(), "Invalid file type")
	var file_content = file_to_string(file_path)
	if file_type == File_Types.JSON:
		return json_to_array(file_content)
	return []

# Reads a file and returns its content as a String.
static func file_to_string(file_path: String) -> String:
	if not FileAccess.file_exists(file_path):
		printerr("File not found: ", file_path)
		return ""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		printerr("Error opening file: ", file_path)
		return ""
	return file.get_as_text()

# Converts a JSON string to a Dictionary.
static func json_to_dictionary(json_text: String) -> Dictionary:
	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		return json.get_data()
	else:
		printerr("Error parsing JSON: ", json.get_error_message())
		return {}

# Converts a JSON string to an Array.
static func json_to_array(json_text: String) -> Array:
	var json = JSON.new()
	var error = json.parse(json_text)
	if error == OK:
		return json.get_data()
	else:
		printerr("Error parsing JSON: ", json.get_error_message())
		return []
