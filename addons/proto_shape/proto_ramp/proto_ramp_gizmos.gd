# Implementing Gizmo
const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")
const ProtoRamp = preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")
const ProtoGizmoPlugin = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo.gd")
const depth_gizmo_id := 1
const width_gizmo_id := 2
const height_gizmo_id := 3
const fill_gizmo_id1 := 4
const fill_gizmo_id2 := 5
const MIN_ARROW_VISUAL_LENGTH := 0.25
const MAX_ARROW_VISUAL_LENGTH := 0.75
var gizmo_utils := ProtoGizmoUtils.new()
var ramp: ProtoRamp = null

var is_editing := false

func attach_ramp(node: ProtoRamp) -> void:
	ramp = node

func remove_ramp() -> void:
	_clear_edit_state()
	ramp = null

func _clear_edit_state() -> void:
	is_editing = false
	screen_pos = Vector2.ZERO
	debug_gizmo_handler_id = 0
	camera_position = Vector3.ZERO

# Snapping to grid
var snap_unit: float = 1.0
var fine_snap_unit: float = 0.1

# Debug purposes
var screen_pos: Vector2
var debug_gizmo_handler_id: int
var camera_position: Vector3

## As gizmos can only be used in the Editor, we can cast the [gizmo] to [EditorNode3DGizmo] and [plugin] to [EditorNode3DGizmoPlugin].
func redraw_gizmos(gizmo: EditorNode3DGizmo, plugin: ProtoGizmoPlugin) -> void:
	if gizmo.get_node_3d() != ramp:
		return

	gizmo.clear()
	var handle_positions := _get_handle_positions()
	for handle_id in _get_handle_ids():
		_add_handle_arrow(gizmo, plugin, handle_id, handle_positions[handle_id], _get_handle_drag_axis(handle_id))

	var handles = PackedVector3Array()
	for handle_id in _get_handle_ids():
		handles.push_back(handle_positions[handle_id])

	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), [depth_gizmo_id, width_gizmo_id, height_gizmo_id, fill_gizmo_id1, fill_gizmo_id2])

	# Adding debug lines while a handle is being edited
	if is_editing:
		var grid_size_modifier = 1.0
		# Grid size is always the max of the two other dimensions
		match debug_gizmo_handler_id:
			depth_gizmo_id:
				# Setting depth
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_width())
				var local_offset_axis = Vector3(0, 0, 1)
				gizmo_utils.debug_draw_handle_grid(camera_position, screen_pos, handle_positions[depth_gizmo_id], local_offset_axis, ramp, gizmo, plugin, grid_size_modifier)
			width_gizmo_id:
				# Setting width
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_true_depth())
				var local_offset_axis = Vector3(1, 0, 0)
				gizmo_utils.debug_draw_handle_grid(camera_position, screen_pos, handle_positions[width_gizmo_id], local_offset_axis, ramp, gizmo, plugin, grid_size_modifier)
			height_gizmo_id:
				# Setting height
				grid_size_modifier = max(ramp.get_width(), ramp.get_true_depth())
				var local_offset_axis = Vector3(0, 1, 0)
				gizmo_utils.debug_draw_handle_grid(camera_position, screen_pos, handle_positions[height_gizmo_id], local_offset_axis, ramp, gizmo, plugin, grid_size_modifier)
			fill_gizmo_id1:
				# Setting fill 1
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_true_depth())
				var local_plane_normal = Vector3(1, 0, 0)
				var local_offset_axis = _get_fill_max_offset().normalized()
				local_offset_axis.z = -local_offset_axis.z
				gizmo_utils.debug_draw_handle_grid_on_plane(handle_positions[fill_gizmo_id1], local_offset_axis, local_plane_normal, ramp, gizmo, plugin, grid_size_modifier)
			fill_gizmo_id2:
				# Setting fill 2
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_true_depth())
				var local_plane_normal = Vector3(1, 0, 0)
				var local_offset_axis = _get_fill_max_offset().normalized()
				local_offset_axis.z = -local_offset_axis.z
				gizmo_utils.debug_draw_handle_grid_on_plane(handle_positions[fill_gizmo_id2], local_offset_axis, local_plane_normal, ramp, gizmo, plugin, grid_size_modifier)

var start_offset := 0.0
var end_offset := 0.0
var start_value := 0.0
var end_value := 0.0
var drag_start_pointer_offset := 0.0

