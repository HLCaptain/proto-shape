const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")
const ExampleDirectionalBeam = preload("res://addons/proto_shape/proto_gizmo/examples/directional_beam/example_directional_beam.gd")

const HANDLE_LENGTH := 1
const HANDLE_HEIGHT := 2
const HANDLE_THICKNESS := 3
const MIN_ARROW_VISUAL_LENGTH := 0.25
const MAX_ARROW_VISUAL_LENGTH := 0.75

var shape: ExampleDirectionalBeam = null
var gizmo_utils := ProtoGizmoUtils.new()
var editing_handle := 0
var start_value := 0.0
var end_value := 0.0
var drag_start_pointer_value := 0.0

func attach_shape(node: ExampleDirectionalBeam) -> void:
	shape = node

func remove_shape() -> void:
	shape = null

func redraw_gizmos(gizmo, plugin) -> void:
	if gizmo.get_node_3d() != shape:
		return

	gizmo.clear()
	var length_handle := _get_length_handle_position()
	var height_handle := _get_height_handle_position()
	var thickness_handle := _get_thickness_handle_position()

	_add_handle_arrow(gizmo, plugin, HANDLE_LENGTH, length_handle, shape.get_direction_axis())
	_add_handle_arrow(gizmo, plugin, HANDLE_HEIGHT, height_handle, Vector3.UP)
	_add_handle_arrow(gizmo, plugin, HANDLE_THICKNESS, thickness_handle, shape.get_right_axis())

	var handles := PackedVector3Array()
	handles.push_back(length_handle)
	handles.push_back(height_handle)
	handles.push_back(thickness_handle)

	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), [HANDLE_LENGTH, HANDLE_HEIGHT, HANDLE_THICKNESS])

func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if gizmo.get_node_3d() != shape:
		return

	if editing_handle == 0:
		if not begin_arrow_drag(plugin, handle_id, camera, screen_pos):
			return
		drag_start_pointer_value = start_value
	set_arrow_drag(plugin, handle_id, camera, screen_pos)

func get_arrow_drag_segments(_plugin) -> Array:
	return _get_arrow_segments()

func begin_arrow_drag(_plugin, handle_id: int, camera: Camera3D, screen_pos: Vector2) -> bool:
	if editing_handle != 0:
		return false
	var pointer_value: Variant = _get_dragged_value(handle_id, camera, screen_pos)
	if pointer_value == null:
		return false
	editing_handle = handle_id
	start_value = _get_handle_value(handle_id)
	drag_start_pointer_value = pointer_value
	end_value = start_value
	return true

func set_arrow_drag(plugin, handle_id: int, camera: Camera3D, screen_pos: Vector2) -> void:
	var value: Variant = _get_relative_dragged_value(handle_id, camera, screen_pos)
	if value == null:
		return
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
	undo_redo.create_action("Edit directional beam %s" % property_name, 0, shape, true)
	undo_redo.add_do_property(shape, property_name, end_value)
	undo_redo.add_undo_property(shape, property_name, start_value)
	undo_redo.commit_action()
	editing_handle = 0

func _get_handle_position(handle_id: int) -> Vector3:
	match handle_id:
		HANDLE_LENGTH:
			return _get_length_handle_position()
		HANDLE_HEIGHT:
			return _get_height_handle_position()
		HANDLE_THICKNESS:
			return _get_thickness_handle_position()
	return Vector3.ZERO

func _get_center_position() -> Vector3:
	return shape.get_direction_axis() * shape.length / 2.0 + Vector3(0, shape.height / 2.0, 0)

func _get_length_handle_position() -> Vector3:
	return shape.get_direction_axis() * shape.length + Vector3(0, shape.height / 2.0, 0)

func _get_height_handle_position() -> Vector3:
	return shape.get_direction_axis() * shape.length / 2.0 + Vector3(0, shape.height, 0)

func _get_thickness_handle_position() -> Vector3:
	return _get_center_position() + shape.get_right_axis() * shape.thickness / 2.0

func _get_arrow_segments() -> Array:
	var segments := []
	for handle_id in [HANDLE_LENGTH, HANDLE_HEIGHT, HANDLE_THICKNESS]:
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
		HANDLE_LENGTH:
			return shape.get_direction_axis()
		HANDLE_HEIGHT:
			return Vector3.UP
		HANDLE_THICKNESS:
			return shape.get_right_axis()
	return Vector3.ZERO

func _add_handle_arrow(gizmo, plugin, handle_id: int, base_position: Vector3, direction: Vector3) -> void:
	if plugin.has_method("should_draw_mesh_guides") and not plugin.should_draw_mesh_guides(gizmo):
		return

	var material: Material = plugin.get_material("main", gizmo)
	if plugin.has_method("get_handle_arrow_material"):
		material = plugin.get_handle_arrow_material(gizmo, handle_id)
	gizmo_utils.add_arrow_mesh(gizmo, material, base_position, base_position + direction.normalized() * _get_arrow_visual_length())

func _get_arrow_visual_length() -> float:
	return clamp(max(shape.length, max(shape.height, shape.thickness)) * 0.2, MIN_ARROW_VISUAL_LENGTH, MAX_ARROW_VISUAL_LENGTH)

func is_handle_highlighted(_gizmo, _plugin, handle_id: int, _secondary: bool) -> bool:
	return editing_handle == handle_id

func _get_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> Variant:
	match handle_id:
		HANDLE_LENGTH:
			var direction := shape.get_direction_axis()
			var offset: Variant = gizmo_utils.get_handle_offset(camera, screen_pos, _get_length_handle_position(), direction, shape)
			return offset.dot(direction) if offset is Vector3 else null
		HANDLE_HEIGHT:
			var offset: Variant = gizmo_utils.get_handle_offset(camera, screen_pos, _get_height_handle_position(), Vector3.UP, shape)
			return offset.y if offset is Vector3 else null
		HANDLE_THICKNESS:
			var right := shape.get_right_axis()
			var offset: Variant = gizmo_utils.get_handle_offset(camera, screen_pos, _get_thickness_handle_position(), right, shape)
			return (offset - _get_center_position()).dot(right) * 2.0 if offset is Vector3 else null
	return null

func _get_relative_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> Variant:
	var pointer_value: Variant = _get_dragged_value(handle_id, camera, screen_pos)
	return null if pointer_value == null else max(0.001, start_value + pointer_value - drag_start_pointer_value)

func _apply_snapping(value: float, plugin) -> float:
	if plugin.fine_snapping:
		return gizmo_utils.snap_to_grid(value, 0.1)
	if plugin.snapping:
		return gizmo_utils.snap_to_grid(value, 1.0)
	return value

func _get_handle_value(handle_id: int) -> float:
	match handle_id:
		HANDLE_LENGTH:
			return shape.length
		HANDLE_HEIGHT:
			return shape.height
		HANDLE_THICKNESS:
			return shape.thickness
	return 0.0

func _set_handle_value(handle_id: int, value: float) -> void:
	match handle_id:
		HANDLE_LENGTH:
			shape.length = value
		HANDLE_HEIGHT:
			shape.height = value
		HANDLE_THICKNESS:
			shape.thickness = value

func _get_property_name(handle_id: int) -> StringName:
	match handle_id:
		HANDLE_LENGTH:
			return &"length"
		HANDLE_HEIGHT:
			return &"height"
		HANDLE_THICKNESS:
			return &"thickness"
	return &"length"
