@tool
extends Node

const ProtoShape = preload("res://addons/proto_shape/proto_shape.gd")

var failures := 0

func _ready() -> void:
	if "--proto-shape-tests" in OS.get_cmdline_user_args() and scene_file_path in OS.get_cmdline_args():
		_run.call_deferred()

func _run() -> void:
	# Let editor startup finish before exercising or shutting down editor objects.
	for index in range(5):
		await get_tree().process_frame
	for action in [&"snap_to_grid", &"fine_snap_to_grid"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.7)
		var event := InputEventKey.new()
		event.keycode = KEY_F9
		InputMap.action_add_event(action, event)
	var original := InputMap.action_get_events(&"snap_to_grid")
	var plugin = ProtoShape.new()
	var signals_received := [0, 0]
	plugin.gizmo_plugin.snapping_changed.connect(func(_enabled): signals_received[0] += 1)
	plugin.gizmo_plugin.fine_snapping_changed.connect(func(_enabled): signals_received[1] += 1)

	_key(plugin, KEY_CTRL, true)
	_expect(plugin.gizmo_plugin.snapping and not plugin.gizmo_plugin.fine_snapping, "Ctrl enables normal snapping")
	_key(plugin, KEY_CTRL, true)
	_expect(signals_received[0] == 1, "Repeated state does not re-emit snapping")
	_key(plugin, KEY_SHIFT, true, true)
	_expect(plugin.gizmo_plugin.snapping and plugin.gizmo_plugin.fine_snapping, "Ctrl+Shift enables fine snapping")
	_key(plugin, KEY_SHIFT, false, true)
	_expect(plugin.gizmo_plugin.snapping and not plugin.gizmo_plugin.fine_snapping, "Shift release restores normal snapping")
	_key(plugin, KEY_CTRL, false)
	_key(plugin, KEY_SHIFT, true)
	_expect(not plugin.gizmo_plugin.snapping and not plugin.gizmo_plugin.fine_snapping, "Shift alone does not snap")
	_key(plugin, KEY_CTRL, true, false, true)
	_expect(plugin.gizmo_plugin.fine_snapping, "Ctrl pressed after Shift enables fine snapping")
	plugin._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_expect(not plugin.gizmo_plugin.snapping and not plugin.gizmo_plugin.fine_snapping, "Focus loss clears modifiers")
	_key(plugin, KEY_CTRL, true)
	plugin._reset_snapping()
	_expect(not plugin.gizmo_plugin.snapping, "Exit reset clears snapping")
	plugin.free()
	var originally_enabled := EditorInterface.is_plugin_enabled("proto_shape")
	EditorInterface.set_plugin_enabled("proto_shape", true)
	for index in range(3):
		await get_tree().process_frame
	_expect(EditorInterface.is_plugin_enabled("proto_shape"), "Installed plugin enables through EditorInterface")
	EditorInterface.set_plugin_enabled("proto_shape", false)
	for index in range(3):
		await get_tree().process_frame
	_expect(not EditorInterface.is_plugin_enabled("proto_shape"), "Installed plugin disables through EditorInterface")
	if originally_enabled:
		EditorInterface.set_plugin_enabled("proto_shape", true)
	_expect(InputMap.action_get_events(&"snap_to_grid") == original, "Host snapping action events are untouched")
	_expect(is_equal_approx(InputMap.action_get_deadzone(&"snap_to_grid"), 0.7), "Host action deadzone is untouched")
	_expect(InputMap.has_action(&"fine_snap_to_grid"), "Host fine-snapping action survives")
	for index in range(3):
		await get_tree().process_frame
	if failures == 0:
		print("PASS: plugin shortcuts")
	get_tree().quit(1 if failures else 0)

func _key(plugin, key: Key, pressed: bool, ctrl := false, shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = pressed
	event.ctrl_pressed = ctrl
	event.shift_pressed = shift
	plugin._shortcut_input(event)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
