extends SceneTree

const ProtoWall = preload("res://addons/proto_shape/proto_wall/proto_wall.gd")
const ProtoWallGizmos = preload("res://addons/proto_shape/proto_wall/proto_wall_gizmos.gd")

class MockEditorUndoRedo extends RefCounted:
	var target: Object
	var property: StringName
	var do_value: Variant
	var undo_value: Variant

	func create_action(_name: String, _merge_mode: int, _custom_context: Object, _backward_undo_ops: bool) -> void:
		pass

	func add_do_property(object: Object, property_name: StringName, value: Variant) -> void:
		target = object
		property = property_name
		do_value = value

	func add_undo_property(object: Object, property_name: StringName, value: Variant) -> void:
		target = object
		property = property_name
		undo_value = value

	func commit_action() -> void:
		target.set(property, do_value)

	func undo() -> void:
		target.set(property, undo_value)

	func redo() -> void:
		target.set(property, do_value)

class MockPlugin extends RefCounted:
	var snapping := false
	var fine_snapping := false
	var undo_redo := MockEditorUndoRedo.new()

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_curve_lifecycle()
	await _test_thickness_cache_invalidation()
	await _test_bake_interval_spacing()
	await _test_reversible_rail_values()
	await _test_rail_save_reload()
	await _test_lower_rail_gizmo()

	if failures == 0:
		print("PASS: wall state")
	quit(failures)

func _test_curve_lifecycle() -> void:
	var default_wall := ProtoWall.new()
	root.add_child(default_wall)
	_check(default_wall.curve != null and default_wall.curve.get_point_count() == 2, "A new ProtoWall gets the default two-point curve")
	default_wall.queue_free()
	await process_frame

	var short_curve := Curve3D.new()
	short_curve.add_point(Vector3(1.0, 2.0, 3.0))
	var wall := ProtoWall.new()
	wall.curve = short_curve
	root.add_child(wall)
	_check(wall.curve == short_curve, "ProtoWall preserves an assigned short curve")
	_check(wall.curve.get_point_count() == 1, "ProtoWall does not replace a short curve with defaults")
	_check(wall.generated_shapes.is_empty(), "A short curve produces no generated geometry")
	_check(not wall.sampled_path_dirty and not wall.sampled_basis_dirty, "Short-curve refresh settles empty cache state")

	var curve := Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, 4.0))
	wall.curve = curve
	_check(is_equal_approx(wall.get_path_length(), 4.0), "Replacing the Path3D curve refreshes the sampled path")

	var replacement := Curve3D.new()
	replacement.add_point(Vector3.ZERO)
	replacement.add_point(Vector3(0.0, 0.0, 5.0))
	wall.curve = replacement
	var generated_id := wall.generated_shapes[0].get_instance_id()
	curve.set_point_position(1, Vector3(0.0, 0.0, 9.0))
	_check(is_equal_approx(wall.get_path_length(), 5.0), "Editing a detached old curve has no effect")
	_check(wall.generated_shapes[0].get_instance_id() == generated_id, "Editing a detached old curve does not regenerate geometry")

	replacement.set_point_position(1, Vector3(0.0, 0.0, 7.0))
	_check(is_equal_approx(wall.get_path_length(), 7.0), "Path3D curve_changed refreshes edits without polling")

	root.remove_child(wall)
	replacement.set_point_position(1, Vector3(0.0, 0.0, 8.0))
	root.add_child(wall)
	_check(is_equal_approx(wall.get_path_length(), 8.0), "Re-entering the tree rebuilds edits made while detached")

	replacement.clear_points()
	_check(is_equal_approx(wall.get_path_length(), 0.0), "An empty curve has zero path length")
	_check(not wall.sampled_path_dirty and not wall.sampled_basis_dirty, "Empty-curve getters settle cache state")
	replacement.add_point(Vector3.ZERO)
	_check(replacement.get_point_count() == 1, "Editing an active curve down to one point remains authored")
	_check(wall.generated_shapes.is_empty(), "Editing an active curve down to one point clears geometry")

	wall.queue_free()
	await process_frame

