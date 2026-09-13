extends SceneTree

const ProtoWall = preload("res://addons/proto_shape/proto_wall/proto_wall.gd")
const ProtoWallGizmos = preload("res://addons/proto_shape/proto_wall/proto_wall_gizmos.gd")
const EPSILON := 0.0001

var failures := 0

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	for side in ProtoWall.WallSide.values():
		_test_straight_slope(side)
		await process_frame
	_test_bent_posts(false)
	await process_frame
	_test_bent_posts(true)
	await process_frame
	_test_degenerate_fixed_up()
	await process_frame
	await _test_tilted_and_full_loop()
	if failures == 0:
		print("PASS: fitted wall posts")
	quit(1 if failures else 0)

func _make_wall(points: Array, closed: bool = false, side: int = ProtoWall.WallSide.CENTER) -> Variant:
	var wall := ProtoWall.new()
	wall.curve = Curve3D.new()
	for point: Vector3 in points:
		wall.curve.add_point(point)
	wall.curve.closed = closed
	wall.style = ProtoWall.Style.RAIL
	wall.path_interpolation = ProtoWall.PathInterpolation.LINEAR
	wall.path_orientation = ProtoWall.PathOrientation.FIXED_UP
	wall.side = side
	wall.height = 4.0
	wall.thickness = 0.4
	wall.post_width = 0.4
	wall.post_placement = ProtoWall.PostPlacement.COUNT
	wall.post_count = 4 if closed else 3
	wall.material = StandardMaterial3D.new()
	wall.collisions_enabled = true
	root.add_child(wall)
	return wall

func _test_straight_slope(side: int) -> void:
	var wall: Variant = _make_wall([Vector3.ZERO, Vector3(0.0, 2.0, 4.0)], false, side)
	var offsets: PackedFloat32Array = wall._get_post_offsets()
	_check(offsets.size() == 3 and is_zero_approx(offsets[0]) and is_equal_approx(offsets[2], wall.get_path_length()), "Open counted posts retain both endpoints")
	var posts := _get_posts(wall)
	for index in range(posts.size()):
		var bounds := AABB()
		var vertices: PackedVector3Array = posts[index].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex_index in range(vertices.size()):
			var point: Vector3 = posts[index].transform * vertices[vertex_index]
			bounds = AABB(point, Vector3.ZERO) if vertex_index == 0 else bounds.expand(point)
		var center: Vector3 = wall.get_path_point(offsets[index])
		_check(abs(bounds.position.z - (center.z - wall.post_width / 2.0)) < EPSILON and abs(bounds.size.z - wall.post_width) < EPSILON, "Sloped posts retain full horizontal width, including open ends")
		_check(abs(bounds.size.x - wall.thickness) < EPSILON and abs(bounds.get_center().x + wall.get_side_center_offset(wall.thickness)) < EPSILON, "Post thickness and wall side offset match the rail")
	_check_top_fit(wall, posts, true)
	var basis: Basis = wall.get_post_basis(wall.get_middle_path_offset())
	var gizmo: Variant = ProtoWallGizmos.new()
	gizmo.attach_shape(wall)
	var center: Vector3 = wall.get_path_point(wall.get_middle_path_offset()) + basis.x * wall.get_side_center_offset(wall.thickness) + basis.y * wall.height / 2.0
	_check(basis.y.is_equal_approx(Vector3.UP) and basis.z.is_equal_approx(Vector3.BACK), "Fixed Up posts retain upright segment alignment")
	_check(gizmo._get_post_forward_axis().is_equal_approx(basis.z) and gizmo._get_post_width_handle_position().is_equal_approx(center + basis.z * wall.post_width / 2.0), "Post width gizmo retains its axis and handle position")
	var rail_before: Array = wall.generated_shapes[0].mesh.surface_get_arrays(0)
	var post_before: Array = posts[1].mesh.surface_get_arrays(0)
	var source_curve: Curve3D = wall.curve
	var undo_redo := UndoRedo.new()
	undo_redo.create_action("Resize fitted posts")
	undo_redo.add_do_property(wall, "post_width", 0.6)
	undo_redo.add_undo_property(wall, "post_width", 0.4)
	undo_redo.commit_action()
	_check(wall.generated_shapes[0].mesh.surface_get_arrays(0) == rail_before, "Changing post width leaves the rail mesh unchanged")
	_check(wall._get_post_offsets() == offsets and wall.curve == source_curve and source_curve.get_point_count() == 2 and source_curve.get_point_position(1) == Vector3(0.0, 2.0, 4.0), "Changing post width preserves the authored curve and placement")
	_check(is_equal_approx(wall.height, 4.0) and is_equal_approx(wall.thickness, 0.4), "Fitting does not change authored wall dimensions")
	_check_top_fit(wall, _get_posts(wall), true)
	undo_redo.undo()
	_check(wall.generated_shapes[3].mesh.surface_get_arrays(0) == post_before, "Undo restores exact fitted post geometry")
	undo_redo.redo()
	_check_top_fit(wall, _get_posts(wall), true)
	undo_redo.free()
	wall.collisions_enabled = false
	wall.material = null
	for post in wall.generated_shapes.slice(2):
		if post is CSGMesh3D:
			_check(not post.use_collision and post.material == null and post.mesh.surface_get_material(0) == null, "Rebuilt posts also forward disabled collision and cleared material")
	wall.queue_free()

