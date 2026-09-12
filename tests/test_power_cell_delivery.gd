extends SceneTree

const Demo = preload("res://addons/proto_shape/examples/power_cell_delivery/power_cell_delivery.gd")
const ProtoExampleControls = preload("res://addons/proto_shape/examples/proto_example_controls.gd")
const SCENE_PATH := "res://addons/proto_shape/examples/power_cell_delivery/power_cell_delivery.tscn"

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_seed_existing_interact_action()
	root.size = Vector2i(480, 360)
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
	_test_hud_layout(gameplay)

	gameplay._on_pickup_area_body_entered(gameplay.player)
	_expect(ProtoExampleControls.get_action_label(ProtoExampleControls.INTERACT) == "Q", "Remapped interaction label must use Q")
	_expect(gameplay.hud_label.text.contains("Q: Pick up power cell"), "HUD interaction prompt must use the preserved Q binding")
	_expect(not gameplay.hud_label.text.contains("E / X"), "HUD interaction prompt must not advertise replaced bindings")
	await process_frame
	_test_hud_layout(gameplay)
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

func _test_hud_layout(gameplay: Node3D) -> void:
	var backdrop := gameplay.get_node("Hud/Backdrop") as Control
	var label := gameplay.hud_label as Label
	var viewport_width := gameplay.get_viewport().get_visible_rect().size.x
	var backdrop_rect := backdrop.get_global_rect()
	var label_rect := label.get_global_rect()
	_expect(is_equal_approx(viewport_width, 480.0), "HUD test must use a 480-pixel-wide viewport")
	_expect(backdrop.position.x >= 0.0 and backdrop.position.x + backdrop.size.x <= viewport_width, "HUD backdrop must fit a narrow viewport")
	_expect(backdrop.size.x >= viewport_width * 0.75, "HUD backdrop must use the available viewport width")
	_expect(label_rect.position.x >= backdrop_rect.position.x and label_rect.end.x <= backdrop_rect.end.x, "HUD label must stay inside its backdrop")
	_expect(label.autowrap_mode != TextServer.AUTOWRAP_OFF, "HUD label must wrap at narrow widths")
	_expect(label.get_combined_minimum_size().y <= label.size.y, "HUD label must reserve enough height for wrapped text")
	_expect(label.get_visible_line_count() == label.get_line_count(), "HUD must show every wrapped text line")
	_expect(backdrop_rect.end.y >= label_rect.end.y + 8.0, "HUD backdrop must contain wrapped text with a bottom margin")

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
