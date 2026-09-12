extends SceneTree

const ProtoRamp = preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")
const ProtoRampGizmos = preload("res://addons/proto_shape/proto_ramp/proto_ramp_gizmos.gd")

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var ramp = ProtoRamp.new()
	world.add_child(ramp)
	ramp.width = 3.0
	ramp.height = 2.0
	ramp.depth = 3.0

	var gizmos = ProtoRampGizmos.new()
	gizmos.attach_ramp(ramp)
	gizmos.width_gizmo_id = 1
	gizmos.depth_gizmo_id = 2
	gizmos.height_gizmo_id = 3
	gizmos.fill_gizmo_id1 = 4
	gizmos.fill_gizmo_id2 = 5

	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = Vector3(-6.0, 4.0, 7.0)
	for fill_handle in [gizmos.fill_gizmo_id1, gizmos.fill_gizmo_id2]:
		_check_fill(gizmos, ramp, camera, fill_handle)

	gizmos.remove_ramp()
	world.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: ramp fill gizmos")
	quit(1 if failures else 0)

func _check_fill(gizmos, ramp, camera: Camera3D, fill_handle: int) -> void:
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
	gizmos.begin_arrow_drag(null, fill_handle, camera, click_screen)
	gizmos.set_arrow_drag(null, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position + fill_axis * 0.05)))
	var increased_fill: float = ramp.fill
	gizmos.set_arrow_drag(null, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position - fill_axis * 0.05)))
	var decreased_fill: float = ramp.fill
	_expect(increased_fill > start_fill, "A small drag toward increasing Fill must increase it from an arrow-body click")
	_expect(decreased_fill < start_fill, "A small drag toward decreasing Fill must decrease it from an arrow-body click")

	gizmos.set_arrow_drag(null, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position + fill_axis * 10.0)))
	_expect(is_equal_approx(ramp.fill, 1.0), "Fill must clamp at one")
	gizmos.set_arrow_drag(null, fill_handle, camera, camera.unproject_position(ramp.global_transform * (click_position - fill_axis * 10.0)))
	_expect(is_zero_approx(ramp.fill), "Fill must clamp at zero")
	gizmos.commit_arrow_drag(null, fill_handle, true)
	_expect(is_equal_approx(ramp.fill, start_fill), "Cancel must restore the original Fill")

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
