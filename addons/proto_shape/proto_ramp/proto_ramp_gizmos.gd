# Implementing Gizmo
const ProtoGizmoWrapper = preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")
const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")
const ProtoRamp = preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")
const ProtoGizmoPlugin = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo.gd")
var width_gizmo_id: int
var depth_gizmo_id: int
var height_gizmo_id: int
var fill_gizmo_id1: int
var fill_gizmo_id2: int
var gizmo_utils := ProtoGizmoUtils.new()
var ramp: ProtoRamp = null

var undo_redo: EditorUndoRedoManager
var is_editing := false

func attach_ramp(node: ProtoRamp) -> void:
	ramp = node
	if ramp.get_parent() is ProtoGizmoWrapper:
		var parent: ProtoGizmoWrapper = ramp.get_parent()
		parent.redraw_gizmos_for_child_signal.connect(redraw_gizmos)
		parent.set_handle_for_child_signal.connect(set_handle)
		parent.commit_handle.connect(commit_handle)

func remove_ramp() -> void:
	if ramp.get_parent() is ProtoGizmoWrapper:
		var parent: ProtoGizmoWrapper = ramp.get_parent()
		parent.redraw_gizmos_for_child_signal.disconnect(redraw_gizmos)
		parent.set_handle_for_child_signal.disconnect(set_handle)
		parent.commit_handle.disconnect(commit_handle)
	ramp = null

# Snapping to grid
var snapping_enabled: bool = false
var snap_unit: float = 1.0
var fine_snapping_enabled: bool = false
var fine_snap_unit: float = 0.1

func init_gizmo(plugin: ProtoGizmoPlugin) -> void:
	# Generate a random id for each gizmo
	width_gizmo_id = randi_range(1_000, 1_000_000)
	depth_gizmo_id = width_gizmo_id + 1
	height_gizmo_id = width_gizmo_id + 2
	fill_gizmo_id1 = width_gizmo_id + 3
	fill_gizmo_id2 = width_gizmo_id + 4
	undo_redo = plugin.undo_redo
	plugin.fine_snapping_changed.connect(func (fine_snapping: bool) -> void:
		fine_snapping_enabled = fine_snapping
		ramp.update_gizmos()
	)
	plugin.snapping_changed.connect(func (snapping: bool) -> void:
		snapping_enabled = snapping
		ramp.update_gizmos()
	)

# Debug purposes
var screen_pos: Vector2
var debug_gizmo_handler_id: int
var camera_position: Vector3

