@tool
extends Node3D

const ProtoRamp = preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")
const ProtoRampGizmos = preload("res://addons/proto_shape/proto_ramp/proto_ramp_gizmos.gd")
const ProtoGizmo = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo.gd")
const ProtoGizmoWrapper = preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")
const ExampleWrappedVolume = preload("res://addons/proto_shape/proto_gizmo/examples/wrapper_volume/example_wrapped_volume.gd")

var failures := 0

func _ready() -> void:
	if "--proto-shape-tests" in OS.get_cmdline_user_args():
		_run.call_deferred()

func _run() -> void:
	for index in range(5):
		await get_tree().process_frame
	var plugin := ProtoGizmo.new()
	plugin.undo_redo = EditorInterface.get_editor_undo_redo()
	var baseline_refs := plugin.get_reference_count()
	var world := Node3D.new()
	add_child(world)

	var ramp = ProtoRamp.new()
	world.add_child(ramp)
	ramp.width = 3.0
	ramp.height = 2.0
	ramp.depth = 3.0

	var gizmos = ProtoRampGizmos.new()
	gizmos.attach_ramp(ramp)
	_expect(PackedInt32Array(gizmos._get_handle_ids()) == PackedInt32Array([1, 2, 3, 4, 5]), "Handle IDs remain small and stable")

	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = Vector3(-6.0, 4.0, 7.0)
	for fill_handle in [gizmos.fill_gizmo_id1, gizmos.fill_gizmo_id2]:
		for arrow_fraction in [0.25, 0.5, 0.75]:
			_check_fill(plugin, gizmos, ramp, camera, fill_handle, arrow_fraction)
	_check_valid_invalid_valid(plugin, gizmos, ramp, camera)

	ramp.gizmos = gizmos
	_check_failed_begin_has_no_undo(plugin, gizmos, ramp, camera)
	var original_fill: float = ramp.fill
	var handle: Vector3 = gizmos._get_handle_positions()[gizmos.fill_gizmo_id1]
	_expect(plugin._begin_arrow_drag(ramp, gizmos.fill_gizmo_id1, camera, camera.unproject_position(handle)), "Valid projection starts generic drag")
	plugin._set_arrow_drag(camera, camera.unproject_position(handle - gizmos._get_fill_drag_axis() * 0.1))
	_expect(not is_equal_approx(ramp.fill, original_fill), "Active drag changes fill before shutdown")
	plugin.shutdown()
	_expect(is_equal_approx(ramp.fill, original_fill), "Plugin shutdown cancels the active drag")
	_expect(plugin.drag_node == null, "Plugin shutdown clears drag ownership")
	var second = ProtoRamp.new()
	world.add_child(second)
	second.position = Vector3(4.0, 0.0, 0.0)
	second.fill = 0.5
	var second_handle: Vector3 = second.gizmos._get_handle_positions()[second.gizmos.fill_gizmo_id1]
	plugin._begin_arrow_drag(second, gizmos.fill_gizmo_id1, camera, camera.unproject_position(second.global_transform * second_handle))
	plugin._set_arrow_drag(camera, camera.unproject_position(second.global_transform * (second_handle + second.gizmos._get_fill_drag_axis() * 0.05)))
	_expect(not is_equal_approx(second.fill, 0.5) and is_equal_approx(ramp.fill, original_fill), "Matching IDs on separate ramps do not cross-dispatch")
	plugin.shutdown()
	_check_orthographic_transformed(plugin, world)
	_check_wrapper_begin_dispatch(plugin, world, camera)
	gizmos.remove_ramp()
	for index in range(3):
		var provider := ProtoRampGizmos.new()
		provider.attach_ramp(ramp)
		provider.get_arrow_drag_segments(plugin)
		provider.remove_ramp()
		_expect(plugin.get_reference_count() == baseline_refs, "Removed provider must not retain its plugin")
	world.queue_free()
	await get_tree().process_frame
	if failures == 0:
		print("PASS: ramp fill gizmos")
	get_tree().quit(1 if failures else 0)

func _check_fill(plugin, gizmos, ramp, camera: Camera3D, fill_handle: int, arrow_fraction: float) -> void:
	ramp.fill = 0.4
	var before: Vector3 = gizmos._get_handle_positions()[fill_handle]
	ramp.fill = 0.5
	var toward_more_fill: Vector3 = gizmos._get_handle_positions()[fill_handle] - before
	var arrow_axis: Vector3 = gizmos._get_fill_drag_axis()
	_expect(arrow_axis.dot(toward_more_fill) > 0.0, "Fill arrow must point toward increasing Fill")

	var start_fill := 0.9
	ramp.fill = start_fill
	var handle_position: Vector3 = gizmos._get_handle_positions()[fill_handle]
	var click_position: Vector3 = handle_position + arrow_axis.normalized() * gizmos._get_arrow_visual_length() * arrow_fraction
	var fill_axis := toward_more_fill.normalized()

	camera.look_at(ramp.global_transform * handle_position)

	var click_screen := camera.unproject_position(ramp.global_transform * click_position)
	_expect(gizmos.begin_arrow_drag(plugin, fill_handle, camera, click_screen), "Arrow-body projection starts at %d%%" % roundi(arrow_fraction * 100.0))
	gizmos.set_arrow_drag(plugin, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position + fill_axis * 0.05)))
	var increased_fill: float = ramp.fill
	gizmos.set_arrow_drag(plugin, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position - fill_axis * 0.05)))
	var decreased_fill: float = ramp.fill
	_expect(increased_fill > start_fill, "A small drag toward increasing Fill must increase it from an arrow-body click")
	_expect(decreased_fill < start_fill, "A small drag toward decreasing Fill must decrease it from an arrow-body click")

	gizmos.set_arrow_drag(plugin, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position + fill_axis * 10.0)))
	_expect(is_equal_approx(ramp.fill, 1.0), "Fill must clamp at one")
	gizmos.set_arrow_drag(plugin, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position - fill_axis * 10.0)))
	_expect(is_zero_approx(ramp.fill), "Fill must clamp at zero")
	gizmos.commit_arrow_drag(plugin, fill_handle, true)
	_expect(is_equal_approx(ramp.fill, start_fill), "Cancel must restore the original Fill")