func _test_reversible_rail_values() -> void:
	var wall: Variant = _make_rail_wall()
	wall.height = 2.0
	wall.rail_count = 2
	wall.rail_thickness = 0.8
	wall.lower_rail_height = 0.6
	var thickness_hint := _get_property_hint(wall, &"rail_thickness")
	var lower_height_hint := _get_property_hint(wall, &"lower_rail_height")

	wall.height = 0.1
	wall.rail_count = 8
	_check(is_equal_approx(wall.rail_thickness, 0.8), "Shrinking height and increasing count preserves authored rail thickness")
	_check(is_equal_approx(wall.lower_rail_height, 0.6), "Shrinking height preserves authored lower rail height")
	_check(_get_property_hint(wall, &"rail_thickness") == thickness_hint, "Rail thickness Inspector range stays static")
	_check(_get_property_hint(wall, &"lower_rail_height") == lower_height_hint, "Lower rail height Inspector range stays static")
	_check(wall.get_effective_rail_thickness() * wall.rail_count <= wall.height + 0.000001, "Effective rail thickness fits height and count")
	_check(wall.get_effective_lower_rail_height() <= wall.height - wall.get_effective_rail_thickness() * (float(wall.rail_count) - 0.5) + 0.000001, "Effective lower rail height leaves room for every rendered rail")

	wall.rail_count = 2
	wall.height = 2.0
	_check(is_equal_approx(wall.get_effective_rail_thickness(), 0.8), "Growing the wall restores authored rail thickness")
	_check(is_equal_approx(wall.get_effective_lower_rail_height(), 0.6), "Growing the wall restores authored lower rail height")

	var undo_redo := UndoRedo.new()
	undo_redo.create_action("Shrink rail wall")
	undo_redo.add_do_property(wall, "height", 0.1)
	undo_redo.add_do_property(wall, "rail_count", 8)
	undo_redo.add_undo_property(wall, "rail_count", 2)
	undo_redo.add_undo_property(wall, "height", 2.0)
	undo_redo.commit_action()
	_check(is_equal_approx(wall.rail_thickness, 0.8) and is_equal_approx(wall.lower_rail_height, 0.6), "UndoRedo do properties preserve authored rail values")
	undo_redo.undo()
	_check(is_equal_approx(wall.get_effective_rail_thickness(), 0.8) and is_equal_approx(wall.get_effective_lower_rail_height(), 0.6), "Undo restores derived rail geometry")
	undo_redo.redo()
	_check(is_equal_approx(wall.rail_thickness, 0.8) and is_equal_approx(wall.lower_rail_height, 0.6), "Redo preserves authored rail values")
	undo_redo.free()

	wall.height = 0.001
	wall.rail_count = 128
	wall.rail_thickness = 1.0
	wall.lower_rail_height = 0.0
	var intervals: Array[Vector2] = wall._get_merged_rail_intervals()
	_check(intervals.size() == 1, "Touching rail intervals merge into one sweep profile")
	_check(intervals.size() == 1 and is_equal_approx(intervals[0].x, 0.0) and is_equal_approx(intervals[0].y, wall.height), "High rail counts fit and merge across a tiny height")
	var rail_mesh: Variant = wall.generated_shapes[0] if not wall.generated_shapes.is_empty() else null
	var rail_vertices := PackedVector3Array()
	if rail_mesh is CSGMesh3D and rail_mesh.mesh != null:
		rail_vertices = rail_mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_check(rail_vertices.size() == 28, "Merged touching rails generate one closed rectangular sweep")
	_check(is_equal_approx(wall._property_get_revert(&"rail_thickness"), 0.12), "Rail thickness revert stays authored and static")
	_check(is_equal_approx(wall._property_get_revert(&"lower_rail_height"), 0.45), "Lower rail height revert stays authored and static")

	wall.queue_free()
	await process_frame

