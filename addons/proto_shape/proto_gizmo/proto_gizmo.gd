extends EditorNode3DGizmoPlugin

const ProtoGizmoWrapper = preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")

# Must be initialized externally by ProtoShape plugin
var undo_redo: EditorUndoRedoManager

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
	create_material("selected", Color(0, 0, 1, 0.1))
	create_handle_material("proto_handler", false, load("res://addons/proto_shape/icon/proto-gizmo-handler.png"))

func _has_gizmo(node: Node3D) -> bool:
	return _get_gizmo_provider(node) != null or _get_gizmo_wrapper(node) != null

func _get_gizmo_name() -> String:
	return "ProtoGizmo"

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	var node := gizmo.get_node_3d()
	var provider = _get_gizmo_provider(node)
	if provider != null:
		provider.redraw_gizmos(gizmo, self)
		return

	var wrapper := _get_gizmo_wrapper(node)
	if wrapper != null:
		wrapper.redraw_gizmos_for_child(gizmo, self)
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
