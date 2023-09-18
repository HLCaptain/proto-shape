@tool
extends Control

@onready var options = %options
@onready var btn_toggle = %btn_toggle

var plugin : EditorPlugin

const PLUGIN_FOLDER := "res://addons/"

func _ready():
	plugin.main_screen_changed.connect(update_current_main_screen)
	
	await get_tree().process_frame
	_update_plugins_list()
	_on_options_item_selected(0)

var current_main_screen = null

func update_current_main_screen(s):
	if btn_toggle.button_pressed:
		current_main_screen = s

var plugin_directories := ["resource_bank_editor"]
var plugin_names := ["Resource Bank"]

func _update_plugins_list():
	plugin_directories.clear()
	plugin_names.clear()
	var selected_prior = options.selected
	
	options.clear()
	var dir := DirAccess.open(PLUGIN_FOLDER)
	
	btn_toggle.disabled = true
	
	for pdir in dir.get_directories():
		if not pdir == "plugin_refresher":
			_search_dir_for_plugins(PLUGIN_FOLDER, pdir)
	
	if plugin_directories.size() > 0:
		btn_toggle.disabled = false
		for i in plugin_names:
			options.add_item(i)
		options.select(clamp(selected_prior, 0, plugin_directories.size() - 1))
	else:
		options.add_separator("No Plugins To Refresh.")
		options.selected = -1
		options.add_item("...")

func _search_dir_for_plugins(base : String, dir_name : String):
	var path = base.path_join(dir_name)
	var dir = DirAccess.open(path)
	
	for file in dir.get_files():
		if file == "plugin.cfg":
			var plugincfg = ConfigFile.new()
			plugincfg.load(path.path_join(file))
			
			plugin_directories.push_back(dir_name)
			plugin_names.push_back(plugincfg.get_value("plugin", "name", ""))
			return
	for subdir in dir.get_directories():
		if not subdir == "plugin_refresher":
			_search_dir_for_plugins(path, subdir)

func _on_options_button_down():
	_update_plugins_list()

func _on_btn_toggle_toggled(button_pressed):
	var plugin_name = plugin_directories[options.selected]
	
	var current_main_screen_bkp = current_main_screen
	
	plugin.get_editor_interface().set_plugin_enabled(plugin_name, button_pressed)
	
	if button_pressed:
		if current_main_screen_bkp:
			plugin.get_editor_interface().set_main_screen_editor(current_main_screen_bkp)
	
	print("\"", plugin_names[options.selected], "\" : ", "ON" if button_pressed else "OFF")

func _on_options_item_selected(index):
	var plugin_name = plugin_directories[index]
	btn_toggle.button_pressed = plugin.get_editor_interface().is_plugin_enabled(plugin_name)

func find_visible_child(node : Control):
	for child in node.get_children():
		if child.visible:
			return child
	return null

func get_main_screen()->String:
	var screen:String
	var base:Panel = plugin.get_editor_interface().get_base_control()
	var editor_head:BoxContainer = base.get_child(0).get_child(0)
	if editor_head.get_child_count()<3:
		# may happen when calling from plugin _init()
		return screen
	var main_screen_buttons:Array = editor_head.get_child(2).get_children()
	for button in main_screen_buttons:
		if button.pressed:
			screen = button.text
			break
	return screen
