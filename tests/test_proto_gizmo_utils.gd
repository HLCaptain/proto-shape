@tool
extends Node3D

const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")

var failures := 0
var gizmo_utils := ProtoGizmoUtils.new()

func _ready() -> void:
	if "--proto-shape-tests" in OS.get_cmdline_user_args() and scene_file_path in OS.get_cmdline_args():
		_run.call_deferred()

func _run() -> void:
	for index in range(5):
		await get_tree().process_frame
	_check_identity_perspective()
	_check_transformed_parent_and_camera()
	_check_orthographic()
	_check_explicit_plane()
	_check_invalid_geometry()
	if failures == 0:
		print("PASS: gizmo projection")
	get_tree().quit(1 if failures else 0)

func _check_identity_perspective() -> void:
	var node := Node3D.new()
	add_child(node)
	var camera := _make_camera(Vector3(4, 3, 6), Vector3.ZERO)
	_expect_axis_projection(camera, node, Vector3(0.25, 0.5, 0), Vector3.RIGHT, 1.4, "Identity perspective")
	camera.queue_free()
	node.queue_free()

func _check_transformed_parent_and_camera() -> void:
	var parent := Node3D.new()
	parent.transform = Transform3D(Basis.from_euler(Vector3(0.2, 0.65, -0.15)).scaled(Vector3(1.8, 0.7, 1.35)), Vector3(2.5, -0.4, -1.5))
	add_child(parent)
	var node := Node3D.new()
	node.transform = Transform3D(Basis.from_euler(Vector3(-0.25, 0.3, 0.1)), Vector3(0.4, 1.1, -0.6))
	parent.add_child(node)

	var camera_rig := Node3D.new()
	camera_rig.transform = Transform3D(Basis.from_euler(Vector3(0.0, -0.35, 0.0)), Vector3(-2, 1, 3))
	add_child(camera_rig)
	var camera := Camera3D.new()
	camera_rig.add_child(camera)
	camera.position = Vector3(3, 3, 8)
	camera.look_at(node.global_position)
	_expect_axis_projection(camera, node, Vector3(0.3, 0.6, -0.2), Vector3(0, 1, 0.25).normalized(), 1.1, "Transformed parent and parented camera")
	camera_rig.queue_free()
	parent.queue_free()

func _check_orthographic() -> void:
	var node := Node3D.new()
	node.transform = Transform3D(Basis.from_euler(Vector3(0.1, -0.45, 0.2)).scaled(Vector3(0.8, 1.6, 1.2)), Vector3(-1, 0.5, -2))
	add_child(node)
	var camera := _make_camera(Vector3(5, 4, 7), node.global_position)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	_expect_axis_projection(camera, node, Vector3(-0.2, 0.8, 0.3), Vector3.BACK, 1.25, "Orthographic projection")
	camera.queue_free()
	node.queue_free()

func _check_explicit_plane() -> void:
	var node := Node3D.new()
	node.transform = Transform3D(Basis.from_euler(Vector3(0.35, 0.4, -0.2)).scaled(Vector3(1.7, 0.65, 1.25)), Vector3(1, 0.5, -1))
	add_child(node)
	var camera := _make_camera(Vector3(5, 5, 7), node.global_position)
	var local_origin := Vector3(0.2, 0.4, -0.3)
	var local_target := local_origin + Vector3(0.8, 0, -0.55)
	var screen := camera.unproject_position(node.global_transform * local_target)
	var result: Variant = gizmo_utils.get_handle_offset_by_plane(camera, screen, local_origin, Vector3.UP, node)
	_expect(result is Vector3 and result.is_equal_approx(local_target), "Explicit plane uses inverse-transpose normal")
	camera.queue_free()
	node.queue_free()

func _check_invalid_geometry() -> void:
	var node := Node3D.new()
	add_child(node)
	var camera := _make_camera(Vector3(0, 2, 6), Vector3.ZERO)
	_expect(gizmo_utils.get_handle_offset(null, Vector2.ZERO, Vector3.ZERO, Vector3.RIGHT, node) == null, "Missing camera is rejected")
	_expect(gizmo_utils.get_handle_offset(camera, Vector2.ZERO, Vector3.ZERO, Vector3.RIGHT, null) == null, "Missing node is rejected")
	_expect(gizmo_utils.get_handle_offset(camera, Vector2(INF, 0), Vector3.ZERO, Vector3.RIGHT, node) == null, "Non-finite screen position is rejected")
	_expect(gizmo_utils.get_handle_offset(camera, Vector2.ZERO, Vector3(INF, 0, 0), Vector3.RIGHT, node) == null, "Non-finite local position is rejected")
	_expect(gizmo_utils.get_handle_offset(camera, Vector2.ZERO, Vector3.ZERO, Vector3.ZERO, node) == null, "Zero drag axis is rejected")

	var axis_origin := Vector3(0.4, 0.2, 0)
	camera.global_position = axis_origin - Vector3.RIGHT * 5.0
	camera.look_at(axis_origin)
	var end_on_screen := camera.unproject_position(axis_origin)
	_expect(gizmo_utils.get_handle_offset(camera, end_on_screen, axis_origin, Vector3.RIGHT, node) == null, "End-on drag is rejected")

	camera.global_position = Vector3(0, 0, 5)
	camera.look_at(Vector3.ZERO)
	var center_screen := camera.unproject_position(Vector3.ZERO)
	_expect(gizmo_utils.get_handle_offset_by_plane(camera, center_screen, Vector3.ZERO, Vector3.RIGHT, node) == null, "Parallel explicit plane has no intersection")

	node.scale = Vector3(0, 1, 1)
	_expect(gizmo_utils.get_handle_offset(camera, center_screen, Vector3.ZERO, Vector3.UP, node) == null, "Singular transform is rejected")
	camera.queue_free()
	node.queue_free()

func _make_camera(position: Vector3, target: Vector3) -> Camera3D:
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = position
	camera.look_at(target)
	return camera

func _expect_axis_projection(camera: Camera3D, node: Node3D, local_origin: Vector3, local_axis: Vector3, distance: float, label: String) -> void:
	var local_target := local_origin + local_axis * distance
	var screen := camera.unproject_position(node.global_transform * local_target)
	var result: Variant = gizmo_utils.get_handle_offset(camera, screen, local_origin, local_axis, node)
	_expect(result is Vector3 and result.is_equal_approx(local_target), "%s round-trips local target" % label)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
