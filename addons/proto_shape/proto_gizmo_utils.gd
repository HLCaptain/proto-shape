## Calculates plane based on the gizmo's position facing the camera
## Returns offset based on the intersection of the ray from the camera to the cursor hitting the plane
func get_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2,
	local_gizmo_position: Vector3,
	local_offset_axis: Vector3,
	node: Node3D) -> Vector3:

	var transform := node.global_transform
	var position: Vector3 = node.global_position
	var quat: Quaternion = transform.basis.get_rotation_quaternion()
	var quat_axis: Vector3 = quat.get_axis() if quat.get_axis().is_normalized() else Vector3.UP
	var quat_angle: float = quat.get_angle()
	var scale: Vector3 = transform.basis.get_scale()
	var global_gizmo_position: Vector3 = local_gizmo_position.rotated(quat_axis, quat_angle) * scale + position
	var global_offset_axis: Vector3 = local_offset_axis.rotated(quat_axis, quat_angle)
	var plane: Plane = get_camera_oriented_plane(camera.position, global_gizmo_position, global_offset_axis)
	var offset: Vector3 = (plane.intersects_ray(camera.position, camera.project_position(screen_pos, 1.0) - camera.position) - position).rotated(quat_axis, -quat_angle) / scale
	return offset

func debug_draw_handle_offset(
	camera_position: Vector3,
	camera_projection_position: Vector3,
	screen_pos: Vector2,
	local_gizmo_position: Vector3,
	local_offset_axis: Vector3,
	node: Node3D,
	gizmo: EditorNode3DGizmo,
	plugin: EditorNode3DGizmoPlugin) -> void:

	var transform := node.global_transform
	var position: Vector3 = node.global_position
	var quat: Quaternion = transform.basis.get_rotation_quaternion()
	var quat_axis: Vector3 = quat.get_axis() if quat.get_axis().is_normalized() else Vector3.UP
	var quat_angle: float = quat.get_angle()
	var scale: Vector3 = transform.basis.get_scale()
	var global_gizmo_position: Vector3 = local_gizmo_position.rotated(quat_axis, quat_angle) * scale + position
	var global_offset_axis: Vector3 = local_offset_axis.rotated(quat_axis, quat_angle)
	var plane: Plane = get_camera_oriented_plane(camera_position, global_gizmo_position, global_offset_axis)
	var offset: Vector3 = (plane.intersects_ray(camera_position, camera_projection_position - camera_position) - position).rotated(quat_axis, -quat_angle) / scale

	# Add debug lines
	var handles = PackedVector3Array()
	handles.push_back(local_gizmo_position)
	handles.push_back(plane.normal - plane.get_center())
	handles.push_back(offset)

	# Push back gizmo positions like a grid on the plane
	# FIXME: there is a small offset in the corners of the grid
	var grid_size: int = 11
	for i in range(grid_size):
		var x: Vector3 = local_gizmo_position + local_offset_axis.normalized() * (i - grid_size / 2)
		for j in range(grid_size):
			var y: Vector3 = x + plane.normal.cross(local_offset_axis) * (j - grid_size / 2)
			handles.push_back(y)

	gizmo.add_lines(handles, plugin.get_material("handles", gizmo))


## Gets the plane along [param global_gizmo_position] going through [param global_gizmo_axis] and facing towards the [param camera_position]
func get_camera_oriented_plane(
	camera_position: Vector3,
	global_gizmo_position: Vector3,
	global_gizmo_axis: Vector3) -> Plane:
	# camera: Camera to orient the plane to
	# gizmo_position: gizmo's current position in the world
	# gizmo_axis: axis the gizmo is moving along

	var closest_point_to_camera: Vector3 = get_closest_point_on_line(global_gizmo_position, global_gizmo_axis, camera_position)
	var closest_point_to_camera_difference: Vector3 = closest_point_to_camera - camera_position
	var parallel_to_gizmo_dir: Vector3 = closest_point_to_camera - global_gizmo_position
	var perpendicular_to_gizmo_dir: Vector3 = parallel_to_gizmo_dir.cross(closest_point_to_camera_difference).normalized()

	# Transform 3 points to global space
	var x: Vector3 = global_gizmo_position
	var y: Vector3 = global_gizmo_position + global_gizmo_axis
	var z: Vector3 = global_gizmo_position + perpendicular_to_gizmo_dir
	var plane := Plane(x, y, z)

	return plane

## [param point_in_line] is a point on the line
## [param line_dir] is the direction of the line
## [param point] is the point to find the closest point on the line to
func get_closest_point_on_line(
	point_in_line: Vector3,
	line_dir: Vector3,
	point: Vector3) -> Vector3:
	var A := point_in_line
	var B := point_in_line + line_dir  # This can be any other point in the direction of the line
	var AP := point - A
	var AB := B - A

	var t := AP.dot(AB) / AB.dot(AB)
	var closest_point := A + t * AB

	return closest_point