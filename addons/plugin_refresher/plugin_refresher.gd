@tool
extends EditorPlugin

var refresh_button : Control

func _enter_tree():
	refresh_button = preload("res://addons/plugin_refresher/refresh_button.tscn").instantiate()
	refresh_button.plugin = self
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, refresh_button)

func _exit_tree():
	if refresh_button:
		refresh_button.queue_free()
