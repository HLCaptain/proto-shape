const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")
const ProtoWall = preload("res://addons/proto_shape/proto_wall/proto_wall.gd")

const HANDLE_HEIGHT := 1
const HANDLE_THICKNESS := 2
const HANDLE_LOWER_RAIL_HEIGHT := 3
const HANDLE_POST_WIDTH := 4
const MIN_ARROW_VISUAL_LENGTH := 0.25
const MAX_ARROW_VISUAL_LENGTH := 0.75

var shape: ProtoWall = null
var gizmo_utils := ProtoGizmoUtils.new()
var editing_handle := 0
var start_value: Variant = 0.0
var end_value: Variant = 0.0
var drag_start_pointer_value: Variant = 0.0

func attach_shape(node: ProtoWall) -> void:
	shape = node

func remove_shape() -> void:
	shape = null

func redraw_gizmos(gizmo, plugin) -> void:
	if shape == null or gizmo.get_node_3d() != shape:
		return

	gizmo.clear()
	var height_handle := _get_height_handle_position()
	var thickness_handle := _get_thickness_handle_position()

	_add_handle_arrow(gizmo, plugin, HANDLE_HEIGHT, height_handle, _get_wall_up_axis())
	_add_handle_arrow(gizmo, plugin, HANDLE_THICKNESS, thickness_handle, _get_thickness_drag_axis())

	var handles := PackedVector3Array()
	var ids := []
	handles.push_back(height_handle)
	ids.push_back(HANDLE_HEIGHT)
	handles.push_back(thickness_handle)
	ids.push_back(HANDLE_THICKNESS)

	if shape.style == ProtoWall.Style.RAIL:
		var lower_rail_handle := _get_lower_rail_height_handle_position()
		_add_handle_arrow(gizmo, plugin, HANDLE_LOWER_RAIL_HEIGHT, lower_rail_handle, _get_wall_up_axis())
		handles.push_back(lower_rail_handle)
		ids.push_back(HANDLE_LOWER_RAIL_HEIGHT)

		if shape.post_enabled:
			var post_width_handle := _get_post_width_handle_position()
			_add_handle_arrow(gizmo, plugin, HANDLE_POST_WIDTH, post_width_handle, _get_post_forward_axis())
			handles.push_back(post_width_handle)
			ids.push_back(HANDLE_POST_WIDTH)

	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), ids)

func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if shape == null or gizmo.get_node_3d() != shape:
		return

	if editing_handle == 0:
		begin_arrow_drag(plugin, handle_id, camera, screen_pos)
		drag_start_pointer_value = start_value
	set_arrow_drag(plugin, handle_id, camera, screen_pos)

func get_arrow_drag_segments(_plugin) -> Array:
	return _get_arrow_segments()

func begin_arrow_drag(_plugin, handle_id: int, camera: Camera3D, screen_pos: Vector2) -> void:
	if editing_handle == 0:
		editing_handle = handle_id
		start_value = _get_handle_value(handle_id)
		drag_start_pointer_value = _get_dragged_value(handle_id, camera, screen_pos)
		end_value = start_value

func set_arrow_drag(plugin, handle_id: int, camera: Camera3D, screen_pos: Vector2) -> void:
	var value: Variant = _get_relative_dragged_value(handle_id, camera, screen_pos)
	value = _apply_snapping(value, plugin)
	_set_handle_value(handle_id, value)
	end_value = _get_handle_value(handle_id)
	shape.update_gizmos()

func commit_arrow_drag(plugin, _handle_id: int, cancel: bool) -> void:
	if editing_handle == 0:
		return
	_commit_current_edit(plugin, cancel)

func commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	if shape == null or gizmo.get_node_3d() != shape or editing_handle == 0:
		return

	_commit_current_edit(plugin, cancel)

func _commit_current_edit(plugin, cancel: bool) -> void:
	if cancel:
		_set_handle_value(editing_handle, start_value)
		shape.update_gizmos()
		editing_handle = 0
		return

	var property_name := _get_property_name(editing_handle)
	var undo_redo = plugin.undo_redo
	undo_redo.create_action("Edit wall %s" % property_name, 0, shape, true)
	undo_redo.add_do_property(shape, property_name, end_value)
	undo_redo.add_undo_property(shape, property_name, start_value)
	undo_redo.commit_action()
	editing_handle = 0

