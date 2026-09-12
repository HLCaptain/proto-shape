const ARROW_RADIAL_SEGMENTS := 12
const ARROW_PICK_DISTANCE_PIXELS := 14.0
const ARROW_PICK_EDGE_TOLERANCE_PIXELS := 1.5
const MIN_ARROW_LENGTH := 0.001
const MIN_TRANSFORM_DETERMINANT := 0.000000001
const MIN_PLANE_NORMAL_LENGTH_SQUARED := 0.00000001
const MIN_RAY_PLANE_DOT := 0.000001

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
	var dimensions := get_arrow_dimensions(length, radius_scale)
	var shaft_radius: float = dimensions["shaft_radius"]
	var head_radius: float = dimensions["head_radius"]
	var head_length: float = dimensions["head_length"]
	var shaft_length: float = dimensions["shaft_length"]

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

func get_arrow_dimensions(length: float, radius_scale: float = 1.0) -> Dictionary:
	var shaft_radius: float = clamp(length * 0.025, 0.015, 0.04) * radius_scale
	var head_radius := shaft_radius * 2.75
	var head_length: float = clamp(length * 0.22, head_radius * 1.4, 0.35 * radius_scale)
	head_length = min(head_length, length * 0.65)
	return {
		"shaft_radius": shaft_radius,
		"head_radius": head_radius,
		"head_length": head_length,
		"shaft_length": max(0.0, length - head_length),
	}

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

func get_screen_arrow_signed_distance(
	camera: Camera3D,
	screen_pos: Vector2,
	node: Node3D,
	from_position: Vector3,
	to_position: Vector3,
	radius_scale: float = 1.0) -> float:

	if camera == null or node == null:
		return INF

	var direction := to_position - from_position
	var length := direction.length()
	if length <= MIN_ARROW_LENGTH:
		return INF

	var from_global: Vector3 = node.global_transform * from_position
	var to_global: Vector3 = node.global_transform * to_position
	if camera.is_position_behind(from_global) or camera.is_position_behind(to_global):
		return INF

	var forward := direction / length
	var dimensions := get_arrow_dimensions(length, radius_scale)
	var shaft_radius: float = dimensions["shaft_radius"]
	var head_radius: float = dimensions["head_radius"]
	var shaft_length: float = dimensions["shaft_length"]
	var head_base_position := from_position + forward * shaft_length
	var head_base_global: Vector3 = node.global_transform * head_base_position
	if camera.is_position_behind(head_base_global):
		return INF

	var from_screen := camera.unproject_position(from_global)
	var to_screen := camera.unproject_position(to_global)
	var head_base_screen := camera.unproject_position(head_base_global)
	var arrow_basis := _create_y_axis_transform(Vector3.ZERO, forward).basis
	var closest_distance := INF

	if shaft_length > MIN_ARROW_LENGTH:
		var shaft_center_global: Vector3 = node.global_transform * from_position.lerp(head_base_position, 0.5)
		var shaft_screen_radius := _get_projected_radius_pixels(camera, shaft_center_global, node, arrow_basis, shaft_radius)
		closest_distance = min(
			closest_distance,
			get_screen_tapered_segment_signed_distance(screen_pos, from_screen, head_base_screen, shaft_screen_radius, shaft_screen_radius)
		)

	var head_center_global: Vector3 = node.global_transform * head_base_position.lerp(to_position, 0.5)
	var head_screen_radius := _get_projected_radius_pixels(camera, head_center_global, node, arrow_basis, head_radius)
	closest_distance = min(
		closest_distance,
		get_screen_tapered_segment_signed_distance(screen_pos, head_base_screen, to_screen, head_screen_radius, 0.0)
	)

	return closest_distance

func get_screen_tapered_segment_signed_distance(
	point: Vector2,
	from_point: Vector2,
	to_point: Vector2,
	from_radius: float,
	to_radius: float) -> float:

	var segment := to_point - from_point
	var length_squared := segment.length_squared()
	if length_squared <= 0.000001:
		return point.distance_to(from_point) - max(from_radius, to_radius)

	var t: float = clamp((point - from_point).dot(segment) / length_squared, 0.0, 1.0)
	var radius := lerp(from_radius, to_radius, t)
	return point.distance_to(from_point + segment * t) - radius

func get_screen_segment_distance_2d(point: Vector2, from_point: Vector2, to_point: Vector2) -> float:
	var segment := to_point - from_point
	var length_squared := segment.length_squared()
	if length_squared <= 0.000001:
		return point.distance_to(from_point)

	var t: float = clamp((point - from_point).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(from_point + segment * t)

func _get_projected_radius_pixels(
	camera: Camera3D,
	center_global: Vector3,
	node: Node3D,
	arrow_basis: Basis,
	radius: float) -> float:

	if camera.is_position_behind(center_global):
		return 0.0

	var center_screen := camera.unproject_position(center_global)
	var radius_axis_x: Vector3 = node.global_transform.basis * (arrow_basis.x * radius)
	var radius_axis_z: Vector3 = node.global_transform.basis * (arrow_basis.z * radius)
	var radius_pixels := 0.0
	var x_global := center_global + radius_axis_x
	if not camera.is_position_behind(x_global):
		radius_pixels = max(radius_pixels, center_screen.distance_to(camera.unproject_position(x_global)))

	var z_global := center_global + radius_axis_z
	if not camera.is_position_behind(z_global):
		radius_pixels = max(radius_pixels, center_screen.distance_to(camera.unproject_position(z_global)))
	return radius_pixels

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
## Returns a local-space [Vector3], or [code]null[/code] when projection is not safe.
func get_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2,
	local_gizmo_position: Vector3,
	local_offset_axis: Vector3,
	node: Node3D) -> Variant:

	if not _can_project(camera, node, screen_pos, local_gizmo_position, local_offset_axis):
		return null

	var transform := node.global_transform
	var global_gizmo_position := transform * local_gizmo_position
	var global_offset_axis := transform.basis * local_offset_axis
	if not _is_valid_direction(global_offset_axis):
		return null
	global_offset_axis = global_offset_axis.normalized()

	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_direction := camera.project_ray_normal(screen_pos)
	if not ray_origin.is_finite() or not _is_valid_direction(ray_direction):
		return null
	ray_direction = ray_direction.normalized()

	var view_direction := global_gizmo_position - ray_origin
	if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		view_direction = ray_direction
	var plane_normal := view_direction - global_offset_axis * view_direction.dot(global_offset_axis)
	return _intersect_local(camera, node, screen_pos, global_gizmo_position, plane_normal)