func _test_bent_posts(closed: bool) -> void:
	var points := [Vector3.ZERO, Vector3(0.0, 1.0, 2.0), Vector3(2.0, 2.0, 2.0)]
	if closed:
		points.append(Vector3(2.0, 1.0, 0.0))
	var wall: Variant = _make_wall(points, closed)
	if not closed:
		wall.post_count = 1
	var offsets: PackedFloat32Array = wall._get_post_offsets()
	_check(offsets.size() == (4 if closed else 1), "Bent rail retains its requested post count")
	if closed:
		_check(is_zero_approx(offsets[0]) and offsets[offsets.size() - 1] < wall.get_path_length(), "Closed seam has one post and no duplicated endpoint")
	else:
		_check(wall.get_path_point(offsets[0]).is_equal_approx(points[1]), "Corner regression places a post across the slope change")
	_check_top_fit(wall, _get_posts(wall))
	wall.queue_free()

func _get_posts(wall: Variant) -> Array:
	var posts: Array = []
	for child in wall.generated_shapes.slice(2):
		_check(child is CSGMesh3D and child.mesh != null, "Posts use fitted meshes")
		if child is CSGMesh3D and child.mesh != null:
			_check(child.use_collision and (child.material == wall.material or child.mesh.surface_get_material(0) == wall.material), "Post meshes retain collision and material settings")
			posts.append(child)
	_check(posts.size() == wall._get_post_offsets().size(), "Every requested post generates one mesh")
	return posts

func _test_degenerate_fixed_up() -> void:
	for horizontal_distance in [0.0, 0.0005]:
		var wall: Variant = _make_wall([Vector3.ZERO, Vector3(0.0, 2.0, horizontal_distance)])
		var posts: Array = wall.generated_shapes.slice(2)
		_check(posts.size() == wall._get_post_offsets().size(), "Near-vertical Fixed Up paths retain their posts")
		for post in posts:
			_check(post is CSGBox3D and post.size == Vector3(wall.thickness, wall.height, wall.post_width), "Undefined horizontal footprint retains full-size box fallback")
		wall.queue_free()

