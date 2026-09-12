extends RefCounted

const MOVE_LEFT := &"proto_shape_demo_move_left"
const MOVE_RIGHT := &"proto_shape_demo_move_right"
const MOVE_FORWARD := &"proto_shape_demo_move_forward"
const MOVE_BACK := &"proto_shape_demo_move_back"
const JUMP := &"proto_shape_demo_jump"
const INTERACT := &"proto_shape_demo_interact"
const RESTART := &"proto_shape_demo_restart"
const RELEASE_CURSOR := &"proto_shape_demo_release_cursor"

static func ensure_actions() -> void:
	_ensure_action(MOVE_LEFT, [_key(KEY_A, true), _key(KEY_LEFT), _button(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_ensure_action(MOVE_RIGHT, [_key(KEY_D, true), _key(KEY_RIGHT), _button(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_ensure_action(MOVE_FORWARD, [_key(KEY_W, true), _key(KEY_UP), _button(JOY_BUTTON_DPAD_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_ensure_action(MOVE_BACK, [_key(KEY_S, true), _key(KEY_DOWN), _button(JOY_BUTTON_DPAD_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_ensure_action(JUMP, [_key(KEY_SPACE), _button(JOY_BUTTON_A)])
	_ensure_action(INTERACT, [_key(KEY_E), _button(JOY_BUTTON_X)])
	_ensure_action(RESTART, [_key(KEY_R), _button(JOY_BUTTON_START)])
	_ensure_action(RELEASE_CURSOR, [_key(KEY_ESCAPE), _button(JOY_BUTTON_BACK)])

static func _ensure_action(action: StringName, events: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)

static func _key(code: int, physical := false) -> InputEventKey:
	var event := InputEventKey.new()
	if physical:
		event.physical_keycode = code
	else:
		event.keycode = code
	return event

static func _button(index: int) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	return event

static func _axis(index: int, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = index
	event.axis_value = value
	return event