## Projects onto an explicit local plane, returning a local-space [Vector3] or [code]null[/code].
func get_handle_offset_by_plane(
	camera: Camera3D,
	screen_pos: Vector2,
	local_gizmo_position: Vector3,
	plane_normal: Vector3,
	node: Node3D) -> Variant:

	if not _can_project(camera, node, screen_pos, local_gizmo_position, plane_normal):
		return null

	var transform := node.global_transform
	var global_gizmo_position := transform * local_gizmo_position
	var global_plane_normal := transform.basis.inverse().transposed() * plane_normal
	return _intersect_local(camera, node, screen_pos, global_gizmo_position, global_plane_normal)

func _can_project(camera: Camera3D, node: Node3D, screen_pos: Vector2, local_position: Vector3, local_direction: Vector3) -> bool:
	return (
		is_instance_valid(camera)
		and is_instance_valid(node)
		and screen_pos.is_finite()
		and local_position.is_finite()
		and _is_valid_direction(local_direction)
		and _is_valid_transform(node.global_transform)
	)

func _is_valid_transform(transform: Transform3D) -> bool:
	return (
		transform.origin.is_finite()
		and transform.basis.x.is_finite()
		and transform.basis.y.is_finite()
		and transform.basis.z.is_finite()
		and abs(transform.basis.determinant()) > MIN_TRANSFORM_DETERMINANT
	)

func _is_valid_direction(direction: Vector3) -> bool:
	return direction.is_finite() and direction.length_squared() > MIN_PLANE_NORMAL_LENGTH_SQUARED

func _intersect_local(
	camera: Camera3D,
	node: Node3D,
	screen_pos: Vector2,
	global_gizmo_position: Vector3,
	global_plane_normal: Vector3) -> Variant:

	if not global_gizmo_position.is_finite() or not _is_valid_direction(global_plane_normal):
		return null
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_direction := camera.project_ray_normal(screen_pos)
	if not ray_origin.is_finite() or not _is_valid_direction(ray_direction):
		return null
	ray_direction = ray_direction.normalized()
	global_plane_normal = global_plane_normal.normalized()
	if abs(global_plane_normal.dot(ray_direction)) <= MIN_RAY_PLANE_DOT:
		return null

	var intersection: Variant = Plane(global_plane_normal, global_gizmo_position).intersects_ray(ray_origin, ray_direction)
	if not (intersection is Vector3) or not intersection.is_finite():
		return null
	var local_intersection: Vector3 = node.global_transform.affine_inverse() * intersection
	return local_intersection if local_intersection.is_finite() else null

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

	if not is_instance_valid(node) or not _is_valid_transform(node.global_transform):
		return
	var transform := node.global_transform
	var global_gizmo_position := transform * local_gizmo_position
	var global_axis := transform.basis * local_offset_axis
	if not camera_position.is_finite() or not _is_valid_direction(global_axis):
		return
	global_axis = global_axis.normalized()
	var global_view := global_gizmo_position - camera_position
	var global_plane_normal := global_view - global_axis * global_view.dot(global_axis)
	if not _is_valid_direction(global_plane_normal):
		return
	var local_plane_normal := transform.basis.transposed() * global_plane_normal.normalized()
	if not _is_valid_direction(local_plane_normal):
		return
	var local_plane := Plane(local_plane_normal.normalized(), local_gizmo_position)

	debug_draw_grid_on_plane(local_gizmo_position, local_offset_axis, gizmo, plugin, local_plane, grid_size)

func debug_draw_handle_grid_on_plane(
	local_gizmo_position: Vector3,
	local_offset_axis: Vector3,
	plane_normal: Vector3,
	node: Node3D,
	gizmo: EditorNode3DGizmo,
	plugin: EditorNode3DGizmoPlugin,
	grid_size: float = 1.0) -> void:

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

	if not camera_position.is_finite() or not gizmo_position.is_finite() or not _is_valid_direction(gizmo_axis):
		return Plane()
	var axis := gizmo_axis.normalized()
	var view_direction := gizmo_position - camera_position
	var plane_normal := view_direction - axis * view_direction.dot(axis)
	if not _is_valid_direction(plane_normal):
		return Plane()
	return Plane(plane_normal.normalized(), gizmo_position)

## [param point_in_line] is a point on the line
## [param line_dir] is the direction of the line
## [param point] is the point to find the closest point on the line to
func get_closest_point_on_line(
	point_on_line: Vector3,
	line_dir: Vector3,
	point: Vector3) -> Vector3:
	if not _is_valid_direction(line_dir):
		return point_on_line
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
