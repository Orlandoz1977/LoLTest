GDPC                 �                                                                         P   res://.godot/exported/133200997/export-8a9eb42d915637a611a7851a8930d5b2-LvL1.scn +            �)7�
�ݝd�f�bPH    ,   res://.godot/global_script_class_cache.cfg  �F            � Z&��j;����-��    D   res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex0      &      A]/�no.^La_L�;       res://.godot/uid_cache.bin  �M      U       �fkrE��O �I��R�       res://LvL1.tscn.remap   @F      a       �^�y��w����H�g       res://icon.svg  �I      �      �W|��/�\�pF[       res://icon.svg.import   `*      �       w�1Kt&/ɿ���       res://project.binary N      �      9��ݒp,c9�#��U       res://scripts/LoLApi.gd �            �Ŏ��RR�6��l<_�        res://scripts/conversions_lib.gd        �      ڣ�L�2&�F����6        res://scripts/file_import_lib.gd�      P      O��m�w�JJ��#Z��       res://scripts/library.gd�	      �       ��e��s_��*%qD    $   res://scripts/load_translations.gd  �
            �}��,����Y.��       res://scripts/string_lib.gd        )      L�y���ė�h����â       res://translations.json 0.            k='����(���(�                class_name ConversionsLib
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
class_name Library
# Base class for libraries

# Prevents instantiation of the library.
func _init():
	var name = self.get_class()
	assert(
		false,
		"{0} is not supposed to be initialized. Use its static functions directly.".format([name])
	)
           class_name TranslationsLoader
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
class_name LoLApi
extends Node

# Importar scripts existentes
const ConversionsLib = preload("res://scripts/conversions_lib.gd")
const FileImportLib = preload("res://scripts/file_import_lib.gd")
const TranslationsLoader = preload("res://scripts/load_translations.gd")
const StringLib = preload("res://scripts/string_lib.gd")

# Señales para manejar los mensajes recibidos
signal start_message_received(payload)
signal translation_message_received(payload)
signal load_state_message_received(payload)
signal pause_message_received(payload)
signal unpause_message_received(payload)

# Mapeo de nombres de mensajes entrantes a señales
const INCOMING_MESSAGE_NAMES = {
	"start": "start_message_received",
	"language": "translation_message_received",
	"loadState": "load_state_message_received",
	"pause": "pause_message_received",
	"resume": "unpause_message_received",
}

# Mapeo de nombres de mensajes salientes
const OUTGOING_MESSAGE_NAMES = {
	"READY": "gameIsReady",
	"TTS": "speakText",
	"REQ_SAVES": "loadState",
	"SAVE": "saveState",
	"PROGRESS": "progress",
	"COMPLETE": "complete",
}

