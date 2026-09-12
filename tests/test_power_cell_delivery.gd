extends SceneTree

const Demo = preload("res://addons/proto_shape/examples/power_cell_delivery/power_cell_delivery.gd")
const ProtoExampleControls = preload("res://addons/proto_shape/examples/proto_example_controls.gd")
const SCENE_PATH := "res://addons/proto_shape/examples/power_cell_delivery/power_cell_delivery.tscn"

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_seed_existing_interact_action()
	var source := load(SCENE_PATH) as PackedScene
	_expect(source != null, "Demo scene must load")
	if source == null:
		quit(1)
		return

	var gameplay = source.instantiate()
	root.add_child(gameplay)
	await process_frame
	_expect(is_equal_approx(InputMap.action_get_deadzone(ProtoExampleControls.INTERACT), 0.23), "Existing demo actions must not be overwritten")
	_expect(InputMap.action_get_events(ProtoExampleControls.INTERACT).size() == 1, "Existing demo action events must be preserved")
	_test_player_visual_matches_collider(gameplay)

	gameplay._on_pickup_area_body_entered(gameplay.player)
	gameplay.interact()
	await process_frame
	_expect(gameplay.delivery_state == Demo.DeliveryState.CARRIED, "Nearby interaction must pick up the cell")
	_expect(gameplay.power_cell.get_parent() == gameplay.carry_socket, "Carried cell must attach to CarrySocket")
	_expect(not gameplay.pickup_area.monitoring, "Pickup area must stop monitoring after collection")

	gameplay._on_terminal_area_body_entered(gameplay.player)
	gameplay.interact()
	_expect(gameplay.delivery_state == Demo.DeliveryState.DELIVERED, "Terminal interaction must complete delivery")
	_expect(gameplay.power_cell.get_parent() == gameplay.terminal_socket, "Delivered cell must attach to TerminalSocket")
	_expect(gameplay.active_terminal.visible and not gameplay.inactive_terminal.visible, "Terminal visuals must show completion")
	gameplay.queue_free()
	await process_frame

	var editable = source.instantiate()
	root.add_child(editable)
	await process_frame
	var cargo_ramp := editable.get_node("MapGeometry/TwinRise/CargoRamp")
	cargo_ramp.width = 4.25
	cargo_ramp.name = "EditedCargoRamp"
	editable.get_node("MapGeometry/RelayYard/TerminalGuideWall").free()
	var marker := Node3D.new()
	marker.name = "UserMarker"
	editable.get_node("MapGeometry").add_child(marker)
	marker.owner = editable
	var saved := PackedScene.new()
	_expect(saved.pack(editable) == OK, "Edited demo must pack")
	_expect(ResourceSaver.save(saved, "user://edited_power_cell_delivery.tscn") == OK, "Edited demo must save")
	editable.queue_free()
	await process_frame

	var reloaded_source := load("user://edited_power_cell_delivery.tscn") as PackedScene
	var reloaded = reloaded_source.instantiate()
	root.add_child(reloaded)
	await process_frame
	_expect(is_equal_approx(reloaded.get_node("MapGeometry/TwinRise/EditedCargoRamp").width, 4.25), "Saved ramp edits must persist")
	_expect(reloaded.has_node("MapGeometry/UserMarker"), "User-added nodes must persist")
	_expect(not reloaded.has_node("MapGeometry/RelayYard/TerminalGuideWall"), "User-deleted nodes must stay deleted")
	reloaded.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: delivery state and editing")
	quit(1 if failures else 0)

func _test_player_visual_matches_collider(gameplay: Node3D) -> void:
	var visual := gameplay.get_node("Player/Body") as MeshInstance3D
	var collision := gameplay.get_node("Player/CollisionShape3D") as CollisionShape3D
	var visual_shape := visual.mesh as CapsuleMesh
	var collision_shape := collision.shape as CapsuleShape3D
	_expect(visual_shape != null, "Player visual must use a CapsuleMesh")
	_expect(collision_shape != null, "Player collision must use a CapsuleShape3D")
	if visual_shape == null or collision_shape == null:
		return
	_expect(is_equal_approx(visual_shape.radius, collision_shape.radius), "Player visual radius must match its collider")
	_expect(is_equal_approx(visual_shape.height, collision_shape.height), "Player visual height must match its collider")
	var vertices: PackedVector3Array = visual_shape.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var visual_bottom := INF
	for vertex: Vector3 in vertices:
		visual_bottom = minf(visual_bottom, (visual.transform * vertex).y)
	var collider_bottom := (collision.transform * Vector3(0.0, -collision_shape.height * 0.5, 0.0)).y
	_expect(is_equal_approx(visual_bottom, collider_bottom), "Player visual and collider feet must align")

func _seed_existing_interact_action() -> void:
	if not InputMap.has_action(ProtoExampleControls.INTERACT):
		InputMap.add_action(ProtoExampleControls.INTERACT)
	InputMap.action_set_deadzone(ProtoExampleControls.INTERACT, 0.23)
	InputMap.action_erase_events(ProtoExampleControls.INTERACT)
	var event := InputEventKey.new()
	event.keycode = KEY_Q
	InputMap.action_add_event(ProtoExampleControls.INTERACT, event)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