func _get_handle_position(handle_id: int) -> Vector3:
	match handle_id:
		HANDLE_HEIGHT:
			return _get_height_handle_position()
		HANDLE_THICKNESS:
			return _get_thickness_handle_position()
		HANDLE_LOWER_RAIL_HEIGHT:
			return _get_lower_rail_height_handle_position()
		HANDLE_POST_WIDTH:
			return _get_post_width_handle_position()
	return Vector3.ZERO

func _get_handle_path_offset() -> float:
	return shape.get_middle_path_offset()

func _get_wall_basis() -> Basis:
	return shape.get_wall_basis(_get_handle_path_offset())

func _get_post_basis() -> Basis:
	return shape.get_post_basis(_get_handle_path_offset())

func _get_thickness_basis() -> Basis:
	return shape.get_segment_aligned_basis(_get_handle_path_offset())

func _get_wall_up_axis() -> Vector3:
	return _get_wall_basis().y

func _get_thickness_side_axis() -> Vector3:
	return _get_thickness_basis().x

func _get_post_forward_axis() -> Vector3:
	return _get_post_basis().z

func _get_center_position() -> Vector3:
	var offset := _get_handle_path_offset()
	var basis := _get_wall_basis()
	var center := shape.get_path_point(offset)
	center += basis.x * shape.get_side_center_offset(shape.thickness)
	return center

func _get_height_handle_position() -> Vector3:
	return _get_center_position() + _get_wall_up_axis() * shape.height

func _get_thickness_handle_position() -> Vector3:
	var offset := _get_handle_path_offset()
	var basis := _get_thickness_basis()
	var point := shape.get_path_point(offset)
	return point + basis.x * shape.get_side_outer_offset(shape.thickness) + basis.y * shape.height / 2.0

func _get_lower_rail_height_handle_position() -> Vector3:
	return _get_center_position() + _get_wall_up_axis() * shape.lower_rail_height

func _get_post_center_position() -> Vector3:
	var offset := _get_handle_path_offset()
	var basis := _get_post_basis()
	var center := shape.get_path_point(offset)
	center += basis.x * shape.get_side_center_offset(shape.thickness)
	center += basis.y * shape.height / 2.0
	return center

func _get_post_width_handle_position() -> Vector3:
	return _get_post_center_position() + _get_post_forward_axis() * shape.post_width / 2.0

func _get_arrow_segments() -> Array:
	var segments := []
	for handle_id in _get_visible_handle_ids():
		var direction := _get_drag_axis(handle_id)
		if direction.length_squared() <= 0.000001:
			continue

		var from_position := _get_handle_position(handle_id)
		segments.append({
			"id": handle_id,
			"from": from_position,
			"to": from_position + direction.normalized() * _get_arrow_visual_length(),
		})
	return segments

func _get_visible_handle_ids() -> Array:
	var ids := [HANDLE_HEIGHT, HANDLE_THICKNESS]
	if shape.style == ProtoWall.Style.RAIL:
		ids.push_back(HANDLE_LOWER_RAIL_HEIGHT)
		if shape.post_enabled:
			ids.push_back(HANDLE_POST_WIDTH)
	return ids

func _get_drag_axis(handle_id: int) -> Vector3:
	match handle_id:
		HANDLE_HEIGHT, HANDLE_LOWER_RAIL_HEIGHT:
			return _get_wall_up_axis()
		HANDLE_THICKNESS:
			return _get_thickness_drag_axis()
		HANDLE_POST_WIDTH:
			return _get_post_forward_axis()
	return Vector3.ZERO

