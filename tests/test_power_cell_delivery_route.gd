extends SceneTree

const SCENE = preload("res://addons/proto_shape/examples/power_cell_delivery/power_cell_delivery.tscn")
const Controls = preload("res://addons/proto_shape/examples/proto_example_controls.gd")
var demo: Node3D
var failed := false
var move_action := Controls.MOVE_FORWARD

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	demo = SCENE.instantiate()
	root.add_child(demo)
	current_scene = demo
	for index in range(5):
		await physics_frame
	for target in [Vector2(-2.2, 6.3), Vector2(-2.2, -0.4), Vector2(-2.2, -7.4), Vector2(0.0, -7.4)]:
		await _walk_to(target)
		if failed:
			_finish()
			return
	for index in range(3):
		await physics_frame
	print("At cell: ", demo.player.global_position, " pickup in range: ", demo.cell_nearby)
	await _interact()
	if demo.delivery_state != demo.DeliveryState.CARRIED:
		failed = true
		push_error("Walkable ascent must reach the real pickup trigger")
	for target in [Vector2(5.5, -7.4), Vector2(5.5, -5.8), Vector2(5.5, 0.8), Vector2(7.4, 4.0), Vector2(7.4, 10.6), Vector2(5.4, 10.6)]:
		await _walk_to(target)
		if failed:
			_finish()
			return
	for index in range(3):
		await physics_frame
	print("At terminal: ", demo.player.global_position, " terminal in range: ", demo.terminal_nearby)
	await _interact()
	if demo.delivery_state != demo.DeliveryState.DELIVERED:
		failed = true
		push_error("Walkable return must reach the real terminal trigger")
	demo.player.global_position = Vector3(7.7, 0.6, -5.0)
	demo.player.velocity = Vector3.ZERO
	for index in range(5):
		await physics_frame
	await _walk_to(Vector2(2.5, -5.0))
	print("Underpass: ", demo.player.global_position)
	var original_instance := demo.get_instance_id()
	_send_action(Controls.RESTART, true)
	for index in range(5):
		await physics_frame
	_send_action(Controls.RESTART, false)
	demo = current_scene
	if demo == null or demo.get_instance_id() == original_instance or demo.delivery_state != demo.DeliveryState.AT_SOURCE:
		failed = true
		push_error("Restart action must load a fresh objective")
	else:
		original_instance = demo.get_instance_id()
		demo.player.global_position.y = -6.0
		for index in range(5):
			await physics_frame
		demo = current_scene
		if demo == null or demo.get_instance_id() == original_instance or demo.delivery_state != demo.DeliveryState.AT_SOURCE:
			failed = true
			push_error("Falling must reset the scene and objective")
	_finish()

func _interact() -> void:
	_send_action(Controls.INTERACT, true)
	await process_frame
	_send_action(Controls.INTERACT, false)
	await process_frame

func _send_action(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)

func _walk_to(target: Vector2) -> void:
	for frame in range(600):
		var position: Vector3 = demo.player.global_position
		var offset := target - Vector2(position.x, position.z)
		if offset.length() < 0.15:
			Input.action_release(move_action)
			return
		demo.player.rotation.y = atan2(-offset.x, -offset.y)
		Input.action_press(move_action)
		await physics_frame
	Input.action_release(move_action)
	failed = true
	push_error("Route blocked before %s at %s" % [target, demo.player.global_position])

func _finish() -> void:
	Input.action_release(move_action)
	if is_instance_valid(demo):
		demo.queue_free()
	await process_frame
	if not failed:
		print("PASS: physical delivery route without jumping")
	quit(1 if failed else 0)
