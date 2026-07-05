const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")
const ExampleProtoBox = preload("res://addons/proto_shape/proto_gizmo/examples/provider_box/example_proto_box.gd")

const HANDLE_WIDTH := 1
const HANDLE_HEIGHT := 2
const HANDLE_DEPTH := 3
const MIN_ARROW_VISUAL_LENGTH := 0.25
const MAX_ARROW_VISUAL_LENGTH := 0.75

var shape: ExampleProtoBox = null
var gizmo_utils := ProtoGizmoUtils.new()
var editing_handle := 0
var start_value := 0.0
var end_value := 0.0
var drag_start_pointer_value := 0.0

func attach_shape(node: ExampleProtoBox) -> void:
	shape = node

func remove_shape() -> void:
	shape = null

func redraw_gizmos(gizmo, plugin) -> void:
	if gizmo.get_node_3d() != shape:
		return

	gizmo.clear()
	var width_handle := _get_width_handle_position()
	var height_handle := _get_height_handle_position()
	var depth_handle := _get_depth_handle_position()

	_add_handle_arrow(gizmo, plugin, HANDLE_WIDTH, width_handle, Vector3.RIGHT)
	_add_handle_arrow(gizmo, plugin, HANDLE_HEIGHT, height_handle, Vector3.UP)
	_add_handle_arrow(gizmo, plugin, HANDLE_DEPTH, depth_handle, Vector3.BACK)

	var handles := PackedVector3Array()
	handles.push_back(width_handle)
	handles.push_back(height_handle)
	handles.push_back(depth_handle)

	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), [HANDLE_WIDTH, HANDLE_HEIGHT, HANDLE_DEPTH])

func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if gizmo.get_node_3d() != shape:
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
	var value := _get_relative_dragged_value(handle_id, camera, screen_pos)
	value = _apply_snapping(value, plugin)
	_set_handle_value(handle_id, value)
	end_value = value
	shape.update_gizmos()

func commit_arrow_drag(plugin, _handle_id: int, cancel: bool) -> void:
	if editing_handle == 0:
		return
	_commit_current_edit(plugin, cancel)

func commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	if gizmo.get_node_3d() != shape or editing_handle == 0:
		return

	_commit_current_edit(plugin, cancel)

func _commit_current_edit(plugin, cancel: bool) -> void:
	if cancel:
		_set_handle_value(editing_handle, start_value)
		shape.update_gizmos()
		editing_handle = 0
		return

	var property_name := _get_property_name(editing_handle)
	var undo_redo: EditorUndoRedoManager = plugin.undo_redo
	undo_redo.create_action("Edit example box %s" % property_name, 0, shape, true)
	undo_redo.add_do_property(shape, property_name, end_value)
	undo_redo.add_undo_property(shape, property_name, start_value)
	undo_redo.commit_action()
	editing_handle = 0

func _get_handle_position(handle_id: int) -> Vector3:
	match handle_id:
		HANDLE_WIDTH:
			return _get_width_handle_position()
		HANDLE_HEIGHT:
			return _get_height_handle_position()
		HANDLE_DEPTH:
			return _get_depth_handle_position()
	return Vector3.ZERO

func _get_width_handle_position() -> Vector3:
	return Vector3(shape.width / 2.0, shape.height / 2.0, 0)

func _get_height_handle_position() -> Vector3:
	return Vector3(0, shape.height, 0)

func _get_depth_handle_position() -> Vector3:
	return Vector3(0, shape.height / 2.0, shape.depth / 2.0)

func _get_arrow_segments() -> Array:
	var segments := []
	for handle_id in [HANDLE_WIDTH, HANDLE_HEIGHT, HANDLE_DEPTH]:
		var direction := _get_drag_axis(handle_id)
		var from_position := _get_handle_position(handle_id)
		segments.append({
			"id": handle_id,
			"from": from_position,
			"to": from_position + direction.normalized() * _get_arrow_visual_length(),
		})
	return segments

func _get_drag_axis(handle_id: int) -> Vector3:
	match handle_id:
		HANDLE_WIDTH:
			return Vector3.RIGHT
		HANDLE_HEIGHT:
			return Vector3.UP
		HANDLE_DEPTH:
			return Vector3.BACK
	return Vector3.ZERO

func _add_handle_arrow(gizmo, plugin, handle_id: int, base_position: Vector3, direction: Vector3) -> void:
	if plugin.has_method("should_draw_mesh_guides") and not plugin.should_draw_mesh_guides(gizmo):
		return

	var material: Material = plugin.get_material("main", gizmo)
	if plugin.has_method("get_handle_arrow_material"):
		material = plugin.get_handle_arrow_material(gizmo, handle_id)
	gizmo_utils.add_arrow_mesh(gizmo, material, base_position, base_position + direction.normalized() * _get_arrow_visual_length())

func _get_arrow_visual_length() -> float:
	return clamp(max(shape.width, max(shape.height, shape.depth)) * 0.2, MIN_ARROW_VISUAL_LENGTH, MAX_ARROW_VISUAL_LENGTH)

func is_handle_highlighted(_gizmo, _plugin, handle_id: int, _secondary: bool) -> bool:
	return editing_handle == handle_id

func _get_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> float:
	match handle_id:
		HANDLE_WIDTH:
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_width_handle_position(), Vector3.RIGHT, shape)
			return max(0.001, offset.x * 2.0)
		HANDLE_HEIGHT:
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_height_handle_position(), Vector3.UP, shape)
			return max(0.001, offset.y)
		HANDLE_DEPTH:
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_depth_handle_position(), Vector3.BACK, shape)
			return max(0.001, offset.z * 2.0)
	return 0.001

func _get_relative_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> float:
	return max(0.001, start_value + _get_dragged_value(handle_id, camera, screen_pos) - drag_start_pointer_value)

func _apply_snapping(value: float, plugin) -> float:
	if plugin.fine_snapping:
		return gizmo_utils.snap_to_grid(value, 0.1)
	if plugin.snapping:
		return gizmo_utils.snap_to_grid(value, 1.0)
	return value

func _get_handle_value(handle_id: int) -> float:
	match handle_id:
		HANDLE_WIDTH:
			return shape.width
		HANDLE_HEIGHT:
			return shape.height
		HANDLE_DEPTH:
			return shape.depth
	return 0.0

func _set_handle_value(handle_id: int, value: float) -> void:
	match handle_id:
		HANDLE_WIDTH:
			shape.width = value
		HANDLE_HEIGHT:
			shape.height = value
		HANDLE_DEPTH:
			shape.depth = value

func _get_property_name(handle_id: int) -> StringName:
	match handle_id:
		HANDLE_WIDTH:
			return &"width"
		HANDLE_HEIGHT:
			return &"height"
		HANDLE_DEPTH:
			return &"depth"
	return &"width"
