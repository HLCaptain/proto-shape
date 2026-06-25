const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")
const ProtoWall = preload("res://addons/proto_shape/proto_wall/proto_wall.gd")

const HANDLE_HEIGHT := 1
const HANDLE_THICKNESS := 2
const HANDLE_LOWER_RAIL_HEIGHT := 3
const HANDLE_POST_WIDTH := 4
const HANDLE_POST_COUNT := 6
const POST_COUNT_HANDLE_UNIT := 0.25

var shape: ProtoWall = null
var gizmo_utils := ProtoGizmoUtils.new()
var editing_handle := 0
var start_value: Variant = 0.0
var end_value: Variant = 0.0

func attach_shape(node: ProtoWall) -> void:
	shape = node

func remove_shape() -> void:
	shape = null

func redraw_gizmos(gizmo, plugin) -> void:
	if shape == null or gizmo.get_node_3d() != shape:
		return

	gizmo.clear()
	var center := _get_center_position()
	var height_handle := _get_height_handle_position()
	var thickness_handle := _get_thickness_handle_position()

	var lines := PackedVector3Array()
	lines.push_back(center)
	lines.push_back(height_handle)
	lines.push_back(center + Vector3.UP * shape.height / 2.0)
	lines.push_back(thickness_handle)

	var handles := PackedVector3Array()
	var ids := []
	handles.push_back(height_handle)
	ids.push_back(HANDLE_HEIGHT)
	handles.push_back(thickness_handle)
	ids.push_back(HANDLE_THICKNESS)

	if shape.style == ProtoWall.Style.RAIL:
		var lower_rail_handle := _get_lower_rail_height_handle_position()
		lines.push_back(center)
		lines.push_back(lower_rail_handle)
		handles.push_back(lower_rail_handle)
		ids.push_back(HANDLE_LOWER_RAIL_HEIGHT)

		if shape.post_enabled:
			var post_width_handle := _get_post_width_handle_position()
			var post_center := _get_post_center_position()
			lines.push_back(post_center)
			lines.push_back(post_width_handle)
			handles.push_back(post_width_handle)
			ids.push_back(HANDLE_POST_WIDTH)

			if shape.post_placement == ProtoWall.PostPlacement.COUNT:
				var post_count_handle := _get_post_count_handle_position()
				lines.push_back(_get_post_count_base_position())
				lines.push_back(post_count_handle)
				handles.push_back(post_count_handle)
				ids.push_back(HANDLE_POST_COUNT)

	gizmo.add_lines(lines, plugin.get_material("main", gizmo))
	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), ids)

func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if shape == null or gizmo.get_node_3d() != shape:
		return

	if editing_handle == 0:
		editing_handle = handle_id
		start_value = _get_handle_value(handle_id)

	var value: Variant = _get_dragged_value(handle_id, camera, screen_pos)
	if handle_id != HANDLE_POST_COUNT:
		value = _apply_snapping(value, plugin)
	_set_handle_value(handle_id, value)
	end_value = _get_handle_value(handle_id)
	shape.update_gizmos()

func commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	if shape == null or gizmo.get_node_3d() != shape or editing_handle == 0:
		return

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

func _get_center_position() -> Vector3:
	var offset := shape.get_middle_path_offset()
	var center := shape.get_path_point(offset)
	center += shape.get_wall_side_axis(offset) * shape.get_side_center_offset(shape.thickness)
	return center

func _get_height_handle_position() -> Vector3:
	var offset := shape.get_middle_path_offset()
	return _get_center_position() + shape.get_wall_up_axis(offset) * shape.height

func _get_thickness_handle_position() -> Vector3:
	var offset := shape.get_middle_path_offset()
	var point := shape.get_path_point(offset)
	var side_axis := shape.get_wall_side_axis(offset)
	return point + side_axis * shape.get_side_outer_offset(shape.thickness) + shape.get_wall_up_axis(offset) * shape.height / 2.0

func _get_lower_rail_height_handle_position() -> Vector3:
	var offset := shape.get_middle_path_offset()
	return _get_center_position() + shape.get_wall_up_axis(offset) * shape.lower_rail_height

func _get_post_center_position() -> Vector3:
	var offset := shape.get_middle_path_offset()
	return _get_center_position() + shape.get_wall_up_axis(offset) * shape.height / 2.0

func _get_post_width_handle_position() -> Vector3:
	var offset := shape.get_middle_path_offset()
	return _get_post_center_position() + shape.get_path_forward(offset) * shape.post_width / 2.0

func _get_post_count_base_position() -> Vector3:
	var offset := shape.get_middle_path_offset()
	return _get_center_position() + shape.get_wall_up_axis(offset) * shape.height

func _get_post_count_handle_position() -> Vector3:
	var offset := shape.get_middle_path_offset()
	return _get_post_count_base_position() + shape.get_wall_up_axis(offset) * shape.post_count * POST_COUNT_HANDLE_UNIT

func _get_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> Variant:
	match handle_id:
		HANDLE_HEIGHT:
			var axis := shape.get_wall_up_axis(shape.get_middle_path_offset())
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_height_handle_position(), axis, shape)
			return max(ProtoWall.MIN_DIMENSION, (offset - _get_center_position()).dot(axis))
		HANDLE_THICKNESS:
			var path_offset := shape.get_middle_path_offset()
			var side_axis := shape.get_wall_side_axis(path_offset)
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_thickness_handle_position(), side_axis, shape)
			var side_distance := (offset - shape.get_path_point(path_offset)).dot(side_axis)
			match shape.side:
				ProtoWall.WallSide.LEFT:
					return max(ProtoWall.MIN_DIMENSION, -side_distance)
				ProtoWall.WallSide.RIGHT:
					return max(ProtoWall.MIN_DIMENSION, side_distance)
			return max(ProtoWall.MIN_DIMENSION, abs(side_distance) * 2.0)
		HANDLE_LOWER_RAIL_HEIGHT:
			var axis := shape.get_wall_up_axis(shape.get_middle_path_offset())
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_lower_rail_height_handle_position(), axis, shape)
			return max(ProtoWall.MIN_DIMENSION, (offset - _get_center_position()).dot(axis))
		HANDLE_POST_WIDTH:
			var path_offset := shape.get_middle_path_offset()
			var forward := shape.get_path_forward(path_offset)
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_post_width_handle_position(), forward, shape)
			var forward_distance := (offset - _get_post_center_position()).dot(forward)
			return max(ProtoWall.MIN_DIMENSION, forward_distance * 2.0)
		HANDLE_POST_COUNT:
			var axis := shape.get_wall_up_axis(shape.get_middle_path_offset())
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_post_count_handle_position(), axis, shape)
			var count_value := roundi((offset - _get_post_count_base_position()).dot(axis) / POST_COUNT_HANDLE_UNIT)
			return max(1, count_value)
	return ProtoWall.MIN_DIMENSION

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
		HANDLE_POST_COUNT:
			return shape.post_count
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
		HANDLE_POST_COUNT:
			shape.post_count = value

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
		HANDLE_POST_COUNT:
			return &"post_count"
	return &"height"