func _test_tilted_and_full_loop() -> void:
	var wall: Variant = _make_wall([Vector3.ZERO, Vector3(0, 1, 2), Vector3(2, 2, 2), Vector3(2, 1, 0)], true)
	wall.path_orientation = ProtoWall.PathOrientation.PATH_PERPENDICULAR
	wall.curve.set_point_tilt(1, 0.35)
	for frame in range(5):
		await process_frame
	for post in _get_posts(wall):
		var arrays: Array = post.mesh.surface_get_arrays(0)
		_check_closed_mesh(arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_INDEX])
		var baked: Array = post.get_meshes()
		_check(baked.size() == 2 and baked[1].get_faces().size() > 0, "Tilted post produces real CSG geometry")
	wall.queue_free()
	await process_frame

	wall = _make_wall([Vector3.ZERO, Vector3(0, 0, 0.1), Vector3(0.1, 0, 0.1), Vector3(0.1, 0, 0)], true)
	wall.thickness = 0.02
	wall.height = 0.5
	for width in [0.4, 0.8]:
		wall.post_width = width
		_check(wall.generated_shapes.size() == 3, "A footprint covering the loop produces one closed fill, not duplicate posts")
		var arrays: Array = wall.generated_shapes[2].mesh.surface_get_arrays(0)
		_check_closed_mesh(arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_INDEX])
		_check(wall.post_width == width and wall.post_count == 4, "Full-loop fitting preserves authored width and count")
	wall.post_width = 0.05
	_check(_get_posts(wall).size() == 4, "Reducing width restores separate posts")
	wall.queue_free()
	await process_frame

func _check_top_fit(wall: Variant, posts: Array, straight_slope: bool = false) -> void:
	var rail: Array = wall.generated_shapes[0].mesh.surface_get_arrays(0)
	for post: CSGMesh3D in posts:
		var arrays := post.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var top_triangles := 0
		var matches := true
		for index in range(0, indices.size(), 3):
			var a: Vector3 = post.transform * vertices[indices[index]]
			var b: Vector3 = post.transform * vertices[indices[index + 1]]
			var c: Vector3 = post.transform * vertices[indices[index + 2]]
			# These tall Fixed Up fixtures separate downward-wound top faces from
			# the much steeper clipped end caps and side faces.
			if (b - a).cross(c - a).normalized().dot(Vector3.UP) >= -0.25:
				continue
			top_triangles += 1
			for point: Vector3 in [a, b, c, (a + b) / 2.0, (b + c) / 2.0, (c + a) / 2.0, (a + b + c) / 3.0]:
				if straight_slope:
					matches = matches and abs(point.y - wall.height - point.z * 0.5) < EPSILON
					if point.z < 0.0 or point.z > 4.0:
						continue
				var hit: Variant = _rail_top_at(rail, point)
				matches = matches and hit != null and abs(point.y - float(hit)) < EPSILON
		_check(top_triangles >= 2 and matches, "Post top vertices, edges and face interiors lie on the generated rail boundary")
		_check_closed_mesh(vertices, indices)

func _rail_top_at(arrays: Array, point: Vector3) -> Variant:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var top: Variant = null
	for index in range(0, indices.size(), 3):
		var a := vertices[indices[index]]
		var b := vertices[indices[index + 1]]
		var c := vertices[indices[index + 2]]
		var center := (a + b + c) / 3.0
		# Allow sub-EPSILON edge rounding without changing the triangle plane.
		var hit: Variant = Geometry3D.ray_intersects_triangle(point + Vector3.UP * 8.0, Vector3.DOWN, center + (a - center) * 1.00001, center + (b - center) * 1.00001, center + (c - center) * 1.00001)
		if hit != null and (top == null or hit.y > float(top)):
			top = hit.y
	return top

func _check_closed_mesh(vertices: PackedVector3Array, indices: PackedInt32Array) -> void:
	var welded := {}
	var edges := {}
	var nondegenerate := true
	for index in range(0, indices.size(), 3):
		var ids: Array[int] = []
		for offset in range(3):
			var key := Vector3i((vertices[indices[index + offset]] / 0.00001).round())
			if not welded.has(key):
				welded[key] = welded.size()
			ids.append(welded[key])
		var a := vertices[indices[index]]
		var b := vertices[indices[index + 1]]
		var c := vertices[indices[index + 2]]
		nondegenerate = nondegenerate and (b - a).cross(c - a).length_squared() > 0.00000000000001
		for edge_index in range(3):
			var edge := Vector2i(min(ids[edge_index], ids[(edge_index + 1) % 3]), max(ids[edge_index], ids[(edge_index + 1) % 3]))
			edges[edge] = edges.get(edge, 0) + 1
	_check(nondegenerate and not indices.is_empty(), "Fitted post triangles are nondegenerate")
	_check(not edges.is_empty() and edges.values().all(func(count: int) -> bool: return count == 2), "Fitted posts are closed after welding shared vertices")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
