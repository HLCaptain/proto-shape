extends EditorNode3DGizmoPlugin

const ProtoGizmoWrapper = preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")
const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")

# Must be initialized externally by ProtoShape plugin
var undo_redo: EditorUndoRedoManager
var gizmo_utils := ProtoGizmoUtils.new()

var hovered_node: Node3D = null
var hovered_arrow_id := -1
var drag_node: Node3D = null
var drag_arrow_id := -1

signal snapping_changed(snapping: bool)
signal fine_snapping_changed(fine_snapping: bool)

# Must be initialized externally by ProtoShape plugin
var _snapping: bool = false
var snapping: bool: set = set_snapping, get = get_snapping
var _fine_snapping: bool = false
var fine_snapping: bool: set = set_fine_snapping, get = get_fine_snapping

func set_snapping(snapping: bool) -> void:
	_snapping = snapping
	snapping_changed.emit(snapping)

func set_fine_snapping(fine_snapping: bool) -> void:
	_fine_snapping = fine_snapping
	fine_snapping_changed.emit(fine_snapping)

func get_snapping() -> bool:
	return _snapping

func get_fine_snapping() -> bool:
	return _fine_snapping

func _init() -> void:
	create_material("main", Color(1, 0.3725, 0.3725, 0.5))
	create_material("main_highlight", Color(1, 0.82, 0.18, 0.85))
	create_material("selected", Color(0, 0, 1, 0.1))
	create_handle_material("proto_handler", false, load("res://addons/proto_shape/icon/proto-gizmo-handler.png"))

func _has_gizmo(node: Node3D) -> bool:
	return _get_gizmo_provider(node) != null or _get_gizmo_wrapper(node) != null

func handles_node(node: Node3D) -> bool:
	return _has_gizmo(node)

func _get_gizmo_name() -> String:
	return "ProtoGizmo"

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	var node := gizmo.get_node_3d()
	var provider = _get_gizmo_provider(node)
	if provider != null:
		provider.redraw_gizmos(gizmo, self)
		_add_selection_meshes(gizmo, node, provider)
		return

	var wrapper := _get_gizmo_wrapper(node)
	if wrapper != null:
		wrapper.redraw_gizmos_for_child(gizmo, self)
		_add_selection_meshes(gizmo, node, null)
		return

func _set_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2) -> void:
	var node := gizmo.get_node_3d()
	var provider = _get_gizmo_provider(node)
	if provider != null:
		provider.set_handle(gizmo, self, handle_id, secondary, camera, screen_pos)
		return

	var wrapper := _get_gizmo_wrapper(node)
	if wrapper != null:
		wrapper.set_handle_for_child(gizmo, self, handle_id, secondary, camera, screen_pos)
		return

func _commit_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	secondary: bool,
	restore: Variant,
	cancel: bool) -> void:
	var node := gizmo.get_node_3d()
	var provider = _get_gizmo_provider(node)
	if provider != null:
		if provider.has_method("commit_handle"):
			provider.commit_handle(gizmo, self, handle_id, secondary, restore, cancel)
		return

	var wrapper := _get_gizmo_wrapper(node)
	if wrapper != null:
		wrapper.commit_handle_for_child(gizmo, self, handle_id, secondary, restore, cancel)
		return

func handle_3d_gui_input(camera: Camera3D, event: InputEvent) -> bool:
	if drag_node != null:
		return _handle_active_arrow_drag(camera, event)

	if event is InputEventMouseMotion:
		_update_arrow_hover(camera, event.position)
		return false

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_update_arrow_hover(camera, event.position)
			if hovered_node == null:
				return false
			_begin_arrow_drag(hovered_node, hovered_arrow_id, camera, event.position)
			return true

	return false

func is_arrow_handle_active(node: Node3D, arrow_id: int) -> bool:
	if node == null:
		return false
	return (node == hovered_node and arrow_id == hovered_arrow_id) or (node == drag_node and arrow_id == drag_arrow_id)