# Inicializar el listener de mensajes
func _ready():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""
			window.addEventListener("message", function(event) {
				GodotLoLApi.receive_message(event.data);
			});
		""")

# Función para manejar los mensajes recibidos
func receive_message(data):
	var message_data = FileImportLib.json_to_dictionary(data)
	var message_name = message_data.get("messageName", "")
	var payload = message_data.get("payload", {})

	match message_name:
		"start":
			emit_signal("start_message_received", payload)
		"pause":
			emit_signal("pause_message_received", payload)
		"resume":
			emit_signal("unpause_message_received", payload)
		"language":
			emit_signal("translation_message_received", payload)
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
func send_ready_message():
	send_message("READY", {
		"aspectRatio": "16:9",
		"resolution": ConversionsLib.vector2_to_string(DisplayServer.window_get_size())
	})

func send_tts_message(text_key: String):
	send_message("TTS", {
		"key": text_key
	})

func send_saves_request_message():
	send_message("REQ_SAVES")

func send_save_state_message(data: Dictionary):
	send_message("SAVE", {
		"data": data
	})

func send_progress_message(current_progress: int, maximum_progress: int):
	send_message("PROGRESS", {
		"currentProgress": current_progress,
		"maximumProgress": maximum_progress
	})

func send_complete_message():
	send_message("COMPLETE")
       class_name StringLib  # class_name debe estar al principio del archivo
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
       GST2   �   �      ����               � �        �  RIFF�  WEBPVP8L�  /������!"2�Hrm�n�Ts�#��� ��Ԁ������g��f�#I����2���w5 z���1��H�#Y���úW���9ȵm-k�|P�C	�<��m�Rܭ d�o���m$EJ�vw��ԶmO�f���23ØyIG��23s�����̐�-�?�#�om�VR����ĥၝ`!m<�  mcm@��Jb�M�t���6�$z��uS�70��`U$&�&g�]����xa{���c���~�*�~�
�� ��B���H��~�~�V�)�J�:̠Ʉ	rYlrs6E�M5�hB�C?Q��x0sT��IGK��پl9��]�Cڗ-�-����1ᇕ��HŦ�Mv�.�i�q�4N[���i������RRy�:[�q�q�Ti��B]x���M�kP�tY�&sڶt	u��݁z���Lф��P�PA���w���>�ʎ
0�ȹ�v�6���:������^�iL.cB؍1�I�w� ���c�Yy��Na�y�2+�9:���͏}����:�i���eX���s=S�ZL�<oJ��M�Z�JU�T�27�E��4����"k���&:�-��zK�ڭ:���Yn����EU�Tq�Sm�Jav"2Q܉�[ ��
}RP#����s,��}��g��lh�jcGJy��в�6�N�"�����+��Ģ�7n�a�j;|pW�f��E}�%�XA�N
�䑭���j��t���+���\��EH)�n��!:��^Pk�]�|��lT ��Z�4�729f�Ј)w��T0Ĕ�ix�\�b�9�<%�#Ɩs�Z�O�mjX �qZ0W����E�Y�ڨD!�$G�v����BJ�f|pq8��5�g�o��9�l�?���Q˝+U�	>�7�K��z�t����n�H�+��FbQ9���3g-UCv���-�n�*���E��A�҂
�Dʶ� ��WA�d�j��+�5�Ȓ���"���n�U��^�����$G��WX+\^�"�h.���M�3�e.
����MX�K,�Jfѕ*N�^�o2��:ՙ�#o�e.
��p�"<W22ENd�4B�V4x0=حZ�y����\^�J��dg��_4�oW�d�ĭ:Q��7c�ڡ��
A>��E�q�e-��2�=Ϲkh���*���jh�?4�QK��y@'�����zu;<-��|�����Y٠m|�+ۡII+^���L5j+�QK]����I �y��[�����(}�*>+���$��A3�EPg�K{��_;�v�K@���U��� gO��g��F� ���gW� �#J$��U~��-��u���������N�@���2@1��Vs���Ŷ`����Dd$R�":$ x��@�t���+D�}� \F�|��h��>�B�����B#�*6��  ��:���< ���=�P!���G@0��a��N�D�'hX�׀ "5#�l"j߸��n������w@ K�@A3�c s`\���J2�@#�_ 8�����I1�&��EN � 3T�����MEp9N�@�B���?ϓb�C��� � ��+�����N-s�M�  ��k���yA 7 �%@��&��c��� �4�{� � �����"(�ԗ�� �t�!"��TJN�2�O~� fB�R3?�������`��@�f!zD��%|��Z��ʈX��Ǐ�^�b��#5� }ى`�u�S6�F�"'U�JB/!5�>ԫ�������/��;	��O�!z����@�/�'�F�D"#��h�a �׆\-������ Xf  @ �q�`��鎊��M��T��(}�_�w�}���r�L|� |v�՘�e��yw�S|�� U�${1J'��[�ڞ�x��2����:��Ggjxؗ�m3�ivF��`�ߢe��a��G��V�t��is��J�����'�Q_5W���?�l�{1g���kԶ�zk�T�-|�V*��ޜZ�CW�,��(۝��Ǘ��� T{?�^��{���(9�(��u�5�͚����y~)J�&������}	@���74���&���N-�L_���o��������ݵ=�����y�VK��&�����������G�xߠ�]������ev%�{��eycc�{s�\�RАk{�|��P���eu�~]���2?0�F���1�V&x���:c������/�g{�.F)PDwGf�M�����(�0}��ag��e�'���6l�"s�L�H�c�"��̊ #Yf���:8������
�Eذ�3u�k5�Bt�m���!�#*Eǚa�ܰ_��Tq�.�0}�a@�^G��N�a��\��A�N�0���I���lq�5�+(��Џ�����Yq�wz_���*;<-w�;tX�"��n�'����Mۭy`0��kOԙ������,�����x�'��S�ݚa�텷�u��h����\��~�d.;����q5f-���������|�������ͪQl�9���~�\����7��^�?��������e�u$?`�߇u��*��yT����������A�6�E~`\�����n��1l�7t�;G�I��c��,VJ�Q[;�	Y|�kj��*�na����U�/�o��u�	?�闯7��׏w�m��.�|�~�}���r��RΎ��o.���o֜��~�_���.��ǿ�χ���q�˹���7�|�����~��[O5����2�%>�K�C�T׿�Y�L�%-	F�E�H,��v�t�f����i�V�N�'g��/)� ^.7��T��f��y�(����R��~f��p®��O���V�\���k���lڮ2aW��jc�{%�Y\m�šN�+����Y��׹H���y?��ۋG�~��b�l�9��dϻĸ��
��l�X��ɎZ�YDVD%*�P&��m�����]r�&��C����-2G-�-���d�gcgH��!�#�s^���s�l#/��l�r��#���8%Ӭ�L��1㬤ӖIYIa��0�qw���M�>�� � �����c��-$��D&����i�|L�n;�YˡR�����.�mK�P9_T� �c�����F*� ����+�\��|�Mt��nS�#��^+�l���2���|��9�Ç��9��X2mZPnߺ0P��������l�C�t'�^�A\�Q6�?Ɯ�_�EDVDDv�������vCcʁ&rw`w@�'c�%��6�_>0�m��i�}ܢ���            [remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://onrx0wpt1klv"
path="res://.godot/imported/icon.svg-218a8f2b3041327d8a5756f3a245f83b.ctex"
metadata={
"vram_texture": false
}
 RSRC                    PackedScene            ��������                                                  resource_local_to_scene    resource_name 	   _bundled    script       Script    res://scripts/LoLApi.gd ��������      local://PackedScene_kabw7          PackedScene          	         names "         LvL1    script    Node2D 
   ColorRect    offset_right    offset_bottom    color    	   variants                     �4D    ��C     �?  �?���>  �?      node_count             nodes        ��������       ����                            ����                               conn_count              conns               node_paths              editable_instances              version             RSRC            {
	"en": {
		"GameName": "Fraction Feast, Pizza Paradise",
		"btn_NewGame": "New Game",
		"btn_Continue": "Continue",
		
		
		"Level_1_Part_1": "Welcome to Turtle Pizza Paradise! Our customers are hungry, and it’s your job to deliver the perfect slice!",
		"Level_1_Part_2": "Before we start delivering pizzas, let’s take a quick look at something important!",  
		"Level_1_Part_3": "This is a number line. It begins at 0 and ends at 1.",  
		"Level_1_Part_4": "We can split it into equal sections. These sections are called FRACTIONS.",  
		"Level_1_Part_5": "Fractions are written with two numbers—one on top and one on the bottom.",  
		"Level_1_Part_6": "The bottom number, the DENOMINATOR, tells us how many equal parts the whole is divided into.",  
		"Level_1_Part_7": "The top number, the NUMERATOR, shows how many parts we are focusing on.",  
		"Level_1_Part_8": "Let’s add another number line and divide it into 4 equal parts.",  
		"Level_1_Part_9": "Now the DENOMINATOR is 4 because the whole is split into 4 sections.",  
		"Level_1_Part_10": "Look! These two fractions are in the same place on the line. That means they are EQUIVALENT FRACTIONS!",  
		"Level_1_Part_11": "Let’s add a third number line and divide it into 8 equal parts.",  
		"Level_1_Part_12": "Now the DENOMINATOR is 8, since the line is cut into 8 pieces.",  
		"Level_1_Part_13": "Check it out! We can now see even more EQUIVALENT FRACTIONS!",  
		"Level_1_Part_14": "Now that we know how fractions work, it's time to put our skills to the test!",  
		"Level_1_Part_15": "A customer’s order might look different from the slice you’re carrying, but if they’re equivalent, it’s a perfect match! Pay close attention and serve wisely!",
		"Level_1_Part_16": "Use W, A, S, D or the arrow keys to move around the beach. No need to press a button to deliver—just walk up to the right turtle and hand them their perfect slice!",
		
		"TutoNum": "NUMERATOR",
		"TutoDen": "DENOMINATOR",
		
		
		
				
		
		
		
		
		
		
		"Level_2_Part_1": "Things are heating up at Turtle Pizza Paradise! Now, customers might ask for their pizza using fraction symbols or a pizza icon that shows the slice they want. Pay close attention!",
		"Level_2_Part_2": "A whole pizza can look different depending on how it's sliced, but the fractions should still be equivalent. Make sure you match the right order!",
		"Level_2_Part_3": "Watch out! Some small creatures are moving around the beach. Those spiky-shelled snails might slow you down if you get too close. Stay sharp and keep those deliveries on time!",
		"Level_3_Part_1": "Looks like we have a new... customer? A crab has appeared on the beach, and it seems pretty interested in your pizzas! But watch out—it throws its claws, and they’re not asking for a tip!",
		"Level_3_Part_2": "The path is getting longer, so stay focused and keep those deliveries moving. Remember, a perfect slice means a happy customer... and fewer angry crabs!",
		"Level_4_Part_1": "The sun has set, but the pizza rush never stops! Customers are still hungry, even at night. Keep your eyes open and your deliveries sharp!",
		"Level_4_Part_2": "Something is lurking in the darkness… We’re not sure what it is, but it shoots glowing energy balls! Maybe it just wants a slice? Either way, stay out of its way!",
		"Level_4_Part_3": "Wait… square pizzas? That’s right! Some customers will now ask for their slices using square-shaped pizzas. It may look different, but don’t let that confuse you—fractions are still fractions!",
		"Level_5_Part_1": "Dash! Watch out! There’s a new creature lurking near the water. It looks like a frog... but it sure has a long tongue! Be careful—it might try to 'taste' your delivery!",
		"Level_5_Part_2": "First square pizzas, now triangular ones?! Our customers sure have unique tastes! But remember, no matter the shape, the fractions must still match!",
		"Level_6_Part_1": "Round, square, triangular—our customers are getting creative with their orders! Keep your focus and remember: different shapes, same fractions!",
		"Level_7_Part_1": "Watch out! Pufferfish ahead! When they get startled, they explode—sending sharp spines flying everywhere! Move carefully, or you’ll end up as a very slow delivery turtle...",
		"Level_7_Part_2": "As if the dark wasn’t enough... now it’s raining! But hungry customers don’t take breaks, so neither can you. Keep those pizzas dry and those orders right!",
		"Level_8_Part_1": "Finally, the sun is up, and the rain is gone! But don’t celebrate just yet... there’s a new sea creature around. These glowing fish may look cool, but their lights pack a surprise—stay out of their laser beams!",
		"Level_8_Part_2": "Daylight makes deliveries easier, but the challenge isn’t over! Stay sharp, dodge those glowing fish, and keep those pizzas heading to the right turtles!",
		"Level_8_Part_3": "Incredible work, Dash! You’ve delivered every last pizza with speed and accuracy. The turtles are full and happy, all thanks to your fraction skills!",
		"Level_8_Part_4": "Understanding equivalent fractions wasn’t just about pizzas it helped you make the right choices, no matter how the orders were shown. Fractions are everywhere, and now you’re a pro at spotting them!",
		"Level_8_Part_5": "Thanks for being the best pizza delivery turtle on the island! Keep practicing your fraction skills, and who knows? Maybe your next challenge will be even bigger! See you next time, Dash!"
	},
	"es": {
		"GameName": "",
		"btn_NewGame": "Nuevo Juego",
		"btn_Continue": "Continuar",
		"Level_1_Part_1": "",
		"Level_1_Part_2": "",
		"Level_1_Part_3": "",
		"Level_1_Part_4": "",
		"Level_1_Part_5": "",
		"Level_2_Part_1": "",
		"Level_2_Part_2": "",
		"Level_2_Part_3": "",
		"Level_3_Part_1": "",
		"Level_3_Part_2": "",
		"Level_4_Part_1": "",
		"Level_4_Part_2": "",
		"Level_4_Part_3": "",
		"Level_5_Part_1": "",
		"Level_5_Part_2": "",
		"Level_6_Part_1": "",
		"Level_7_Part_1": "",
		"Level_7_Part_2": "",
		"Level_8_Part_1": "",
		"Level_8_Part_2": "",
		"Level_8_Part_3": "",
		"Level_8_Part_4": "",
		"Level_8_Part_5": ""
	}
}    [remap]

path="res://.godot/exported/133200997/export-8a9eb42d915637a611a7851a8930d5b2-LvL1.scn"
               list=Array[Dictionary]([{
"base": &"RefCounted",
"class": &"ConversionsLib",
"icon": "",
"language": &"GDScript",
"path": "res://scripts/conversions_lib.gd"
}, {
"base": &"RefCounted",
"class": &"FileImportLib",
"icon": "",
"language": &"GDScript",
"path": "res://scripts/file_import_lib.gd"
}, {
"base": &"RefCounted",
"class": &"Library",
"icon": "",
"language": &"GDScript",
"path": "res://scripts/library.gd"
}, {
"base": &"Node",
"class": &"LoLApi",
"icon": "",
"language": &"GDScript",
"path": "res://scripts/LoLApi.gd"
}, {
"base": &"Library",
"class": &"StringLib",
"icon": "",
"language": &"GDScript",
"path": "res://scripts/string_lib.gd"
}, {
"base": &"RefCounted",
"class": &"TranslationsLoader",
"icon": "",
"language": &"GDScript",
"path": "res://scripts/load_translations.gd"
}])
     <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="124" height="124" x="2" y="2" fill="#363d52" stroke="#212532" stroke-width="4" rx="14"/><g fill="#fff" transform="translate(12.322 12.322)scale(.101)"><path d="M105 673v33q407 354 814 0v-33z"/><path fill="#478cbf" d="m105 673 152 14q12 1 15 14l4 67 132 10 8-61q2-11 15-15h162q13 4 15 15l8 61 132-10 4-67q3-13 15-14l152-14V427q30-39 56-81-35-59-83-108-43 20-82 47-40-37-88-64 7-51 8-102-59-28-123-42-26 43-46 89-49-7-98 0-20-46-46-89-64 14-123 42 1 51 8 102-48 27-88 64-39-27-82-47-48 49-83 108 26 42 56 81zm0 33v39c0 276 813 276 814 0v-39l-134 12-5 69q-2 10-14 13l-162 11q-12 0-16-11l-10-65H446l-10 65q-4 11-16 11l-162-11q-12-3-14-13l-5-69z"/><path d="M483 600c0 34 58 34 58 0v-86c0-34-58-34-58 0z"/><circle cx="725" cy="526" r="90"/><circle cx="299" cy="526" r="90"/></g><g fill="#414042" transform="translate(12.322 12.322)scale(.101)"><circle cx="307" cy="532" r="60"/><circle cx="717" cy="532" r="60"/></g></svg>                 �"�P�6   res://icon.svg+_��˽�h   res://index.tscn+_��˽�h   res://LvL1.tscn           ECFG      _custom_features         LoLApi     application/config/name         LoLTest    application/run/main_scene         res://LvL1.tscn    application/config/features$   "         4.3    Forward Plus       application/config/icon         res://icon.svg     autoload/LoL_Api          *res://scripts/LoLApi.gd#   rendering/renderer/rendering_method         gl_compatibility*   rendering/renderer/rendering_method.mobile         gl_compatibility    