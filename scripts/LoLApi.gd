class_name LoLApi
extends Node

# Importar scripts existentes
const ConversionsLib = preload("res://scripts/conversions_lib.gd")
const FileImportLib = preload("res://scripts/file_import_lib.gd")
const TranslationsLoader = preload("res://scripts/load_translations.gd")
const StringLib = preload("res://scripts/string_lib.gd")

# Señales para manejar los mensajes recibidos
signal start_message_received(payload)
signal language_message_received(payload)
signal load_state_message_received(payload)
signal pause_message_received(payload)
signal resume_message_received(payload)

# Mapeo de nombres de mensajes entrantes a señales
const INCOMING_MESSAGE_NAMES = {
	"start": "start_message_received",
	"language": "language_message_received",
	"loadState": "load_state_message_received",
	"pause": "pause_message_received",
	"resume": "resume_message_received",
}

# Mapeo de nombres de mensajes salientes
const OUTGOING_MESSAGE_NAMES = {
	"gameIsReady": "gameIsReady",
	"speakText": "speakText",
	"loadState": "loadState",
	"saveState": "saveState",
	"progress": "progress",
	"complete": "complete",
}

# Inicializar el listener de mensajes
func _ready():
	if OS.has_feature("web"):
		# Registrar la función `receive_message` en el ámbito global de JavaScript
		JavaScriptBridge.eval("""
			window.GodotLoLApi = {
				receive_message: function(data) {
					GodotLoLApi._receive_message(data);
				}
			};
		""")
		# Escuchar mensajes desde la plataforma LoL
		JavaScriptBridge.eval("""
			window.addEventListener("message", function(event) {
				GodotLoLApi.receive_message(event.data);
			});
		""")

# Función para manejar los mensajes recibidos
func receive_message(data):
	var json = JSON.new()  # Crear una instancia de JSON
	var error = json.parse(data)  # Parsear la cadena JSON

	if error != OK:
		printerr("Error parsing JSON: ", json.get_error_message())
		return

	var message_data = json.get_data()  # Obtener los datos parseados
	var message_name = message_data.get("messageName", "")
	var payload = message_data.get("payload", {})

	# Parsear el payload si es una cadena JSON
	if typeof(payload) == TYPE_STRING:
		error = json.parse(payload)
		if error == OK:
			payload = json.get_data()
		else:
			printerr("Error parsing payload JSON: ", json.get_error_message())
			payload = {}

	match message_name:
		"start":
			emit_signal("start_message_received", payload)
		"pause":
			emit_signal("pause_message_received", payload)
		"resume":
			emit_signal("resume_message_received", payload)
		"language":
			emit_signal("language_message_received", payload)
		"loadState":
			emit_signal("load_state_message_received", payload)
		_:
			printerr("Unknown message received: ", message_name)

# Función para enviar mensajes a la API de LoL
func send_message(message_name: String, payload: Dictionary = {}) -> void:
	var payload_json = JSON.stringify(payload)
	var js_code = """
		parent.postMessage({
			message: "{0}",
			payload: {1}
		}, '*');
	""".format([message_name, payload_json])
	
	if OS.has_feature("web"):
		JavaScriptBridge.eval(js_code)
	else:
		printerr("send_message is only available in HTML5 exports.")
			
# Funciones específicas para enviar mensajes comunes
func send_game_is_ready():
	send_message("gameIsReady", {
		"aspectRatio": "16:9",
		"resolution": ConversionsLib.vector2_to_string(DisplayServer.window_get_size())
	})

func send_speak_text(text_key: String):
	send_message("speakText", {
		"key": text_key
	})

func send_load_state():
	send_message("loadState", {})

func send_save_state(data: Dictionary):
	send_message("saveState", {
		"data": data
	})

func send_progress(current_progress: int, maximum_progress: int):
	send_message("progress", {
		"currentProgress": current_progress,
		"maximumProgress": maximum_progress
	})

func send_complete():
	send_message("complete", {})
