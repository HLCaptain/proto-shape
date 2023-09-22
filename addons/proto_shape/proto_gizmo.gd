extends EditorNode3DGizmoPlugin

const ProtoStairs = preload("proto_stairs.gd")
var camera_position: Vector3 = Vector3(0, 0, 0)

func _has_gizmo(node):
	return node is ProtoStairs

func _init():
	create_material("main", Color(1, 0, 0))
	create_handle_material("handles")

func _redraw(gizmo):
	gizmo.clear()

	var node : ProtoStairs = gizmo.get_node_3d()

	var handles = PackedVector3Array()

	if (node.calculation == ProtoStairs.Calculation.STEP_DIMENSIONS):
		handles.push_back(Vector3(0, node.height * node.steps / 2, node.depth * node.steps))
	else :
		handles.push_back(Vector3(0, node.height / 2, node.depth))

	gizmo.add_handles(handles, get_material("handles", gizmo), [])

	var plane_y = node.height
	var plane_z = node.depth
	if (node.calculation == ProtoStairs.Calculation.STEP_DIMENSIONS):
		plane_y = node.height * node.steps
		plane_z = node.depth * node.steps
	# var plane = Plane(Vector3(1, 1, 0).rotated(node.quaternion.get_axis(), node.quaternion.get_angle()).normalized(), Vector3(0, 1, 0))
	var gizmo_position = Vector3(0, node.height / 2, node.depth)
	if (node.calculation == ProtoStairs.Calculation.STEP_DIMENSIONS):
		gizmo_position *= node.steps
	var plane = _get_camera_oriented_plane(camera_position, gizmo_position, Vector3(0, 0, 1), gizmo)


func _set_handle(gizmo, handle_id, secondary, camera, screen_pos):
	print_debug("_set_handle")
	camera_position = camera.position
	var node : ProtoStairs = gizmo.get_node_3d()
	var gizmo_position = Vector3(0, node.height / 2, node.depth)
	if (node.calculation == ProtoStairs.Calculation.STEP_DIMENSIONS):
		gizmo_position *= node.steps

	var plane = _get_camera_oriented_plane(camera_position, gizmo_position, Vector3(0, 0, 1), gizmo)
	var offset = (plane.intersects_ray(camera_position, camera.project_position(screen_pos, 1.0) - camera_position).rotated(node.quaternion.get_axis(), -node.quaternion.get_angle()) - node.position).z
	if (node.calculation == ProtoStairs.Calculation.STEP_DIMENSIONS):
		offset = offset / node.steps
	node.depth = offset

	gizmo.get_node_3d().update_gizmos()

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
	var global_gizmo_position = gizmo_position.rotated(quaternion.get_axis(), quaternion.get_angle()) + node.position
	# gizmo_axis = gizmo_axis.rotated(quaternion.get_axis(), quaternion.get_angle()).normalized()
	# gizmo_axis = node.transform.rotated(gizmo_axis).origin.normalized()
	# gizmo_axis = gizmo_axis.normalized()
	print_debug("gizmo_axis = " + str(gizmo_axis))
	print_debug("gizmo_position = " + str(global_gizmo_position))
	var closest_point_to_camera = _get_closest_point_on_line(global_gizmo_position, gizmo_axis, camera_position)
	var closest_point_to_camera_difference = closest_point_to_camera - camera_position
	var parallel_to_gizmo_dir = closest_point_to_camera - global_gizmo_position
	print_debug("parallel = " + str(parallel_to_gizmo_dir))
	var perpendicular_to_gizmo_dir = parallel_to_gizmo_dir.cross(closest_point_to_camera_difference).normalized()
	print_debug("perpendicular = " + str(perpendicular_to_gizmo_dir))

	# Transform 3 points to global space
	var x = global_gizmo_position
	var y = global_gizmo_position + gizmo_axis
	var z = global_gizmo_position + perpendicular_to_gizmo_dir
	# x = x.rotated(quaternion.get_axis(), quaternion.get_angle()) + node.position
	# y = y.rotated(quaternion.get_axis(), quaternion.get_angle()) + node.position
	# z = z.rotated(quaternion.get_axis(), quaternion.get_angle()) + node.position
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
