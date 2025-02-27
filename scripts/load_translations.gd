class_name TranslationsLoader
# Utility for loading and processing translations from a JSON file

const TRANSLATIONS_FILENAME = "res://translations.json"

# Loads translations from the root file.
static func load_translations_from_root() -> Dictionary:
	var translations_json = FileImportLib.file_to_string(TRANSLATIONS_FILENAME)
	var translations = ConversionsLib.json_to_dictionary(translations_json)
	process_translations(translations)
	return translations

# Processes translations, ignoring language IDs starting with "_".
static func process_translations(translations: Dictionary):
	for key in translations.keys():
		if not key.begins_with("_"):
			process_translation(key, translations[key])

# Processes translation data for a specific language.
static func process_translation(language_code: String, translations: Dictionary):
	var translation = Translation.new()
	translation.locale = language_code
	for key in translations.keys():
		translation.add_message(key, translations[key])
	TranslationServer.add_translation(translation)
