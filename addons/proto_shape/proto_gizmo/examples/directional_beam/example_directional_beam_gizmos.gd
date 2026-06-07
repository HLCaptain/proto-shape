const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")
const ExampleDirectionalBeam = preload("res://addons/proto_shape/proto_gizmo/examples/directional_beam/example_directional_beam.gd")

const HANDLE_LENGTH := 1
const HANDLE_HEIGHT := 2
const HANDLE_THICKNESS := 3

var shape: ExampleDirectionalBeam = null
var gizmo_utils := ProtoGizmoUtils.new()
var editing_handle := 0
var start_value := 0.0
var end_value := 0.0

func attach_shape(node: ExampleDirectionalBeam) -> void:
	shape = node

func remove_shape() -> void:
	shape = null

func redraw_gizmos(gizmo, plugin) -> void:
	if gizmo.get_node_3d() != shape:
		return

	gizmo.clear()
	var center := _get_center_position()
	var length_handle := _get_length_handle_position()
	var height_handle := _get_height_handle_position()
	var thickness_handle := _get_thickness_handle_position()

	var lines := PackedVector3Array()
	lines.push_back(center)
	lines.push_back(length_handle)
	lines.push_back(center)
	lines.push_back(height_handle)
	lines.push_back(center)
	lines.push_back(thickness_handle)

	var handles := PackedVector3Array()
	handles.push_back(length_handle)
	handles.push_back(height_handle)
	handles.push_back(thickness_handle)

	gizmo.add_lines(lines, plugin.get_material("main", gizmo))
	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), [HANDLE_LENGTH, HANDLE_HEIGHT, HANDLE_THICKNESS])

func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if gizmo.get_node_3d() != shape:
		return

	if editing_handle == 0:
		editing_handle = handle_id
		start_value = _get_handle_value(handle_id)

	var value := _get_dragged_value(handle_id, camera, screen_pos)
	value = _apply_snapping(value, plugin)
	_set_handle_value(handle_id, value)
	end_value = value
	shape.update_gizmos()

func commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	if gizmo.get_node_3d() != shape or editing_handle == 0:
		return

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

func _get_center_position() -> Vector3:
	return shape.get_direction_axis() * shape.length / 2.0 + Vector3(0, shape.height / 2.0, 0)

func _get_length_handle_position() -> Vector3:
	return shape.get_direction_axis() * shape.length + Vector3(0, shape.height / 2.0, 0)

func _get_height_handle_position() -> Vector3:
	return shape.get_direction_axis() * shape.length / 2.0 + Vector3(0, shape.height, 0)

func _get_thickness_handle_position() -> Vector3:
	return _get_center_position() + shape.get_right_axis() * shape.thickness / 2.0

func _get_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> float:
	match handle_id:
		HANDLE_LENGTH:
			var direction := shape.get_direction_axis()
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_length_handle_position(), direction, shape)
			return max(0.001, offset.dot(direction))
		HANDLE_HEIGHT:
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_height_handle_position(), Vector3.UP, shape)
			return max(0.001, offset.y)
		HANDLE_THICKNESS:
			var right := shape.get_right_axis()
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_thickness_handle_position(), right, shape)
			return max(0.001, (offset - _get_center_position()).dot(right) * 2.0)
	return 0.001

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