func set_handle(
	gizmo: EditorNode3DGizmo,
	plugin: ProtoGizmoPlugin,
	handle_id: int,
	secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2) -> void:
	# Set debug parameters for redraw
	var child := gizmo.get_node_3d()
	if child != ramp:
		return

	if !is_editing:
		if not begin_arrow_drag(plugin, handle_id, camera, screen_pos):
			return
		drag_start_pointer_offset = start_offset
	set_arrow_drag(plugin, handle_id, camera, screen_pos)

func get_arrow_drag_segments(_gizmo_plugin: ProtoGizmoPlugin) -> Array:
	return _get_handle_arrow_segments()

func begin_arrow_drag(_plugin: ProtoGizmoPlugin, handle_id: int, camera: Camera3D, screen_pos: Vector2) -> bool:
	if is_editing:
		return false
	var pointer_offset: Variant = _get_screen_handle_offset(handle_id, camera, screen_pos)
	if pointer_offset == null:
		return false
	self.screen_pos = screen_pos
	self.camera_position = camera.global_position
	debug_gizmo_handler_id = handle_id
	start_offset = _get_current_handle_offset(handle_id)
	start_value = _get_handle_value(handle_id)
	drag_start_pointer_offset = pointer_offset
	end_offset = start_offset
	end_value = start_value
	is_editing = true
	return true

func set_arrow_drag(plugin: ProtoGizmoPlugin, handle_id: int, camera: Camera3D, screen_pos: Vector2) -> void:
	if not _set_dragged_handle_from_screen(plugin, handle_id, camera, screen_pos):
		return
	self.screen_pos = screen_pos
	self.camera_position = camera.global_position
	ramp.update_gizmos()

func commit_arrow_drag(plugin: ProtoGizmoPlugin, handle_id: int, cancel: bool) -> void:
	if not is_editing:
		return
	_commit_current_edit(plugin, handle_id, cancel)

func _set_dragged_handle_from_screen(plugin: ProtoGizmoPlugin, handle_id: int, camera: Camera3D, screen_pos: Vector2) -> bool:
	var pointer_offset: Variant = _get_screen_handle_offset(handle_id, camera, screen_pos)
	if pointer_offset == null:
		return false
	end_offset = start_offset + pointer_offset - drag_start_pointer_offset
	if not is_equal_approx(end_offset, start_offset):
		if plugin.fine_snapping:
			end_offset = gizmo_utils.snap_to_grid(end_offset, fine_snap_unit)
		elif plugin.snapping:
			end_offset = gizmo_utils.snap_to_grid(end_offset, snap_unit)
	if is_equal_approx(end_offset, start_offset):
		if end_value != start_value:
			_set_handle_value(handle_id, start_value)
		end_offset = start_offset
		end_value = start_value
		return true
	match handle_id:
		depth_gizmo_id:
			ramp.depth = _get_ramp_depth(end_offset)
		width_gizmo_id:
			ramp.width = _get_ramp_width(end_offset)
		height_gizmo_id:
			ramp.height = _get_ramp_height(end_offset)
		fill_gizmo_id1, fill_gizmo_id2:
			end_offset = clamp(end_offset, 0.0, 1.0)
			ramp.fill = end_offset
		_:
			return false
	end_value = _get_handle_value(handle_id)
	end_offset = _get_current_handle_offset(handle_id)
	if is_equal_approx(end_offset, start_offset):
		_set_handle_value(handle_id, start_value)
		end_offset = start_offset
		end_value = start_value
	return true

func _get_screen_handle_offset(handle_id: int, camera: Camera3D, screen_pos: Vector2) -> Variant:
	match handle_id:
		depth_gizmo_id:
			return _get_depth_handle_offset(camera, screen_pos)
		width_gizmo_id:
			return _get_width_handle_offset(camera, screen_pos)
		height_gizmo_id:
			return _get_height_handle_offset(camera, screen_pos)
		fill_gizmo_id1:
			return _get_fill_handle_offset(camera, screen_pos, Vector3(-ramp.width / 2, 0, 0))
		fill_gizmo_id2:
			return _get_fill_handle_offset(camera, screen_pos, Vector3(ramp.width / 2, 0, 0))
	return null

func _get_depth_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2) -> Variant:
	var local_offset_axis = Vector3(0, 0, 1)
	var gizmo_position = Vector3(0, ramp.get_true_height() / 2, ramp.get_true_depth()) + ramp.get_anchor_offset(ramp.anchor)
	var handle_offset: Variant = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, local_offset_axis, ramp)
	if not (handle_offset is Vector3):
		return null
	return handle_offset.z

