class_name StringLib  # class_name debe estar al principio del archivo
extends Library
# Library for string manipulation

# Surrounds a string with quotes.
static func quotify(s: String) -> String:
	return "\"{0}\"".format([s])

# Flips a string (e.g., "hello" -> "olleh").
static func flip(s: String) -> String:
	return s.reverse()

# Checks if a string begins with any of the given substrings.
static func begins_with_any(s: String, substrings: Array) -> bool:
	for substring in substrings:
		if s.begins_with(substring):
			return true
	return false