func _check_valid_invalid_valid(plugin, gizmos, ramp, camera: Camera3D) -> void:
	ramp.fill = 0.5
	var fill_handle: int = gizmos.fill_gizmo_id1
	var handle_position: Vector3 = gizmos._get_handle_positions()[fill_handle]
	var arrow_axis: Vector3 = gizmos._get_fill_drag_axis().normalized()
	camera.look_at(ramp.global_transform * handle_position)
	var click_position: Vector3 = handle_position + arrow_axis * gizmos._get_arrow_visual_length() * 0.5
	_expect(gizmos.begin_arrow_drag(plugin, fill_handle, camera, camera.unproject_position(ramp.global_transform * click_position)), "Valid-invalid-valid drag begins")
	gizmos.set_arrow_drag(plugin, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position + arrow_axis * 0.05)))
	var last_valid_fill: float = ramp.fill
	var last_valid_end: float = gizmos.end_offset
	var original_pointer: float = gizmos.drag_start_pointer_offset
	gizmos.set_arrow_drag(plugin, fill_handle, camera, Vector2(INF, 0))
	_expect(is_equal_approx(ramp.fill, last_valid_fill) and is_equal_approx(gizmos.end_offset, last_valid_end), "Invalid mid-drag projection preserves last valid state")
	_expect(is_equal_approx(gizmos.drag_start_pointer_offset, original_pointer), "Invalid projection preserves original pointer offset")
	gizmos.set_arrow_drag(plugin, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position + arrow_axis * 0.1)))
	_expect(not is_equal_approx(ramp.fill, last_valid_fill), "Drag resumes after a valid projection")
	gizmos.commit_arrow_drag(plugin, fill_handle, true)

func _check_failed_begin_has_no_undo(plugin, gizmos, ramp, camera: Camera3D) -> void:
	var history_id: int = plugin.undo_redo.get_object_history_id(ramp)
	var history: UndoRedo = plugin.undo_redo.get_history_undo_redo(history_id)
	var version_before: int = history.get_version()
	var fill_before: float = ramp.fill
	_expect(not plugin._begin_arrow_drag(ramp, gizmos.fill_gizmo_id1, camera, Vector2(INF, 0)), "Invalid projection rejects generic drag ownership")
	_expect(plugin.drag_node == null and not gizmos.is_editing, "Failed begin captures no drag state")
	plugin._commit_arrow_drag(false)
	_expect(history.get_version() == version_before and is_equal_approx(ramp.fill, fill_before), "Failed begin creates no undo action")

func _check_orthographic_transformed(plugin, world: Node3D) -> void:
	var parent := Node3D.new()
	parent.transform = Transform3D(Basis.from_euler(Vector3(0.15, 0.6, -0.1)).scaled(Vector3(1.6, 0.75, 1.25)), Vector3(1.5, 0.4, -2.0))
	world.add_child(parent)
	var ramp = ProtoRamp.new()
	parent.add_child(ramp)
	ramp.width = 3.0
	ramp.height = 2.0
	ramp.depth = 3.0
	var gizmos = ProtoRampGizmos.new()
	gizmos.attach_ramp(ramp)
	var camera_parent := Node3D.new()
	camera_parent.rotation.y = -0.35
	world.add_child(camera_parent)
	var camera := Camera3D.new()
	camera_parent.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.global_position = Vector3(-7, 6, 9)
	var handle: Vector3 = gizmos._get_handle_positions()[gizmos.fill_gizmo_id1]
	camera.look_at(ramp.global_transform * handle)
	_check_fill(plugin, gizmos, ramp, camera, gizmos.fill_gizmo_id1, 0.5)
	camera_parent.queue_free()
	parent.queue_free()

func _check_wrapper_begin_dispatch(plugin, world: Node3D, camera: Camera3D) -> void:
	var wrapper := ProtoGizmoWrapper.new()
	world.add_child(wrapper)
	var volume := ExampleWrappedVolume.new()
	wrapper.add_child(volume)
	var handle := volume._get_radius_handle_position()
	camera.look_at(volume.global_transform * handle)
	_expect(not plugin._begin_arrow_drag(volume, volume.HANDLE_RADIUS, camera, Vector2(INF, 0)), "Wrapper rejects an invalid initial projection")
	_expect(plugin._begin_arrow_drag(volume, volume.HANDLE_RADIUS, camera, camera.unproject_position(volume.global_transform * handle)), "Wrapper captures only a successful begin")
	plugin.shutdown()
	wrapper.queue_free()

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