func _get_width_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2) -> Variant:
	var local_offset_axis = Vector3(1, 0, 0)
	var gizmo_position = Vector3(ramp.width / 2, ramp.get_true_height() / 2, ramp.get_true_depth() / 2) + ramp.get_anchor_offset(ramp.anchor)
	var handle_offset: Variant = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, local_offset_axis, ramp)
	if not (handle_offset is Vector3):
		return null
	return handle_offset.x

func _get_height_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2) -> Variant:
	var local_offset_axis = Vector3(0, 1, 0)
	var gizmo_position = Vector3(0, ramp.get_true_height(), ramp.get_true_depth() / 2) + ramp.get_anchor_offset(ramp.anchor)
	var handle_offset: Variant = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, local_offset_axis, ramp)
	if not (handle_offset is Vector3):
		return null
	return handle_offset.y

func _get_fill_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2,
	gizmo_position_offset: Vector3) -> Variant:
	var fill_gizmo_axis := _get_fill_max_offset()
	fill_gizmo_axis.z = ramp.get_true_depth() - fill_gizmo_axis.z
	var fill_gizmo_offset := fill_gizmo_axis * (1 - ramp.fill)
	var gizmo_position := Vector3(0, fill_gizmo_offset.y, fill_gizmo_offset.z) + ramp.get_anchor_offset(ramp.anchor) + gizmo_position_offset
	var local_plane_normal := Vector3(1, 0, 0)
	var handle_offset: Variant = gizmo_utils.get_handle_offset_by_plane(camera, screen_pos, gizmo_position, local_plane_normal, ramp)
	if not (handle_offset is Vector3):
		return null
	var gizmo_base_position := Vector3(0, 0, ramp.get_true_depth())
	handle_offset -= gizmo_base_position
	var gizmo_max_position := fill_gizmo_axis - gizmo_base_position
	gizmo_max_position.x = 0
	if gizmo_max_position.length_squared() <= 0.000001:
		return null
	handle_offset -= ramp.get_anchor_offset(ramp.anchor)
	handle_offset.x = 0
	return 1.0 - handle_offset.dot(gizmo_max_position) / gizmo_max_position.length_squared()

func _get_ramp_width(offset: float) -> float:
	# If anchor is on the left, offset is negative
	# If anchor is not centered, offset is divided by 2
	match ramp.anchor:
		ProtoRamp.Anchor.BOTTOM_LEFT:
			offset = -offset / 2
		ProtoRamp.Anchor.TOP_LEFT:
			offset = -offset / 2
		ProtoRamp.Anchor.BASE_LEFT:
			offset = -offset / 2
		ProtoRamp.Anchor.BOTTOM_RIGHT:
			offset = offset / 2
		ProtoRamp.Anchor.TOP_RIGHT:
			offset = offset / 2
		ProtoRamp.Anchor.BASE_RIGHT:
			offset = offset / 2
	return offset * 2

func _get_ramp_depth(offset: float) -> float:
	if ramp.calculation == ProtoRamp.Calculation.STEP_DIMENSIONS and ramp.type == ProtoRamp.Type.STAIRCASE:
		offset = offset / ramp.steps
	# If anchor is on the back, offset is negative
	match ramp.anchor:
		ProtoRamp.Anchor.BASE_CENTER:
			offset = -offset
		ProtoRamp.Anchor.BASE_RIGHT:
			offset = -offset
		ProtoRamp.Anchor.BASE_LEFT:
			offset = -offset
		ProtoRamp.Anchor.TOP_CENTER:
			offset = -offset
		ProtoRamp.Anchor.TOP_RIGHT:
			offset = -offset
		ProtoRamp.Anchor.TOP_LEFT:
			offset = -offset
	return offset

func _get_ramp_height(offset: float) -> float:
	# If anchor is TOP, offset is negative
	if ramp.calculation == ProtoRamp.Calculation.STEP_DIMENSIONS and ramp.type == ProtoRamp.Type.STAIRCASE:
		offset = offset / ramp.steps
	match ramp.anchor:
		ProtoRamp.Anchor.TOP_LEFT:
			offset = -offset
		ProtoRamp.Anchor.TOP_CENTER:
			offset = -offset
		ProtoRamp.Anchor.TOP_RIGHT:
			offset = -offset
	return offset

func _get_fill_max_offset() -> Vector3:
	var A := Vector2(0, ramp.get_true_height())
	var B := Vector2(ramp.get_true_depth(), 0)
	var fill_gizmo_base_position := Vector2(0, 0)
	var dir := (B - A).normalized()
	var t := (fill_gizmo_base_position - A).dot(dir)
	var fill_gizmo_hypotenuse_projection := A + dir * t
	var projection_vector := fill_gizmo_hypotenuse_projection - fill_gizmo_base_position
	return Vector3(0, projection_vector.y, projection_vector.x)

