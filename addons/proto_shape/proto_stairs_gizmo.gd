extends EditorNode3DGizmoPlugin

const ProtoStairs = preload("proto_stairs.gd")

func _has_gizmo(node):
	return node is ProtoStairs

func _init():
	create_material("main", Color(1, 0, 0))
	create_handle_material("handles")

func _redraw(gizmo):
	gizmo.clear()

	var stairs : ProtoStairs = gizmo.get_node_3d()

	var handles = PackedVector3Array()

	if (stairs.calculation == ProtoStairs.Calculation.STEP_DIMENSIONS):
		handles.push_back(Vector3(0, stairs.height * stairs.steps / 2, stairs.depth * stairs.steps))
	else :
		handles.push_back(Vector3(0, stairs.height / 2, stairs.depth))

	gizmo.add_handles(handles, get_material("handles", gizmo), [])

	var lines = PackedVector3Array()
	var plane_y = stairs.height
	var plane_z = stairs.depth
	if (stairs.calculation == ProtoStairs.Calculation.STEP_DIMENSIONS):
		plane_y = stairs.height * stairs.steps
		plane_z = stairs.depth * stairs.steps
	var plane = Plane(Vector3(1, 0, 0).rotated(stairs.quaternion.get_axis(), stairs.quaternion.get_angle()), Vector3(0, 0, 0))
	lines.push_back(Vector3(0, plane_y / 2, plane_z + 0.1).rotated(stairs.quaternion.get_axis(), stairs.quaternion.get_angle()))
	lines.push_back(Vector3(0, plane_y / 2, plane_z + 0.1).rotated(stairs.quaternion.get_axis(), stairs.quaternion.get_angle()) + plane.normal)
	gizmo.add_lines(lines, get_material("main", gizmo), false)

func _set_handle(gizmo, handle_id, secondary, camera, screen_pos):
	print_debug("_set_handle")
	var stairs : ProtoStairs = gizmo.get_node_3d()
	var plane_z = stairs.depth
	if (stairs.calculation == ProtoStairs.Calculation.STEP_DIMENSIONS):
		plane_z = stairs.depth * stairs.steps
	var plane = Plane(Vector3(1, 0, 0), Vector3(0, 0, 0))
	# Print everything
	# print_debug("camera: " + str(camera.position))
	# print_debug("screen_pos: " + str(screen_pos))
	# print_debug("plane: " + str(plane))
	# print_debug("camera.project_position(screen_pos, 1.0): " + str(camera.position - camera.project_position(screen_pos, 1.0)))
	# print_debug("intersection: " + str(plane.intersects_ray(camera.position, camera.project_position(screen_pos, 1.0) - camera.position)))
	var offset = plane.intersects_ray(camera.position, camera.project_position(screen_pos, 1.0) - camera.position).z
	if (stairs.calculation == ProtoStairs.Calculation.STEP_DIMENSIONS):
		offset = offset / stairs.steps
	stairs.depth = offset

	var gt: Transform3D = gizmo.get_node_3d().transform
	var gi = gt.affine_inverse()

	var ray_from = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)

	# r_segment[0] = gi.xform(ray_from);
	# r_segment[1] = gi.xform(ray_from + ray_dir * 4096);

	gizmo.get_node_3d().update_gizmos()