func _add_handle_arrow(gizmo, plugin, handle_id: int, base_position: Vector3, direction: Vector3) -> void:
	if plugin.has_method("should_draw_mesh_guides") and not plugin.should_draw_mesh_guides(gizmo):
		return
	if direction.length_squared() <= 0.000001:
		return

	var material: Material = plugin.get_material("main", gizmo)
	if plugin.has_method("get_handle_arrow_material"):
		material = plugin.get_handle_arrow_material(gizmo, handle_id)
	gizmo_utils.add_arrow_mesh(gizmo, material, base_position, base_position + direction.normalized() * _get_arrow_visual_length())

func _get_arrow_visual_length() -> float:
	return clamp(max(shape.height, max(shape.thickness, shape.post_width)) * 0.25, MIN_ARROW_VISUAL_LENGTH, MAX_ARROW_VISUAL_LENGTH)

func _get_thickness_drag_axis() -> Vector3:
	var side_axis := _get_thickness_side_axis()
	if shape.side == ProtoWall.WallSide.LEFT:
		return -side_axis
	return side_axis

func is_handle_highlighted(_gizmo, _plugin, handle_id: int, _secondary: bool) -> bool:
	return editing_handle == handle_id

func _get_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> Variant:
	match handle_id:
		HANDLE_HEIGHT:
			var axis := _get_wall_up_axis()
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_height_handle_position(), axis, shape)
			return max(ProtoWall.MIN_DIMENSION, (offset - _get_center_position()).dot(axis))
		HANDLE_THICKNESS:
			var side_axis := _get_thickness_side_axis()
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_thickness_handle_position(), side_axis, shape)
			var side_distance := (offset - shape.get_path_point(_get_handle_path_offset())).dot(side_axis)
			match shape.side:
				ProtoWall.WallSide.LEFT:
					return max(ProtoWall.MIN_DIMENSION, -side_distance)
				ProtoWall.WallSide.RIGHT:
					return max(ProtoWall.MIN_DIMENSION, side_distance)
			return max(ProtoWall.MIN_DIMENSION, abs(side_distance) * 2.0)
		HANDLE_LOWER_RAIL_HEIGHT:
			var axis := _get_wall_up_axis()
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_lower_rail_height_handle_position(), axis, shape)
			return max(ProtoWall.MIN_DIMENSION, (offset - _get_center_position()).dot(axis))
		HANDLE_POST_WIDTH:
			var forward := _get_post_forward_axis()
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_post_width_handle_position(), forward, shape)
			var forward_distance := (offset - _get_post_center_position()).dot(forward)
			return max(ProtoWall.MIN_DIMENSION, forward_distance * 2.0)
	return ProtoWall.MIN_DIMENSION

func _get_relative_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> Variant:
	var pointer_value: Variant = _get_dragged_value(handle_id, camera, screen_pos)
	return max(ProtoWall.MIN_DIMENSION, float(start_value) + float(pointer_value) - float(drag_start_pointer_value))

func _apply_snapping(value: float, plugin) -> float:
	if plugin.fine_snapping:
		return gizmo_utils.snap_to_grid(value, 0.1)
	if plugin.snapping:
		return gizmo_utils.snap_to_grid(value, 1.0)
	return value

func _get_handle_value(handle_id: int) -> Variant:
	match handle_id:
		HANDLE_HEIGHT:
			return shape.height
		HANDLE_THICKNESS:
			return shape.thickness
		HANDLE_LOWER_RAIL_HEIGHT:
			return shape.lower_rail_height
		HANDLE_POST_WIDTH:
			return shape.post_width
	return 0.0

func _set_handle_value(handle_id: int, value: Variant) -> void:
	match handle_id:
		HANDLE_HEIGHT:
			shape.height = value
		HANDLE_THICKNESS:
			shape.thickness = value
		HANDLE_LOWER_RAIL_HEIGHT:
			shape.lower_rail_height = value
		HANDLE_POST_WIDTH:
			shape.post_width = value

func _get_property_name(handle_id: int) -> StringName:
	match handle_id:
		HANDLE_HEIGHT:
			return &"height"
		HANDLE_THICKNESS:
			return &"thickness"
		HANDLE_LOWER_RAIL_HEIGHT:
			return &"lower_rail_height"
		HANDLE_POST_WIDTH:
			return &"post_width"
	return &"height"
