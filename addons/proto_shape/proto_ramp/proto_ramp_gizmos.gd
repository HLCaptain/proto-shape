# Implementing Gizmo
const ProtoGizmoWrapper = preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")
const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")
const ProtoRamp = preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")
const ProtoGizmoPlugin = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo.gd")
var width_gizmo_id: int
var depth_gizmo_id: int
var height_gizmo_id: int
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
	width_gizmo_id = randi_range(0, 1_000_000)
	depth_gizmo_id = randi_range(0, 1_000_000)
	height_gizmo_id = randi_range(0, 1_000_000)
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
var local_offset_axis: Vector3
var camera_position: Vector3

## As gizmos can only be used in the Editor, we can cast the [gizmo] to [EditorNode3DGizmo] and [plugin] to [EditorNode3DGizmoPlugin].
func redraw_gizmos(gizmo: EditorNode3DGizmo, plugin: ProtoGizmoPlugin) -> void:
	if gizmo.get_node_3d() != ramp:
		return

	if width_gizmo_id == 0 or depth_gizmo_id == 0 or height_gizmo_id == 0:
		init_gizmo(plugin)

	gizmo.clear()
	var true_depth: float = ramp.get_true_depth()
	var true_height: float = ramp.get_true_height()
	var anchor_offset: Vector3 = ramp.get_anchor_offset(ramp.anchor)
	var depth_gizmo_position := Vector3(0, true_height / 2, true_depth) + anchor_offset
	var width_gizmo_position := Vector3(ramp.width / 2, true_height / 2, true_depth / 2) + anchor_offset
	var height_gizmo_position := Vector3(0, true_height, true_depth / 2) + anchor_offset

	# When on the left, width gizmo is on the right
	# When in the back (top, base), depth gizmo is on the front
	# When on the top, height gizmo is on the bottom
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

	gizmo.add_handles(handles, plugin.get_material("proto_handler", gizmo), [depth_gizmo_id, width_gizmo_id, height_gizmo_id])

	# Add collision triangles by generating TriangleMesh from node mesh
	# Meshes can be empty when reparenting the node with an existing selection
	# FIXME: Behavior is inconsistent, as other gizmos can override the collision triangles.
	#  Node can be selected without a problem when reparenting with a single Node3D.
	#  Node cannot be selected normally, when the new parent is a CSGShape3D.
	#  CSGShape3D is updating its own collision triangles, which are overriding the ProtoRamp's.
	#  Although in theory, ProtoRamp's Gizmo has more priority, it doesn't seem to work.

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
		# Transform mesh with transform
		gizmo.add_collision_triangles(newMesh.generate_triangle_mesh())
		gizmo.add_mesh(newMesh, plugin.get_material("selected", gizmo))

	# Adding debug lines for gizmo if we have cursor screen position set
	if screen_pos:
		var grid_size_modifier = 1.0
		# Grid size is always the max of the two other dimensions
		var local_gizmo_position: Vector3
		match local_offset_axis:
			Vector3(0, 0, 1):
				# Setting depth
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_width())
				local_gizmo_position = depth_gizmo_position
			Vector3(1, 0, 0):
				# Setting width
				grid_size_modifier = max(ramp.get_true_height(), ramp.get_true_depth())
				local_gizmo_position = width_gizmo_position
			Vector3(0, 1, 0):
				# Setting height
				grid_size_modifier = max(ramp.get_width(), ramp.get_true_depth())
				local_gizmo_position = height_gizmo_position
		gizmo_utils.debug_draw_handle_grid(camera_position, screen_pos, local_gizmo_position, local_offset_axis, ramp, gizmo, plugin, grid_size_modifier)

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

	if !is_editing:
		match handle_id:
			depth_gizmo_id:
				start_offset = _get_depth_handle_offset(camera, screen_pos)
			width_gizmo_id:
				start_offset = _get_width_handle_offset(camera, screen_pos)
			height_gizmo_id:
				start_offset = _get_height_handle_offset(camera, screen_pos)
		is_editing = true

	ramp.update_gizmos()

func _get_depth_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2) -> float:
	local_offset_axis = Vector3(0, 0, 1)
	var gizmo_position = Vector3(0, ramp.get_true_height() / 2, ramp.get_true_depth()) + ramp.get_anchor_offset(ramp.anchor)
	var handle_offset = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, local_offset_axis, ramp)
	return handle_offset.z

func _get_width_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2) -> float:
	local_offset_axis = Vector3(1, 0, 0)
	var gizmo_position = Vector3(ramp.width / 2, ramp.get_true_height() / 2, ramp.get_true_depth() / 2) + ramp.get_anchor_offset(ramp.anchor)
	var handle_offset = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, local_offset_axis, ramp)
	return handle_offset.x

func _get_height_handle_offset(
	camera: Camera3D,
	screen_pos: Vector2) -> float:
	local_offset_axis = Vector3(0, 1, 0)
	var gizmo_position = Vector3(0, ramp.get_true_height(), ramp.get_true_depth() / 2) + ramp.get_anchor_offset(ramp.anchor)
	var handle_offset = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, local_offset_axis, ramp)
	return handle_offset.y

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

	undo_redo.commit_action()
	is_editing = false