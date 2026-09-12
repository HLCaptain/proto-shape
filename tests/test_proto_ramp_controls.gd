extends SceneTree

const ProtoExampleControls = preload("res://addons/proto_shape/examples/proto_example_controls.gd")
const ProtoRampExampleCharacter = preload("res://addons/proto_shape/proto_ramp/example/proto_ramp_example_character.gd")

const ACTIONS := [
	ProtoExampleControls.MOVE_LEFT,
	ProtoExampleControls.MOVE_RIGHT,
	ProtoExampleControls.MOVE_FORWARD,
	ProtoExampleControls.MOVE_BACK,
	ProtoExampleControls.JUMP,
	ProtoExampleControls.INTERACT,
	ProtoExampleControls.RESTART,
	ProtoExampleControls.RELEASE_CURSOR,
]

var failures := 0
var world: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	_test_project_actions()
	_test_missing_only_fallback()
	await _test_character_input_routing()
	world.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: ramp example controls")
	quit(1 if failures else 0)

func _test_project_actions() -> void:
	for action in ACTIONS:
		_expect(InputMap.has_action(action), "Project Input Map must expose %s" % action)
		_expect_float(InputMap.action_get_deadzone(action), 0.2, "%s must match the runtime fallback deadzone" % action)

	_expect(_has_key(ProtoExampleControls.MOVE_LEFT, KEY_A, true), "Move left must include physical A")
	_expect(_has_key(ProtoExampleControls.MOVE_LEFT, KEY_LEFT), "Move left must include Left Arrow")
	_expect(_has_axis(ProtoExampleControls.MOVE_LEFT, JOY_AXIS_LEFT_X, -1.0), "Move left must include analog stick left")
	_expect(_has_key(ProtoExampleControls.MOVE_RIGHT, KEY_D, true), "Move right must include physical D")
	_expect(_has_key(ProtoExampleControls.MOVE_FORWARD, KEY_W, true), "Move forward must include physical W")
	_expect(_has_key(ProtoExampleControls.MOVE_BACK, KEY_S, true), "Move back must include physical S")
	_expect(_has_key(ProtoExampleControls.JUMP, KEY_SPACE), "Jump must include Space")
	_expect(_has_button(ProtoExampleControls.JUMP, JOY_BUTTON_A), "Jump must include gamepad A")
	_expect(_has_key(ProtoExampleControls.INTERACT, KEY_E), "Interact must include E")
	_expect(_has_key(ProtoExampleControls.RESTART, KEY_R), "Restart must include R")
	_expect(_has_key(ProtoExampleControls.RELEASE_CURSOR, KEY_ESCAPE), "Release cursor must include Escape")
	_expect(_has_button(ProtoExampleControls.RELEASE_CURSOR, JOY_BUTTON_BACK), "Release cursor must include gamepad Back")

func _test_missing_only_fallback() -> void:
	InputMap.erase_action(ProtoExampleControls.INTERACT)
	InputMap.add_action(ProtoExampleControls.INTERACT, 0.73)
	var custom_event := InputEventKey.new()
	custom_event.keycode = KEY_Q
	InputMap.action_add_event(ProtoExampleControls.INTERACT, custom_event)
	InputMap.erase_action(ProtoExampleControls.RESTART)

	ProtoExampleControls.ensure_actions()
	var custom_events := InputMap.action_get_events(ProtoExampleControls.INTERACT)
	_expect_float(InputMap.action_get_deadzone(ProtoExampleControls.INTERACT), 0.73, "Existing custom deadzone must survive fallback setup")
	_expect(custom_events.size() == 1 and custom_events[0] is InputEventKey and custom_events[0].keycode == KEY_Q, "Existing custom events must survive fallback setup")
	_expect(_has_key(ProtoExampleControls.RESTART, KEY_R), "Missing Restart action must receive its default key")
	_expect(_has_button(ProtoExampleControls.RESTART, JOY_BUTTON_START), "Missing Restart action must receive its default gamepad button")

func _test_character_input_routing() -> void:
	var player = ProtoRampExampleCharacter.new()
	var camera_pivot := Node3D.new()
	camera_pivot.name = "CameraPivot"
	player.add_child(camera_pivot)
	var camera_arm := SpringArm3D.new()
	camera_arm.name = "SpringArm3D"
	camera_pivot.add_child(camera_arm)
	world.add_child(player)
	await process_frame

	Input.action_press(ProtoExampleControls.MOVE_RIGHT, 0.6)
	var expected_input := Input.get_vector(
		ProtoExampleControls.MOVE_LEFT,
		ProtoExampleControls.MOVE_RIGHT,
		ProtoExampleControls.MOVE_FORWARD,
		ProtoExampleControls.MOVE_BACK
	).limit_length(1.0)
	_expect(expected_input.length() > 0.0 and expected_input.length() < 1.0, "Synthetic movement must retain a partial analog magnitude")
	player._physics_process(0.0)
	var horizontal_velocity := Vector2(player.velocity.x, player.velocity.z)
	_expect_float(horizontal_velocity.length(), expected_input.length() * ProtoRampExampleCharacter.SPEED, "Character speed must preserve analog magnitude")
	_expect(player.velocity.x > 0.0, "Namespaced Move Right must drive character movement")
	Input.action_release(ProtoExampleControls.MOVE_RIGHT)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var release_event := InputEventAction.new()
	release_event.action = ProtoExampleControls.RELEASE_CURSOR
	release_event.pressed = true
	player._unhandled_input(release_event)
	_expect(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "Namespaced Release Cursor must restore the cursor")
	player.queue_free()

func _has_key(action: StringName, key: Key, physical := false) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			if physical and event.physical_keycode == key:
				return true
			if not physical and event.keycode == key:
				return true
	return false

func _has_button(action: StringName, button: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return true
	return false

func _has_axis(action: StringName, axis: JoyAxis, value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, value):
			return true
	return false

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _expect_float(actual: float, expected: float, message: String) -> void:
	_expect(is_equal_approx(actual, expected), "%s: expected %s, got %s" % [message, expected, actual])