## As gizmos can only be used in the Editor, we can cast the [gizmo] to [EditorNode3DGizmo] and [plugin] to [EditorNode3DGizmoPlugin].
func redraw_gizmos(gizmo: EditorNode3DGizmo, plugin: ProtoGizmoPlugin) -> void:
	if gizmo.get_node_3d() != ramp:
		return

	if width_gizmo_id == 0 or depth_gizmo_id == 0 or height_gizmo_id == 0 or fill_gizmo_id1 == 0 or fill_gizmo_id2 == 0:
		init_gizmo(plugin)

	gizmo.clear()
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

	var handles = PackedVector3Array()
	handles.push_back(depth_gizmo_position)
	handles.push_back(width_gizmo_position)
	handles.push_back(height_gizmo_position)
	handles.push_back(fill_gizmo_position1)
	handles.push_back(fill_gizmo_position2)

	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), [depth_gizmo_id, width_gizmo_id, height_gizmo_id, fill_gizmo_id1, fill_gizmo_id2])

	if ramp.shape_polygon != null and ramp.shape_polygon.get_meshes().size() > 1:
		var offset := ramp.get_anchor_offset(ramp.anchor)
		var polygon_offset := offset - Vector3(ramp.width / 2, 0, 0)
		var mesh: Mesh = ramp.shape_polygon.get_meshes()[1]
		var mdt := MeshDataTool.new()
		mdt.create_from_surface(mesh, 0)
		for i in range(mdt.get_vertex_count()):
			var vertex := mdt.get_vertex(i)
			vertex = vertex.rotated(Vector3.UP, -PI / 2.0)
			vertex += polygon_offset
			mdt.set_vertex(i, vertex)

		var newMesh: Mesh = ArrayMesh.new()
		newMesh.clear_surfaces()
		mdt.commit_to_surface(newMesh)
		mdt.clear()
		gizmo.add_collision_triangles(newMesh.generate_triangle_mesh())
		gizmo.add_mesh(newMesh.create_outline(0.001), plugin.get_material("selected", gizmo))

	# Adding debug lines for gizmo if we have cursor screen position set
	if screen_pos:
		var grid_size_modifier = 1.0
		# Grid size is always the max of the two other dimensions
		match debug_gizmo_handler_id:
			depth_gizmo_id:
				# Setting depth
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_width())
				var local_offset_axis = Vector3(0, 0, 1)
				gizmo_utils.debug_draw_handle_grid(camera_position, screen_pos, depth_gizmo_position, local_offset_axis, ramp, gizmo, plugin, grid_size_modifier)
			width_gizmo_id:
				# Setting width
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_true_depth())
				var local_offset_axis = Vector3(1, 0, 0)
				gizmo_utils.debug_draw_handle_grid(camera_position, screen_pos, width_gizmo_position, local_offset_axis, ramp, gizmo, plugin, grid_size_modifier)
			height_gizmo_id:
				# Setting height
				grid_size_modifier = max(ramp.get_width(), ramp.get_true_depth())
				var local_offset_axis = Vector3(0, 1, 0)
				gizmo_utils.debug_draw_handle_grid(camera_position, screen_pos, height_gizmo_position, local_offset_axis, ramp, gizmo, plugin, grid_size_modifier)
			fill_gizmo_id1:
				# Setting fill 1
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_true_depth())
				var local_plane_normal = Vector3(1, 0, 0)
				var local_offset_axis = _get_fill_max_offset().normalized()
				local_offset_axis.z = -local_offset_axis.z
				gizmo_utils.debug_draw_handle_grid_on_plane(fill_gizmo_position1, local_offset_axis, local_plane_normal, ramp, gizmo, plugin, grid_size_modifier)
			fill_gizmo_id2:
				# Setting fill 2
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_true_depth())
				var local_plane_normal = Vector3(1, 0, 0)
				var local_offset_axis = _get_fill_max_offset().normalized()
				local_offset_axis.z = -local_offset_axis.z
				gizmo_utils.debug_draw_handle_grid_on_plane(fill_gizmo_position2, local_offset_axis, local_plane_normal, ramp, gizmo, plugin, grid_size_modifier)

var start_offset := 0.0
var end_offset := 0.0

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

	self.screen_pos = screen_pos
	self.camera_position = camera.position

	match handle_id:
		depth_gizmo_id:
			end_offset = _get_depth_handle_offset(camera, screen_pos)
			if snapping_enabled and not fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, snap_unit)
			elif fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, fine_snap_unit)
			ramp.depth = _get_ramp_depth(end_offset)
		width_gizmo_id:
			end_offset = _get_width_handle_offset(camera, screen_pos)
			if snapping_enabled and not fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, snap_unit)
			elif fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, fine_snap_unit)
			ramp.width = _get_ramp_width(end_offset)
		height_gizmo_id:
			end_offset = _get_height_handle_offset(camera, screen_pos)
			if snapping_enabled and not fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, snap_unit)
			elif fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, fine_snap_unit)
			ramp.height = _get_ramp_height(end_offset)
		fill_gizmo_id1:
			end_offset = _get_fill_handle_offset(camera, screen_pos, Vector3(-ramp.width / 2, 0, 0))
			if snapping_enabled and not fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, snap_unit)
			elif fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, fine_snap_unit)
			ramp.fill = end_offset
		fill_gizmo_id2:
			end_offset = _get_fill_handle_offset(camera, screen_pos, Vector3(ramp.width / 2, 0, 0))
			if snapping_enabled and not fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, snap_unit)
			elif fine_snapping_enabled:
				end_offset = gizmo_utils.snap_to_grid(end_offset, fine_snap_unit)
			ramp.fill = end_offset

	if !is_editing:
		match handle_id:
			depth_gizmo_id:
				debug_gizmo_handler_id = depth_gizmo_id
				start_offset = _get_depth_handle_offset(camera, screen_pos)
			width_gizmo_id:
				debug_gizmo_handler_id = width_gizmo_id
				start_offset = _get_width_handle_offset(camera, screen_pos)
			height_gizmo_id:
				debug_gizmo_handler_id = height_gizmo_id
				start_offset = _get_height_handle_offset(camera, screen_pos)
			fill_gizmo_id1:
				debug_gizmo_handler_id = fill_gizmo_id1
				start_offset = _get_fill_handle_offset(camera, screen_pos, Vector3(-ramp.width / 2, 0, 0))
			fill_gizmo_id2:
				debug_gizmo_handler_id = fill_gizmo_id2
				start_offset = _get_fill_handle_offset(camera, screen_pos, Vector3(ramp.width / 2, 0, 0))
		is_editing = true

	ramp.update_gizmos()