func _test_rail_save_reload() -> void:
	var scene_root := Node3D.new()
	root.add_child(scene_root)
	var wall: Variant = _make_rail_wall(false)
	scene_root.add_child(wall)
	wall.owner = scene_root
	wall.height = 0.1
	wall.rail_count = 8
	wall.rail_thickness = 0.8
	wall.lower_rail_height = 0.6

	var packed := PackedScene.new()
	_check(packed.pack(scene_root) == OK, "ProtoWall rail scene packs")
	var save_path := "user://test_proto_wall_roundtrip.tscn"
	_check(ResourceSaver.save(packed, save_path) == OK, "ProtoWall rail scene saves")
	scene_root.queue_free()
	await process_frame

	var loaded_scene: PackedScene = load(save_path)
	var loaded_root := loaded_scene.instantiate()
	root.add_child(loaded_root)
	var loaded_wall: Variant = loaded_root.get_child(0)
	_check(is_equal_approx(loaded_wall.rail_thickness, 0.8), "Save and reload preserves authored rail thickness")
	_check(is_equal_approx(loaded_wall.lower_rail_height, 0.6), "Save and reload preserves authored lower rail height")
	loaded_wall.height = 2.0
	loaded_wall.rail_count = 2
	_check(is_equal_approx(loaded_wall.get_effective_rail_thickness(), 0.8), "Reloaded authored thickness restores when constraints grow")
	_check(is_equal_approx(loaded_wall.get_effective_lower_rail_height(), 0.6), "Reloaded authored lower height restores when constraints grow")

	loaded_root.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	await process_frame

func _test_lower_rail_gizmo() -> void:
	var wall: Variant = _make_rail_wall()
	wall.height = 0.5
	wall.rail_count = 3
	wall.rail_thickness = 0.1
	wall.lower_rail_height = 0.6

	var gizmo: Variant = ProtoWallGizmos.new()
	gizmo.attach_shape(wall)
	var center: Vector3 = gizmo._get_center_position()
	var up: Vector3 = gizmo._get_wall_up_axis()
	var handle_height: float = (gizmo._get_lower_rail_height_handle_position() - center).dot(up)
	_check(is_equal_approx(handle_height, wall.get_effective_lower_rail_height()), "Lower rail handle starts at the rendered effective height")
	_check(gizmo._get_visible_handle_ids().has(3), "Multiple rails show the lower rail handle")
	wall.rail_count = 1
	_check(not gizmo._get_visible_handle_ids().has(3), "A single rail hides the irrelevant lower rail handle")
	wall.rail_count = 2

	var plugin := MockPlugin.new()
	var rendered_start: float = wall.get_effective_lower_rail_height()
	gizmo._begin_drag(3, 2.0)
	_check(is_equal_approx(float(gizmo.start_value), 0.6), "Lower rail drag keeps the raw authored value for restore")
	_check(is_equal_approx(float(gizmo.drag_start_value), wall.get_effective_lower_rail_height()), "Lower rail drag begins from its rendered value")
	plugin.snapping = true
	gizmo._apply_dragged_pointer_value(plugin, 3, 2.0)
	gizmo._commit_current_edit(plugin, false)
	_check(is_equal_approx(wall.lower_rail_height, 0.6), "A zero-motion drag does not overwrite the authored value")
	plugin.snapping = false

	gizmo._begin_drag(3, 2.0)
	gizmo._apply_dragged_pointer_value(plugin, 3, 1.99)
	var moved_value: float = rendered_start - 0.01
	_check(is_equal_approx(wall.lower_rail_height, moved_value), "Lower rail drag moves immediately from the rendered value without a jump")
	gizmo._apply_dragged_pointer_value(plugin, 3, 2.0)
	gizmo._commit_current_edit(plugin, false)
	_check(is_equal_approx(wall.lower_rail_height, 0.6), "Returning to the rendered start preserves the authored value")

	gizmo._begin_drag(3, 2.0)
	gizmo._apply_dragged_pointer_value(plugin, 3, 1.99)
	moved_value = wall.lower_rail_height
	gizmo._commit_current_edit(plugin, false)
	plugin.undo_redo.undo()
	_check(is_equal_approx(wall.lower_rail_height, 0.6), "Lower rail gizmo undo restores the authored value")
	plugin.undo_redo.redo()
	_check(is_equal_approx(wall.lower_rail_height, moved_value), "Lower rail gizmo redo restores the edited value")

	gizmo._begin_drag(3, 2.0)
	gizmo._apply_dragged_pointer_value(plugin, 3, 1.98)
	gizmo._commit_current_edit(plugin, true)
	_check(is_equal_approx(wall.lower_rail_height, moved_value), "Cancelling a lower rail drag restores its raw starting value")

	wall.queue_free()
	await process_frame

