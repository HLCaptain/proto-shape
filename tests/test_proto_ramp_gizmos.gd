@tool
extends Node3D

const ProtoRamp = preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")
const ProtoRampGizmos = preload("res://addons/proto_shape/proto_ramp/proto_ramp_gizmos.gd")
const ProtoGizmo = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo.gd")

var failures := 0

func _ready() -> void:
	if "--proto-shape-tests" in OS.get_cmdline_user_args():
		_run.call_deferred()

func _run() -> void:
	for index in range(5):
		await get_tree().process_frame
	var plugin := ProtoGizmo.new()
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
		_check_fill(plugin, gizmos, ramp, camera, fill_handle)

	ramp.gizmos = gizmos
	var original_fill: float = ramp.fill
	var handle: Vector3 = gizmos._get_handle_positions()[gizmos.fill_gizmo_id1]
	plugin._begin_arrow_drag(ramp, gizmos.fill_gizmo_id1, camera, camera.unproject_position(handle))
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

func _check_fill(plugin, gizmos, ramp, camera: Camera3D, fill_handle: int) -> void:
	ramp.fill = 0.4
	var before: Vector3 = gizmos._get_handle_positions()[fill_handle]
	ramp.fill = 0.5
	var toward_more_fill: Vector3 = gizmos._get_handle_positions()[fill_handle] - before
	var arrow_axis: Vector3 = gizmos._get_fill_drag_axis()
	_expect(arrow_axis.dot(toward_more_fill) > 0.0, "Fill arrow must point toward increasing Fill")

	var start_fill := 0.9
	ramp.fill = start_fill
	var handle_position: Vector3 = gizmos._get_handle_positions()[fill_handle]
	var click_position: Vector3 = handle_position + arrow_axis.normalized() * gizmos._get_arrow_visual_length() * 0.5
	var fill_axis := toward_more_fill.normalized()

	camera.look_at(ramp.global_transform * handle_position)

	var click_screen := camera.unproject_position(ramp.global_transform * click_position)
	gizmos.begin_arrow_drag(plugin, fill_handle, camera, click_screen)
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

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