func _handle_active_arrow_drag(camera: Camera3D, event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		_set_arrow_drag(camera, event.position)
		return true

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_commit_arrow_drag(false)
			_update_arrow_hover(camera, event.position)
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_commit_arrow_drag(true)
			_update_arrow_hover(camera, event.position)
			return true

	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			_commit_arrow_drag(true)
			return true
		return false

	return true

func _update_arrow_hover(camera: Camera3D, screen_pos: Vector2) -> void:
	var hit := _get_hovered_arrow(camera, screen_pos)
	var next_node: Node3D = hit["node"]
	var next_arrow_id: int = hit["id"]
	if next_node == hovered_node and next_arrow_id == hovered_arrow_id:
		return

	var old_hovered_node := hovered_node
	hovered_node = next_node
	hovered_arrow_id = next_arrow_id
	_update_node_gizmos(old_hovered_node)
	_update_node_gizmos(hovered_node)

func _get_hovered_arrow(camera: Camera3D, screen_pos: Vector2) -> Dictionary:
	var closest_node: Node3D = null
	var closest_id := -1
	var closest_distance := INF
	for node in _get_selected_gizmo_nodes():
		var segments := _get_arrow_drag_segments(node)
		for segment in segments:
			if not (segment is Dictionary):
				continue
			if not segment.has("id") or not segment.has("from") or not segment.has("to"):
				continue

			var radius_scale := 1.0
			if segment.has("radius_scale"):
				radius_scale = float(segment["radius_scale"])

			var distance := gizmo_utils.get_screen_arrow_signed_distance(camera, screen_pos, node, segment["from"], segment["to"], radius_scale)
			if distance <= ProtoGizmoUtils.ARROW_PICK_EDGE_TOLERANCE_PIXELS and distance < closest_distance:
				closest_node = node
				closest_id = segment["id"]
				closest_distance = distance

	return {"node": closest_node, "id": closest_id}

func _get_selected_gizmo_nodes() -> Array[Node3D]:
	var nodes: Array[Node3D] = []
	if not Engine.has_singleton("EditorInterface"):
		return nodes

	var editor_interface: Variant = Engine.get_singleton("EditorInterface")
	if editor_interface == null:
		return nodes

	var selection: Variant = editor_interface.get_selection()
	if selection == null:
		return nodes

	for node in selection.get_selected_nodes():
		if node is Node3D and handles_node(node):
			nodes.push_back(node)
	return nodes

func _begin_arrow_drag(node: Node3D, arrow_id: int, camera: Camera3D, screen_pos: Vector2) -> void:
	drag_node = node
	drag_arrow_id = arrow_id
	_call_begin_arrow_drag(node, arrow_id, camera, screen_pos)
	_update_node_gizmos(node)

func _set_arrow_drag(camera: Camera3D, screen_pos: Vector2) -> void:
	_call_set_arrow_drag(drag_node, drag_arrow_id, camera, screen_pos)

func _commit_arrow_drag(cancel: bool) -> void:
	var node := drag_node
	var arrow_id := drag_arrow_id
	drag_node = null
	drag_arrow_id = -1
	_call_commit_arrow_drag(node, arrow_id, cancel)
	_update_node_gizmos(node)

func _get_arrow_drag_segments(node: Node3D) -> Array:
	var provider = _get_gizmo_provider(node)
	if provider != null and provider.has_method("get_arrow_drag_segments"):
		var provider_segments: Variant = provider.get_arrow_drag_segments(self)
		if provider_segments is Array:
			return provider_segments

	var wrapper := _get_gizmo_wrapper(node)
	if wrapper != null:
		var wrapper_segments: Variant = wrapper.get_arrow_drag_segments_for_child(node, self)
		if wrapper_segments is Array:
			return wrapper_segments
	return []

func _call_begin_arrow_drag(node: Node3D, arrow_id: int, camera: Camera3D, screen_pos: Vector2) -> void:
	var provider = _get_gizmo_provider(node)
	if provider != null and provider.has_method("begin_arrow_drag"):
		provider.begin_arrow_drag(self, arrow_id, camera, screen_pos)
		return

	var wrapper := _get_gizmo_wrapper(node)
	if wrapper != null:
		wrapper.begin_arrow_drag_for_child(node, self, arrow_id, camera, screen_pos)

func _call_set_arrow_drag(node: Node3D, arrow_id: int, camera: Camera3D, screen_pos: Vector2) -> void:
	var provider = _get_gizmo_provider(node)
	if provider != null and provider.has_method("set_arrow_drag"):
		provider.set_arrow_drag(self, arrow_id, camera, screen_pos)
		return

	var wrapper := _get_gizmo_wrapper(node)
	if wrapper != null:
		wrapper.set_arrow_drag_for_child(node, self, arrow_id, camera, screen_pos)

func _call_commit_arrow_drag(node: Node3D, arrow_id: int, cancel: bool) -> void:
	var provider = _get_gizmo_provider(node)
	if provider != null and provider.has_method("commit_arrow_drag"):
		provider.commit_arrow_drag(self, arrow_id, cancel)
		return

	var wrapper := _get_gizmo_wrapper(node)
	if wrapper != null:
		wrapper.commit_arrow_drag_for_child(node, self, arrow_id, cancel)

func _update_node_gizmos(node: Node3D) -> void:
	if node != null and is_instance_valid(node):
		node.update_gizmos()

func _is_handle_highlighted(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> bool:
	return is_proto_handle_highlighted(gizmo, handle_id, secondary)

func get_handle_arrow_material(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool = false) -> Material:
	if is_proto_handle_highlighted(gizmo, handle_id, secondary):
		return get_material("main_highlight", gizmo)
	return get_material("main", gizmo)

func is_proto_handle_highlighted(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool = false) -> bool:
	var node := gizmo.get_node_3d()
	if is_arrow_handle_active(node, handle_id):
		return true

	var provider = _get_gizmo_provider(node)
	if provider != null and provider.has_method("is_handle_highlighted"):
		return provider.is_handle_highlighted(gizmo, self, handle_id, secondary)

	var wrapper := _get_gizmo_wrapper(node)
	if wrapper != null:
		return wrapper.is_handle_highlighted_for_child(gizmo, self, handle_id, secondary)
	return false

func should_draw_mesh_guides(gizmo: EditorNode3DGizmo) -> bool:
	var node := gizmo.get_node_3d()
	if node == null:
		return false
	if not Engine.has_singleton("EditorInterface"):
		return true

	var editor_interface: Variant = Engine.get_singleton("EditorInterface")
	if editor_interface == null:
		return true

	var selection: Variant = editor_interface.get_selection()
	if selection == null:
		return true
	return selection.get_selected_nodes().has(node)

func _get_gizmo_provider(node: Node3D) -> Variant:
	if node == null or not node.has_method("get_proto_gizmo_provider"):
		return null

	var provider: Variant = node.get_proto_gizmo_provider()
	if _is_gizmo_provider(provider):
		return provider
	return null

func _is_gizmo_provider(provider: Variant) -> bool:
	if provider == null or not (provider is Object):
		return false
	return provider.has_method("redraw_gizmos") and provider.has_method("set_handle")

func _get_gizmo_wrapper(node: Node3D) -> ProtoGizmoWrapper:
	if node == null:
		return null
	if node.get_parent() is ProtoGizmoWrapper:
		return node.get_parent()
	return null

func _add_selection_meshes(gizmo: EditorNode3DGizmo, node: Node3D, provider: Variant) -> void:
	var selection_nodes := _get_selection_nodes(node, provider)
	for selection_node in selection_nodes:
		if selection_node == null or not (selection_node is Node3D):
			continue

		var mesh_data := _get_selection_mesh_data(selection_node)
		if mesh_data.is_empty():
			continue

		var mesh: Mesh = mesh_data["mesh"]
		var mesh_global_transform: Transform3D = mesh_data["global_transform"]
		var local_transform: Transform3D = node.global_transform.affine_inverse() * mesh_global_transform
		var transformed_mesh := _transform_mesh(mesh, local_transform)
		if transformed_mesh == null:
			continue

		var triangle_mesh := transformed_mesh.generate_triangle_mesh()
		if triangle_mesh != null:
			gizmo.add_collision_triangles(triangle_mesh)

		if selection_node.is_visible_in_tree():
			var outline_mesh := transformed_mesh.create_outline(0.001)
			if outline_mesh != null:
				gizmo.add_mesh(outline_mesh, get_material("selected", gizmo))

func _get_selection_nodes(node: Node3D, provider: Variant) -> Array:
	if provider != null and provider.has_method("get_proto_gizmo_selection_nodes"):
		var provider_selection_nodes: Variant = provider.get_proto_gizmo_selection_nodes()
		if provider_selection_nodes is Array:
			return provider_selection_nodes

	if node.has_method("get_proto_gizmo_selection_nodes"):
		var node_selection_nodes: Variant = node.get_proto_gizmo_selection_nodes()
		if node_selection_nodes is Array:
			return node_selection_nodes

	return []

func _get_selection_mesh_data(selection_node: Node3D) -> Dictionary:
	if selection_node is MeshInstance3D and selection_node.mesh != null:
		return {"mesh": selection_node.mesh, "global_transform": selection_node.global_transform}

	if selection_node is CSGShape3D:
		var meshes: Array = selection_node.get_meshes()
		if meshes.size() > 1 and meshes[1] is Mesh:
			var mesh_transform := Transform3D.IDENTITY
			if meshes[0] is Transform3D:
				mesh_transform = meshes[0]

			var global_transform := selection_node.global_transform
			if mesh_transform != Transform3D.IDENTITY and selection_node.get_parent() is Node3D:
				global_transform = selection_node.get_parent().global_transform * mesh_transform

			return {"mesh": meshes[1], "global_transform": global_transform}

	return {}

func _transform_mesh(mesh: Mesh, transform: Transform3D) -> ArrayMesh:
	var transformed_mesh := ArrayMesh.new()
	for surface_index in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface_index)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for vertex_index in range(vertices.size()):
			vertices[vertex_index] = transform * vertices[vertex_index]
		arrays[Mesh.ARRAY_VERTEX] = vertices
		transformed_mesh.add_surface_from_arrays(mesh.surface_get_primitive_type(surface_index), arrays)

	return transformed_mesh
