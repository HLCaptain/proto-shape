@tool
extends Node3D

const ProtoGizmoWrapper = preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")

const HANDLE_RADIUS := 1
const HANDLE_HEIGHT := 2

var _radius := 1.0
var _height := 1.5

@export var radius: float: set = set_radius, get = get_radius
@export var height: float: set = set_height, get = get_height

var cylinder: CSGCylinder3D = null
var gizmo_utils = null
var editing_handle := 0
var start_value := 0.0
var end_value := 0.0

func get_radius() -> float:
	return _radius

func get_height() -> float:
	return _height

func set_radius(value: float) -> void:
	_radius = max(0.001, value)
	refresh_shape()
	update_gizmos()

func set_height(value: float) -> void:
	_height = max(0.001, value)
	refresh_shape()
	update_gizmos()

func refresh_shape() -> void:
	if not is_inside_tree():
		return

	if cylinder == null:
		cylinder = CSGCylinder3D.new()
		cylinder.name = "GeneratedVolume"
		cylinder.sides = 24
		cylinder.use_collision = true
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.4, 1.0, 0.35, 0.7)
		cylinder.material = material
		add_child(cylinder)

	cylinder.radius = radius
	cylinder.height = height
	cylinder.position = Vector3(0, height / 2.0, 0)

func _enter_tree() -> void:
	refresh_shape()
	if Engine.is_editor_hint():
		var ProtoGizmoUtils = load("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")
		gizmo_utils = ProtoGizmoUtils.new()
	if Engine.is_editor_hint() and get_parent() is ProtoGizmoWrapper:
		var parent: ProtoGizmoWrapper = get_parent()
		if not parent.redraw_gizmos_for_child_signal.is_connected(redraw_gizmos):
			parent.redraw_gizmos_for_child_signal.connect(redraw_gizmos)
		if not parent.set_handle_for_child_signal.is_connected(set_handle):
			parent.set_handle_for_child_signal.connect(set_handle)
		if not parent.commit_handle.is_connected(commit_handle):
			parent.commit_handle.connect(commit_handle)

func _exit_tree() -> void:
	if Engine.is_editor_hint() and get_parent() is ProtoGizmoWrapper:
		var parent: ProtoGizmoWrapper = get_parent()
		if parent.redraw_gizmos_for_child_signal.is_connected(redraw_gizmos):
			parent.redraw_gizmos_for_child_signal.disconnect(redraw_gizmos)
		if parent.set_handle_for_child_signal.is_connected(set_handle):
			parent.set_handle_for_child_signal.disconnect(set_handle)
		if parent.commit_handle.is_connected(commit_handle):
			parent.commit_handle.disconnect(commit_handle)
	if cylinder != null:
		remove_child(cylinder)
		cylinder.queue_free()
		cylinder = null
	gizmo_utils = null

func redraw_gizmos(gizmo, plugin) -> void:
	if gizmo.get_node_3d() != self:
		return

	gizmo.clear()
	var center := Vector3(0, height / 2.0, 0)
	var radius_handle := _get_radius_handle_position()
	var height_handle := _get_height_handle_position()

	var lines := PackedVector3Array()
	lines.push_back(center)
	lines.push_back(radius_handle)
	lines.push_back(center)
	lines.push_back(height_handle)

	var handles := PackedVector3Array()
	handles.push_back(radius_handle)
	handles.push_back(height_handle)

	gizmo.add_lines(lines, plugin.get_material("main", gizmo))
	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), [HANDLE_RADIUS, HANDLE_HEIGHT])

func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if gizmo.get_node_3d() != self:
		return

	if editing_handle == 0:
		editing_handle = handle_id
		start_value = _get_handle_value(handle_id)

	var value := _get_dragged_value(handle_id, camera, screen_pos)
	value = _apply_snapping(value, plugin)
	_set_handle_value(handle_id, value)
	end_value = value
	update_gizmos()

func commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	if gizmo.get_node_3d() != self or editing_handle == 0:
		return

	if cancel:
		_set_handle_value(editing_handle, start_value)
		update_gizmos()
		editing_handle = 0
		return

	var property_name := _get_property_name(editing_handle)
	var undo_redo = plugin.undo_redo
	undo_redo.create_action("Edit wrapped volume %s" % property_name, 0, self, true)
	undo_redo.add_do_property(self, property_name, end_value)
	undo_redo.add_undo_property(self, property_name, start_value)
	undo_redo.commit_action()
	editing_handle = 0

func _get_radius_handle_position() -> Vector3:
	return Vector3(radius, height / 2.0, 0)

func _get_height_handle_position() -> Vector3:
	return Vector3(0, height, 0)

func _get_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> float:
	match handle_id:
		HANDLE_RADIUS:
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_radius_handle_position(), Vector3.RIGHT, self)
			return max(0.001, offset.x)
		HANDLE_HEIGHT:
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_height_handle_position(), Vector3.UP, self)
			return max(0.001, offset.y)
	return 0.001

func _apply_snapping(value: float, plugin) -> float:
	if plugin.fine_snapping:
		return gizmo_utils.snap_to_grid(value, 0.1)
	if plugin.snapping:
		return gizmo_utils.snap_to_grid(value, 1.0)
	return value

func _get_handle_value(handle_id: int) -> float:
	match handle_id:
		HANDLE_RADIUS:
			return radius
		HANDLE_HEIGHT:
			return height
	return 0.0

func _set_handle_value(handle_id: int, value: float) -> void:
	match handle_id:
		HANDLE_RADIUS:
			radius = value
		HANDLE_HEIGHT:
			height = value

func _get_property_name(handle_id: int) -> StringName:
	match handle_id:
		HANDLE_RADIUS:
			return &"radius"
		HANDLE_HEIGHT:
			return &"height"
	return &"radius"