func _get_handle_ids() -> Array:
	return [depth_gizmo_id, width_gizmo_id, height_gizmo_id, fill_gizmo_id1, fill_gizmo_id2]

func _get_handle_positions() -> Dictionary:
	var true_depth: float = ramp.get_true_depth()
	var true_height: float = ramp.get_true_height()
	var anchor_offset: Vector3 = ramp.get_anchor_offset(ramp.anchor)
	var fill: float = ramp.get_fill()
	var depth_gizmo_position := Vector3(0, true_height / 2, true_depth) + anchor_offset
	var width_gizmo_position := Vector3(ramp.width / 2, true_height / 2, true_depth / 2) + anchor_offset
	var height_gizmo_position := Vector3(0, true_height, true_depth / 2) + anchor_offset

	# Calculate perpendicular line points for hypotenuse and the offset
	var fill_gizmo_hypotenuse_projection := _get_fill_max_offset() * (1 - fill)
	var fill_gizmo_position1 := Vector3(-ramp.width / 2, fill_gizmo_hypotenuse_projection.y, true_depth - fill_gizmo_hypotenuse_projection.z) + anchor_offset
	var fill_gizmo_position2 := Vector3(ramp.width / 2, fill_gizmo_hypotenuse_projection.y, true_depth - fill_gizmo_hypotenuse_projection.z) + anchor_offset

	# When on the left, width gizmo is on the right
	# When in the back (top, base), depth gizmo is on the front
	# When on the top, height gizmo is on the bottom
	# Don't offset fill gizmo positions
	match ramp.anchor:
		ProtoRamp.Anchor.BOTTOM_LEFT:
			width_gizmo_position.x = -ramp.width
		ProtoRamp.Anchor.TOP_LEFT:
			width_gizmo_position.x = -ramp.width
			depth_gizmo_position.z = -true_depth
			height_gizmo_position.y = -true_height
		ProtoRamp.Anchor.BASE_LEFT:
			width_gizmo_position.x = -ramp.width
			depth_gizmo_position.z = -true_depth
		ProtoRamp.Anchor.BASE_CENTER:
			depth_gizmo_position.z = -true_depth
		ProtoRamp.Anchor.BASE_RIGHT:
			depth_gizmo_position.z = -true_depth
		ProtoRamp.Anchor.TOP_RIGHT:
			depth_gizmo_position.z = -true_depth
			height_gizmo_position.y = -true_height
		ProtoRamp.Anchor.TOP_CENTER:
			depth_gizmo_position.z = -true_depth
			height_gizmo_position.y = -true_height

	return {
		depth_gizmo_id: depth_gizmo_position,
		width_gizmo_id: width_gizmo_position,
		height_gizmo_id: height_gizmo_position,
		fill_gizmo_id1: fill_gizmo_position1,
		fill_gizmo_id2: fill_gizmo_position2,
	}

func _get_handle_arrow_segments() -> Array:
	var segments := []
	var handle_positions := _get_handle_positions()
	for handle_id in _get_handle_ids():
		var direction := _get_handle_drag_axis(handle_id)
		if direction.length_squared() <= 0.000001:
			continue

		var from_position: Vector3 = handle_positions[handle_id]
		segments.append({
			"id": handle_id,
			"from": from_position,
			"to": from_position + direction.normalized() * _get_arrow_visual_length(),
		})
	return segments

func _add_handle_arrow(gizmo: EditorNode3DGizmo, plugin: ProtoGizmoPlugin, handle_id: int, base_position: Vector3, direction: Vector3) -> void:
	if not plugin.should_draw_mesh_guides(gizmo):
		return
	if direction.length_squared() <= 0.000001:
		return

	var material := plugin.get_handle_arrow_material(gizmo, handle_id)
	gizmo_utils.add_arrow_mesh(gizmo, material, base_position, base_position + direction.normalized() * _get_arrow_visual_length())

func _get_arrow_visual_length() -> float:
	return clamp(max(ramp.width, max(ramp.get_true_depth(), ramp.get_true_height())) * 0.2, MIN_ARROW_VISUAL_LENGTH, MAX_ARROW_VISUAL_LENGTH)

