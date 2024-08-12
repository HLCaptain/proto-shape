extends EditorNode3DGizmoPlugin

const ProtoGizmoWrapper := preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")
const ProtoRamp := preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")

func _init() -> void:
	create_material("main", Color(1, 0, 0))
	create_material("selected", Color(0, 0, 1, 0.1))

func _has_gizmo(node: Node3D) -> bool:
	if node.get_parent() is ProtoGizmoWrapper or node is ProtoRamp:
		return true
	else:
		return false

func _get_gizmo_name() -> String:
	return "ProtoGizmo"

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	var node := gizmo.get_node_3d()
	if node is ProtoRamp:
		node.redraw_gizmos(gizmo, self)
		return
	if node.get_parent() is ProtoGizmoWrapper:
		node.get_parent().redraw_gizmos_for_child(gizmo, self)
		return

func _set_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2) -> void:
	var node := gizmo.get_node_3d()
	if node is ProtoRamp:
		node.set_handle(gizmo, self, handle_id, secondary, camera, screen_pos)
		return
	if node.get_parent() is ProtoGizmoWrapper:
		node.get_parent().set_handle_for_child(gizmo, self, handle_id, secondary, camera, screen_pos)
		return
