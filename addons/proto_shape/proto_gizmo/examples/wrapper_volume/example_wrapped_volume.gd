@tool
extends Node3D

const ProtoGizmoWrapper = preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")

const HANDLE_RADIUS := 1
const HANDLE_HEIGHT := 2
const MIN_ARROW_VISUAL_LENGTH := 0.25
const MAX_ARROW_VISUAL_LENGTH := 0.75

const _default_radius := 1.0
const _default_height := 1.5

var _radius := _default_radius
var _height := _default_height

@export var radius: float: set = set_radius, get = get_radius
@export var height: float: set = set_height, get = get_height

var cylinder: CSGCylinder3D = null
var gizmo_utils = null
var editing_handle := 0
var start_value := 0.0
var end_value := 0.0
var drag_start_pointer_value := 0.0

func get_proto_gizmo_selection_nodes() -> Array:
	return [cylinder]

func _property_can_revert(property: StringName) -> bool:
	return property in [&"radius", &"height"]

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"radius":
			return _default_radius
		&"height":
			return _default_height
	return null

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
		if cylinder.get_parent() == self:
			remove_child(cylinder)
		cylinder.queue_free()
		cylinder = null
	gizmo_utils = null

func redraw_gizmos(gizmo, plugin) -> void:
	if gizmo.get_node_3d() != self:
		return

	gizmo.clear()
	var radius_handle := _get_radius_handle_position()
	var height_handle := _get_height_handle_position()

	_add_handle_arrow(gizmo, plugin, HANDLE_RADIUS, radius_handle, Vector3.RIGHT)
	_add_handle_arrow(gizmo, plugin, HANDLE_HEIGHT, height_handle, Vector3.UP)

	var handles := PackedVector3Array()
	handles.push_back(radius_handle)
	handles.push_back(height_handle)

	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), [HANDLE_RADIUS, HANDLE_HEIGHT])

func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if gizmo.get_node_3d() != self:
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
	update_gizmos()

func commit_arrow_drag(plugin, _handle_id: int, cancel: bool) -> void:
	if editing_handle == 0:
		return
	_commit_current_edit(plugin, cancel)

func commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	if gizmo.get_node_3d() != self or editing_handle == 0:
		return

	_commit_current_edit(plugin, cancel)

func _commit_current_edit(plugin, cancel: bool) -> void:
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

func _get_handle_position(handle_id: int) -> Vector3:
	match handle_id:
		HANDLE_RADIUS:
			return _get_radius_handle_position()
		HANDLE_HEIGHT:
			return _get_height_handle_position()
	return Vector3.ZERO

func _get_radius_handle_position() -> Vector3:
	return Vector3(radius, height / 2.0, 0)

func _get_height_handle_position() -> Vector3:
	return Vector3(0, height, 0)

func _get_arrow_segments() -> Array:
	var segments := []
	for handle_id in [HANDLE_RADIUS, HANDLE_HEIGHT]:
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
		HANDLE_RADIUS:
			return Vector3.RIGHT
		HANDLE_HEIGHT:
			return Vector3.UP
	return Vector3.ZERO

func _add_handle_arrow(gizmo, plugin, handle_id: int, base_position: Vector3, direction: Vector3) -> void:
	if plugin.has_method("should_draw_mesh_guides") and not plugin.should_draw_mesh_guides(gizmo):
		return

	var material: Material = plugin.get_material("main", gizmo)
	if plugin.has_method("get_handle_arrow_material"):
		material = plugin.get_handle_arrow_material(gizmo, handle_id)
	gizmo_utils.add_arrow_mesh(gizmo, material, base_position, base_position + direction.normalized() * _get_arrow_visual_length())

func _get_arrow_visual_length() -> float:
	return clamp(max(radius * 2.0, height) * 0.2, MIN_ARROW_VISUAL_LENGTH, MAX_ARROW_VISUAL_LENGTH)

func is_handle_highlighted(_gizmo, _plugin, handle_id: int, _secondary: bool) -> bool:
	return editing_handle == handle_id

func _get_dragged_value(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> float:
	match handle_id:
		HANDLE_RADIUS:
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_radius_handle_position(), Vector3.RIGHT, self)
			return max(0.001, offset.x)
		HANDLE_HEIGHT:
			var offset: Vector3 = gizmo_utils.get_handle_offset(camera, screen_pos, _get_height_handle_position(), Vector3.UP, self)
			return max(0.001, offset.y)
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