func _get_depth_drag_axis() -> Vector3:
	match ramp.anchor:
		ProtoRamp.Anchor.BASE_CENTER, ProtoRamp.Anchor.BASE_LEFT, ProtoRamp.Anchor.BASE_RIGHT, ProtoRamp.Anchor.TOP_CENTER, ProtoRamp.Anchor.TOP_LEFT, ProtoRamp.Anchor.TOP_RIGHT:
			return Vector3(0, 0, -1)
	return Vector3(0, 0, 1)

func _get_width_drag_axis() -> Vector3:
	match ramp.anchor:
		ProtoRamp.Anchor.BOTTOM_LEFT, ProtoRamp.Anchor.TOP_LEFT, ProtoRamp.Anchor.BASE_LEFT:
			return Vector3(-1, 0, 0)
	return Vector3(1, 0, 0)

func _get_height_drag_axis() -> Vector3:
	match ramp.anchor:
		ProtoRamp.Anchor.TOP_LEFT, ProtoRamp.Anchor.TOP_CENTER, ProtoRamp.Anchor.TOP_RIGHT:
			return Vector3(0, -1, 0)
	return Vector3(0, 1, 0)

func _get_fill_drag_axis() -> Vector3:
	var axis := _get_fill_max_offset().normalized()
	axis.z = -axis.z
	return -axis

func _get_handle_drag_axis(handle_id: int) -> Vector3:
	match handle_id:
		depth_gizmo_id:
			return _get_depth_drag_axis()
		width_gizmo_id:
			return _get_width_drag_axis()
		height_gizmo_id:
			return _get_height_drag_axis()
		fill_gizmo_id1, fill_gizmo_id2:
			return _get_fill_drag_axis()
	return Vector3.ZERO

func _get_current_handle_offset(handle_id: int) -> float:
	var handle_positions := _get_handle_positions()
	match handle_id:
		depth_gizmo_id:
			return handle_positions[handle_id].z
		width_gizmo_id:
			return handle_positions[handle_id].x
		height_gizmo_id:
			return handle_positions[handle_id].y
		fill_gizmo_id1, fill_gizmo_id2:
			return ramp.fill
	return 0.0

func _get_handle_value(handle_id: int) -> float:
	match handle_id:
		depth_gizmo_id:
			return ramp.depth
		width_gizmo_id:
			return ramp.width
		height_gizmo_id:
			return ramp.height
		fill_gizmo_id1, fill_gizmo_id2:
			return ramp.fill
	return 0.0

func _set_handle_value(handle_id: int, value: float) -> void:
	match handle_id:
		depth_gizmo_id:
			ramp.depth = value
		width_gizmo_id:
			ramp.width = value
		height_gizmo_id:
			ramp.height = value
		fill_gizmo_id1, fill_gizmo_id2:
			ramp.fill = value

func is_handle_highlighted(_gizmo: EditorNode3DGizmo, _plugin: ProtoGizmoPlugin, handle_id: int, _secondary: bool) -> bool:
	return is_editing and debug_gizmo_handler_id == handle_id

func _commit_current_edit(plugin: ProtoGizmoPlugin, handle_id: int, cancel: bool) -> void:
	var property_name: StringName
	var action_name: String
	match handle_id:
		depth_gizmo_id:
			property_name = &"depth"
			action_name = "Edit ramp depth"
		width_gizmo_id:
			property_name = &"width"
			action_name = "Edit ramp width"
		height_gizmo_id:
			property_name = &"height"
			action_name = "Edit ramp height"
		fill_gizmo_id1, fill_gizmo_id2:
			property_name = &"fill"
			action_name = "Edit ramp fill"
		_:
			_clear_edit_state()
			if is_instance_valid(ramp):
				ramp.update_gizmos()
			return

	_clear_edit_state()
	if cancel:
		_set_handle_value(handle_id, start_value)
		ramp.update_gizmos()
		return

	if is_equal_approx(end_offset, start_offset):
		if _get_handle_value(handle_id) != start_value:
			_set_handle_value(handle_id, start_value)
		ramp.update_gizmos()
		return
	if end_value == start_value:
		ramp.update_gizmos()
		return

	var undo_redo := plugin.undo_redo
	undo_redo.create_action(action_name, 0, ramp, true)
	undo_redo.add_do_property(ramp, property_name, end_value)
	undo_redo.add_undo_property(ramp, property_name, start_value)
	undo_redo.commit_action()

func commit_handle(
	gizmo: EditorNode3DGizmo,
	plugin: ProtoGizmoPlugin,
	handle_id: int,
	secondary: bool,
	restore: Variant,
	cancel: bool) -> void:
	if gizmo.get_node_3d() != ramp or not is_editing:
		return

	_commit_current_edit(plugin, handle_id, cancel)
