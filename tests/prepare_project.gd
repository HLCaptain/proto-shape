extends SceneTree

func _initialize() -> void:
	if not OS.get_cmdline_user_args().has("--isolated-test-project"):
		push_error("Use this helper only through tests/run.sh in its disposable project copy")
		quit(1)
		return
	var config := ConfigFile.new()
	var error := config.load("res://project.godot")
	if error == OK:
		config.set_value("editor_plugins", "enabled", PackedStringArray())
		error = config.save("res://project.godot")
	if error != OK:
		push_error("Could not prepare the isolated project: %s" % error_string(error))
	else:
		print("PASS: isolated project prepared for first import")
	quit(0 if error == OK else 1)
