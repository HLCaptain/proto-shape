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
	var global_plane: Plane = get_camera_oriented_plane(camera.position, global_gizmo_position, global_offset_axis)
	var local_offset: Vector3 = (global_plane.intersects_ray(camera.position, camera.project_position(screen_pos, 1.0) - camera.position) - position).rotated(quat_axis, -quat_angle) / scale
	return local_offset

func get_handle_offset_by_plane(
	camera: Camera3D,
	screen_pos: Vector2,
	local_gizmo_position: Vector3,
	plane_normal: Vector3,
	node: Node3D) -> Vector3:

	var transform := node.global_transform
	var position: Vector3 = node.global_position
	var quat: Quaternion = transform.basis.get_rotation_quaternion()
	var quat_axis: Vector3 = quat.get_axis() if quat.get_axis().is_normalized() else Vector3.UP
	var quat_angle: float = quat.get_angle()
	var scale: Vector3 = transform.basis.get_scale()
	var global_gizmo_position: Vector3 = local_gizmo_position.rotated(quat_axis, quat_angle) * scale + position
	var global_plane_normal: Vector3 = plane_normal.rotated(quat_axis, quat_angle)
	var global_plane: Plane = Plane(global_plane_normal, global_gizmo_position)
	var local_offset: Vector3 = (global_plane.intersects_ray(camera.position, camera.project_position(screen_pos, 1.0) - camera.position) - position).rotated(quat_axis, -quat_angle) / scale
	return local_offset

# Adds debug lines for the plane the gizmo can move on
# Should only be called on gizmo redraw
func debug_draw_handle_grid(
	camera_position: Vector3,
	screen_pos: Vector2,
	local_gizmo_position: Vector3,
	local_offset_axis: Vector3,
	node: Node3D,
	gizmo: EditorNode3DGizmo,
	plugin: EditorNode3DGizmoPlugin,
	grid_size: float = 1.0) -> void:

	var transform := node.global_transform
	var position: Vector3 = node.global_position
	var quat: Quaternion = transform.basis.get_rotation_quaternion()
	var quat_axis: Vector3 = quat.get_axis() if quat.get_axis().is_normalized() else Vector3.UP
	var quat_angle: float = quat.get_angle()
	var scale: Vector3 = transform.basis.get_scale()
	var local_camera_position: Vector3 = (camera_position - position).rotated(quat_axis, -quat_angle) / scale
	var local_plane: Plane = get_camera_oriented_plane(local_camera_position, local_gizmo_position, local_offset_axis)

	debug_draw_grid_on_plane(local_gizmo_position, local_offset_axis, gizmo, plugin, local_plane, grid_size)

func debug_draw_handle_grid_on_plane(
	local_gizmo_position: Vector3,
	local_offset_axis: Vector3,
	plane_normal: Vector3,
	node: Node3D,
	gizmo: EditorNode3DGizmo,
	plugin: EditorNode3DGizmoPlugin,
	grid_size: float = 1.0) -> void:

	var transform := node.global_transform
	var position: Vector3 = node.global_position
	var quat: Quaternion = transform.basis.get_rotation_quaternion()
	var quat_axis: Vector3 = quat.get_axis() if quat.get_axis().is_normalized() else Vector3.UP
	var quat_angle: float = quat.get_angle()
	var scale: Vector3 = transform.basis.get_scale()
	var local_plane: Plane = Plane(plane_normal, local_gizmo_position)

	debug_draw_grid_on_plane(local_gizmo_position, local_offset_axis, gizmo, plugin, local_plane, grid_size)

func debug_draw_grid_on_plane(
	local_gizmo_position: Vector3,
	local_offset_axis: Vector3,
	gizmo: EditorNode3DGizmo,
	plugin: EditorNode3DGizmoPlugin,
 	local_plane: Plane,
	grid_size: float = 1.0
	) -> void:
	# Add debug lines
	var plane_lines = PackedVector3Array()
	# Push back gizmo positions like a grid on the plane
	var lines_on_grid: int = 11 # 11 lines in horizontal and vertical axis
	# var gradient_granularity: int = 10 # 10 sub-lines with varying opacity with each line
	for i in range(lines_on_grid):
		var horizontal_distance: float = (i - lines_on_grid / 2) * grid_size / lines_on_grid
		var horizontal_axis: Vector3 = local_gizmo_position + local_offset_axis.normalized() * horizontal_distance
		for j in range(lines_on_grid):
			var vertical_distance: float = (j - lines_on_grid / 2) * grid_size / lines_on_grid
			var vertical_axis: Vector3 = local_plane.normal.cross(local_offset_axis) * vertical_distance
			plane_lines.push_back(horizontal_axis + vertical_axis - local_plane.normal * 0.2 * grid_size / lines_on_grid)
			plane_lines.push_back(horizontal_axis + vertical_axis + local_plane.normal * 0.2 * grid_size / lines_on_grid)
			plane_lines.push_back(horizontal_axis + local_offset_axis.normalized() * 0.25 * grid_size / lines_on_grid + vertical_axis)
			plane_lines.push_back(horizontal_axis - local_offset_axis.normalized() * 0.25 * grid_size / lines_on_grid + vertical_axis)
			plane_lines.push_back(horizontal_axis + vertical_axis + local_plane.normal.cross(local_offset_axis) * 0.25 * grid_size / lines_on_grid)
			plane_lines.push_back(horizontal_axis + vertical_axis - local_plane.normal.cross(local_offset_axis) * 0.25 * grid_size / lines_on_grid)
			# TODO: set the opacity of the lines based on the distance from the center

	gizmo.add_lines(plane_lines, plugin.get_material("main", gizmo))

## Gets the plane along [param gizmo_position] going through [param gizmo_axis] and facing towards the [param camera_position].
## Consider [param camera_position], [param gizmo_position] and [param gizmo_axis] in the same space.
func get_camera_oriented_plane(
	camera_position: Vector3,
	gizmo_position: Vector3,
	gizmo_axis: Vector3) -> Plane:
	# camera: Camera to orient the plane to
	# gizmo_position: gizmo's current position in the world
	# gizmo_axis: axis the gizmo is moving along

	var closest_point_to_camera: Vector3 = get_closest_point_on_line(gizmo_position, gizmo_axis, camera_position)
	var closest_point_to_camera_difference: Vector3 = closest_point_to_camera - camera_position
	var parallel_to_gizmo_dir: Vector3 = closest_point_to_camera - gizmo_position
	var perpendicular_to_gizmo_dir: Vector3 = parallel_to_gizmo_dir.cross(closest_point_to_camera_difference).normalized()

	# Transform 3 points to global space
	var x: Vector3 = gizmo_position
	var y: Vector3 = gizmo_position + gizmo_axis
	var z: Vector3 = gizmo_position + perpendicular_to_gizmo_dir
	var plane := Plane(x, y, z)

	return plane

## [param point_in_line] is a point on the line
## [param line_dir] is the direction of the line
## [param point] is the point to find the closest point on the line to
func get_closest_point_on_line(
	point_on_line: Vector3,
	line_dir: Vector3,
	point: Vector3) -> Vector3:
	var A := point_on_line
	var B := point_on_line + line_dir  # This can be any other point in the direction of the line
	var AP := point - A
	var AB := B - A

	var t := AP.dot(AB) / AB.dot(AB)
	var closest_point := A + t * AB

	return closest_point

func snap_to_grid(
	value: float,
	grid_unit: float) -> float:
	return round(value / grid_unit) * grid_unit