func _get_depth_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2) -> float:
	var local_offset_axis = Vector3(0, 0, 1)
	var gizmo_position = Vector3(0, ramp.get_true_height() / 2, ramp.get_true_depth()) + ramp.get_anchor_offset(ramp.anchor)
	var handle_offset = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, local_offset_axis, ramp)
	return handle_offset.z

func _get_width_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2) -> float:
	var local_offset_axis = Vector3(1, 0, 0)
	var gizmo_position = Vector3(ramp.width / 2, ramp.get_true_height() / 2, ramp.get_true_depth() / 2) + ramp.get_anchor_offset(ramp.anchor)
	var handle_offset = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, local_offset_axis, ramp)
	return handle_offset.x

func _get_height_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2) -> float:
	var local_offset_axis = Vector3(0, 1, 0)
	var gizmo_position = Vector3(0, ramp.get_true_height(), ramp.get_true_depth() / 2) + ramp.get_anchor_offset(ramp.anchor)
	var handle_offset = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, local_offset_axis, ramp)
	return handle_offset.y

func _get_fill_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2,
	gizmo_position_offset: Vector3) -> float:
	var fill_gizmo_axis := _get_fill_max_offset()
	fill_gizmo_axis.z = ramp.get_true_depth() - fill_gizmo_axis.z
	var fill_gizmo_offset := fill_gizmo_axis * (1 - ramp.fill)
	var gizmo_position := Vector3(0, fill_gizmo_offset.y, fill_gizmo_offset.z) + ramp.get_anchor_offset(ramp.anchor) + gizmo_position_offset
	var local_plane_normal := Vector3(1, 0, 0)
	var handle_offset = gizmo_utils.get_handle_offset_by_plane(camera, screen_pos, gizmo_position, local_plane_normal, ramp)
	var gizmo_base_position := Vector3(0, 0, ramp.get_true_depth())
	handle_offset -= gizmo_base_position
	var gizmo_max_position := fill_gizmo_axis - gizmo_base_position
	gizmo_max_position.x = 0
	handle_offset -= ramp.get_anchor_offset(ramp.anchor)
	handle_offset.x = 0
	if (handle_offset.dot(gizmo_max_position) < 0):
		return 1
	return min(1.0, max(0.0, 1 - handle_offset.project(gizmo_max_position).length() / gizmo_max_position.length()))

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

func commit_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	secondary: bool,
	restore: Variant,
	cancel: bool) -> void:
	if gizmo.get_node_3d() != ramp:
		return

	match handle_id:
		depth_gizmo_id:
			restore = _get_ramp_depth(start_offset)
			undo_redo.create_action("Edit ramp depth", 0, ramp, true)
			undo_redo.add_do_property(ramp, "depth", _get_ramp_depth(end_offset))
			undo_redo.add_undo_property(ramp, "depth", restore)
		width_gizmo_id:
			restore = _get_ramp_width(start_offset)
			undo_redo.create_action("Edit ramp width", 0, ramp, true)
			undo_redo.add_do_property(ramp, "width", _get_ramp_width(end_offset))
			undo_redo.add_undo_property(ramp, "width", restore)
		height_gizmo_id:
			restore = _get_ramp_height(start_offset)
			undo_redo.create_action("Edit ramp height", 0, ramp, true)
			undo_redo.add_do_property(ramp, "height", _get_ramp_height(end_offset))
			undo_redo.add_undo_property(ramp, "height", restore)
		fill_gizmo_id1, fill_gizmo_id2:
			restore = start_offset
			undo_redo.create_action("Edit ramp fill", 0, ramp, true)
			undo_redo.add_do_property(ramp, "fill", end_offset)
			undo_redo.add_undo_property(ramp, "fill", restore)

	undo_redo.commit_action()
	is_editing = false