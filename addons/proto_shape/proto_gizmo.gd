extends EditorNode3DGizmoPlugin

const ProtoRamp = preload("proto_ramp.gd")
var camera_position: Vector3 = Vector3(0, 0, 0)
var depth_handle_id = 0
var width_handle_id = 0

func _has_gizmo(node):
	return node is ProtoRamp

func _init():
	create_material("main", Color(1, 0, 0))
	create_handle_material("handles")

func _redraw(gizmo):
	gizmo.clear()

	var node : ProtoRamp = gizmo.get_node_3d()

	var handles = PackedVector3Array()

	var stair_calculation = node.calculation
	if node.type == ProtoRamp.Type.RAMP:
		stair_calculation = ProtoRamp.Calculation.STAIRCASE_DIMENSIONS

	if (stair_calculation == ProtoRamp.Calculation.STEP_DIMENSIONS):
		handles.push_back(Vector3(0, node.height * node.steps / 2, node.depth * node.steps))
		handles.push_back(Vector3(node.width / 2, node.height * node.steps / 4, node.depth * node.steps / 2))
	else :
		handles.push_back(Vector3(0, node.height / 2, node.depth))
		handles.push_back(Vector3(node.width / 2, node.height / 4, node.depth / 2))

	if depth_handle_id == 0:
		depth_handle_id = randi()
	if width_handle_id == 0:
		width_handle_id = randi()

	gizmo.add_handles(handles, get_material("handles", gizmo), [depth_handle_id, width_handle_id])

	var plane_y = node.height
	var plane_z = node.depth
	if (stair_calculation == ProtoRamp.Calculation.STEP_DIMENSIONS):
		plane_y = node.height * node.steps
		plane_z = node.depth * node.steps
	# var plane = Plane(Vector3(1, 1, 0).rotated(node.quaternion.get_axis(), node.quaternion.get_angle()).normalized(), Vector3(0, 1, 0))
	var gizmo_position = Vector3(0, node.height / 2, node.depth)
	if (stair_calculation == ProtoRamp.Calculation.STEP_DIMENSIONS):
		gizmo_position *= node.steps
	var plane = _get_camera_oriented_plane(camera_position, gizmo_position, Vector3(0, 0, 1), gizmo)

func _set_handle(gizmo, handle_id, secondary, camera, screen_pos):
	print_debug("handle_id = " + str(handle_id))
	match handle_id:
		depth_handle_id:
			_set_depth_handle(gizmo, camera, screen_pos)
		width_handle_id:
			_set_width_handle(gizmo, camera, screen_pos)

	gizmo.get_node_3d().update_gizmos()

func _set_width_handle(gizmo, camera, screen_pos):
	print_debug("_set_width_handle")
	var node : ProtoRamp = gizmo.get_node_3d()
	var gizmo_position = Vector3(node.width / 2, node.height / 4, node.depth / 2)

	var plane = _get_camera_oriented_plane(camera.position, gizmo_position, Vector3(1, 0, 0), gizmo)
	var offset = ((plane.intersects_ray(camera.position, camera.project_position(screen_pos, 1.0) - camera.position) - node.position).rotated(node.quaternion.get_axis(), -node.quaternion.get_angle())).x
	if (node.calculation == ProtoRamp.Calculation.STEP_DIMENSIONS && node.type == ProtoRamp.Type.STAIRCASE):
		offset = offset
	node.width = offset * 2

func _set_depth_handle(gizmo, camera, screen_pos):
	print_debug("_set_depth_handle")
	var node : ProtoRamp = gizmo.get_node_3d()
	var gizmo_position = Vector3(0, node.height / 2, node.depth)
	if (node.calculation == ProtoRamp.Calculation.STEP_DIMENSIONS && node.type == ProtoRamp.Type.STAIRCASE):
		gizmo_position *= node.steps

	var plane = _get_camera_oriented_plane(camera.position, gizmo_position, Vector3(0, 0, 1), gizmo)
	var offset = ((plane.intersects_ray(camera.position, camera.project_position(screen_pos, 1.0) - camera.position) - node.position).rotated(node.quaternion.get_axis(), -node.quaternion.get_angle())).z
	if (node.calculation == ProtoRamp.Calculation.STEP_DIMENSIONS && node.type == ProtoRamp.Type.STAIRCASE):
		offset = offset / node.steps
	node.depth = offset

func _get_camera_oriented_plane(
	camera_position: Vector3,
	gizmo_position: Vector3,
	gizmo_axis: Vector3,
	gizmo: EditorNode3DGizmo) -> Plane:
	# camera: Camera to orient the plane to
	# gizmo_position: gizmo's current position in the world
	# gizmo_axis: axis the gizmo is moving along
	var node = gizmo.get_node_3d()
	# Node's transformation
	var quaternion = node.quaternion # Rotation in degrees for each axis

	# Transform the local point
	var local_gizmo_position = gizmo_position
	var global_gizmo_position = gizmo_position.rotated(quaternion.get_axis(), quaternion.get_angle()) * node.scale + node.position
	var global_gizmo_axis = gizmo_axis.rotated(quaternion.get_axis(), quaternion.get_angle()).normalized()
	# gizmo_axis = node.transform.rotated(gizmo_axis).origin.normalized()
	# gizmo_axis = gizmo_axis.normalized()
	print_debug("global_gizmo_axis = " + str(global_gizmo_axis))
	print_debug("gizmo_position = " + str(global_gizmo_position))
	var closest_point_to_camera = _get_closest_point_on_line(global_gizmo_position, global_gizmo_axis, camera_position)
	var closest_point_to_camera_difference = closest_point_to_camera - camera_position
	var parallel_to_gizmo_dir = closest_point_to_camera - global_gizmo_position
	print_debug("parallel = " + str(parallel_to_gizmo_dir))
	var perpendicular_to_gizmo_dir = parallel_to_gizmo_dir.cross(closest_point_to_camera_difference).normalized()
	print_debug("perpendicular = " + str(perpendicular_to_gizmo_dir))

	# Transform 3 points to global space
	var x = global_gizmo_position
	var y = global_gizmo_position + global_gizmo_axis
	var z = global_gizmo_position + perpendicular_to_gizmo_dir
	var plane = Plane(x, y, z)

	# Drawing
	var lines = PackedVector3Array()
	var debug_gizmo_position = gizmo_position + Vector3(0, 0, 1)

	# Plane normal
	lines.push_back(debug_gizmo_position)
	lines.push_back(debug_gizmo_position + plane.normal)

	# Camera perpendicular
	lines.push_back(debug_gizmo_position)
	lines.push_back(debug_gizmo_position + perpendicular_to_gizmo_dir.normalized())

	# Gizmo axis
	lines.push_back(debug_gizmo_position)
	lines.push_back(debug_gizmo_position + gizmo_axis)
	gizmo.add_lines(lines, get_material("main", gizmo), false)

	return plane

func _get_closest_point_on_line(point_in_line: Vector3, line_dir: Vector3, point: Vector3) -> Vector3:
	var A = point_in_line
	var B = point_in_line + line_dir  # This can be any other point in the direction of the line
	var AP = point - A
	var AB = B - A

	var t = AP.dot(AB) / AB.dot(AB)
	var closest_point = A + t * AB

	return closest_point
