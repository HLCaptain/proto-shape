extends EditorNode3DGizmoPlugin

const ProtoGizmoWrapper := preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")
const ProtoRamp := preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")
var camera_position := Vector3(0, 0, 0)
var width_gizmo_id: int
var depth_gizmo_id: int
var height_gizmo_id: int

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
		node.redraw_gizmos(gizmo, self, node)
		return
	if node.get_parent() is ProtoGizmoWrapper:
		node.get_parent().redraw_gizmos_for_child(gizmo, self, node)
		return

func _set_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2) -> void:
	var node := gizmo.get_node_3d()
	if node is ProtoRamp:
		node.set_handle(gizmo, handle_id, secondary, camera, screen_pos, node)
		return
	if node.get_parent() is ProtoGizmoWrapper:
		node.get_parent().set_handle_for_child(gizmo, handle_id, secondary, camera, screen_pos, node)
		return