func _test_thickness_cache_invalidation() -> void:
	var edited_wall: Variant = _make_corner_wall(0.05)
	edited_wall.thickness = 0.8
	var edited_points: PackedVector3Array = edited_wall.sampled_path_points.duplicate()

	var fresh_wall: Variant = _make_corner_wall(0.8)
	_check(_points_equal(edited_points, fresh_wall.sampled_path_points), "Changing thickness rebuilds the same sampled path as a fresh wall")

	edited_wall.queue_free()
	fresh_wall.queue_free()
	await process_frame

func _test_bake_interval_spacing() -> void:
	var curve := Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, 4.0))
	curve.bake_interval = 0.25

	var wall := ProtoWall.new()
	wall.curve = curve
	wall.path_interpolation = ProtoWall.PathInterpolation.FOLLOW_CURVED_PATH3D
	wall.follow_use_bake_interval = true
	wall.sample_simplify_angle = 0.0
	root.add_child(wall)
	_check(wall.sampled_path_points.size() == 17, "A 0.25 bake interval samples a four-unit path seventeen times")

	curve.bake_interval = 1.0
	_check(wall.sampled_path_points.size() == 5, "Increasing bake interval reduces generated sample density")

	curve.bake_interval = 3.0
	_check(wall.sampled_path_points.size() == 3, "Large native bake intervals use the maximum supported spacing")
	_check(is_equal_approx(wall._get_follow_bake_interval_sample_spacing(), ProtoWall.MAX_PATH_SAMPLE_SPACING), "Bake interval spacing respects the maximum bound")

	curve.bake_interval = 0.001
	_check(is_equal_approx(wall._get_follow_bake_interval_sample_spacing(), ProtoWall.MIN_PATH_SAMPLE_SPACING), "Bake interval spacing respects the minimum bound")

	wall.queue_free()
	await process_frame

func _make_corner_wall(wall_thickness: float) -> Variant:
	var curve := Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, 1.0))
	curve.add_point(Vector3(1.0, 0.0, 1.0))

	var wall := ProtoWall.new()
	wall.curve = curve
	wall.path_interpolation = ProtoWall.PathInterpolation.CORNER_ROUNDED
	wall.corner_rounding = 0.5
	wall.path_sample_spacing = 0.1
	wall.sample_simplify_angle = 0.0
	wall.thickness = wall_thickness
	root.add_child(wall)
	return wall

func _make_rail_wall(add_to_tree: bool = true) -> Variant:
	var curve := Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, 4.0))

	var wall := ProtoWall.new()
	wall.curve = curve
	wall.style = ProtoWall.Style.RAIL
	wall.post_enabled = false
	if add_to_tree:
		root.add_child(wall)
	return wall

func _points_equal(left: PackedVector3Array, right: PackedVector3Array) -> bool:
	if left.size() != right.size():
		return false
	for index in range(left.size()):
		if not left[index].is_equal_approx(right[index]):
			return false
	return true

func _get_property_hint(object: Object, property_name: StringName) -> String:
	for property in object.get_property_list():
		if property["name"] == property_name:
			return property["hint_string"]
	return ""

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
