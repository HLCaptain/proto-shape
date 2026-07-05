const ARROW_RADIAL_SEGMENTS := 12
const ARROW_PICK_DISTANCE_PIXELS := 14.0
const MIN_ARROW_LENGTH := 0.001

func add_arrow_mesh(
	gizmo: EditorNode3DGizmo,
	material: Material,
	from_position: Vector3,
	to_position: Vector3,
	radius_scale: float = 1.0) -> void:

	var direction := to_position - from_position
	var length := direction.length()
	if length <= MIN_ARROW_LENGTH:
		return

	var collision_segment := PackedVector3Array()
	collision_segment.push_back(from_position)
	collision_segment.push_back(to_position)
	gizmo.add_collision_segments(collision_segment)

	var forward := direction / length
	var shaft_radius: float = clamp(length * 0.025, 0.015, 0.04) * radius_scale
	var head_radius := shaft_radius * 2.75
	var head_length: float = clamp(length * 0.22, head_radius * 1.4, 0.35 * radius_scale)
	head_length = min(head_length, length * 0.65)
	var shaft_length := max(0.0, length - head_length)

	if shaft_length > MIN_ARROW_LENGTH:
		var shaft_mesh := CylinderMesh.new()
		shaft_mesh.top_radius = shaft_radius
		shaft_mesh.bottom_radius = shaft_radius
		shaft_mesh.height = shaft_length
		shaft_mesh.radial_segments = ARROW_RADIAL_SEGMENTS
		shaft_mesh.rings = 1
		var shaft_transform := _create_y_axis_transform(from_position + forward * shaft_length * 0.5, forward)
		gizmo.add_mesh(shaft_mesh, material, shaft_transform)

	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = head_radius
	head_mesh.height = head_length
	head_mesh.radial_segments = ARROW_RADIAL_SEGMENTS
	head_mesh.rings = 1
	var head_transform := _create_y_axis_transform(from_position + forward * (shaft_length + head_length * 0.5), forward)
	gizmo.add_mesh(head_mesh, material, head_transform)

func get_closest_screen_segment_id(
	camera: Camera3D,
	screen_pos: Vector2,
	node: Node3D,
	segments: Array,
	max_distance_pixels: float = ARROW_PICK_DISTANCE_PIXELS) -> int:

	var closest_id := -1
	var closest_distance := max_distance_pixels
	for segment in segments:
		if not (segment is Dictionary):
			continue
		if not segment.has("id") or not segment.has("from") or not segment.has("to"):
			continue

		var distance := get_screen_segment_distance(camera, screen_pos, node, segment["from"], segment["to"])
		if distance <= closest_distance:
			closest_id = segment["id"]
			closest_distance = distance

	return closest_id

func get_screen_segment_distance(
	camera: Camera3D,
	screen_pos: Vector2,
	node: Node3D,
	from_position: Vector3,
	to_position: Vector3) -> float:

	if camera == null or node == null:
		return INF

	var from_global: Vector3 = node.global_transform * from_position
	var to_global: Vector3 = node.global_transform * to_position
	if camera.is_position_behind(from_global) and camera.is_position_behind(to_global):
		return INF

	var from_screen := camera.unproject_position(from_global)
	var to_screen := camera.unproject_position(to_global)
	return get_screen_segment_distance_2d(screen_pos, from_screen, to_screen)

func get_screen_segment_distance_2d(point: Vector2, from_point: Vector2, to_point: Vector2) -> float:
	var segment := to_point - from_point
	var length_squared := segment.length_squared()
	if length_squared <= 0.000001:
		return point.distance_to(from_point)

	var t: float = clamp((point - from_point).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(from_point + segment * t)

func _create_y_axis_transform(origin: Vector3, direction: Vector3) -> Transform3D:
	var y_axis := direction.normalized()
	var reference := Vector3.UP
	if abs(y_axis.dot(reference)) > 0.98:
		reference = Vector3.FORWARD

	var x_axis := reference.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	return Transform3D(Basis(x_axis, y_axis, z_axis).orthonormalized(), origin)

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
