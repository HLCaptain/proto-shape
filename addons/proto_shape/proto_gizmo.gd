extends EditorNode3DGizmoPlugin

const ProtoGizmoWrapper := preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")
var camera_position := Vector3(0, 0, 0)
var width_gizmo_id: int
var depth_gizmo_id: int
var height_gizmo_id: int

func _has_gizmo(node: Node3D) -> bool:
	if node.get_parent() is ProtoGizmoWrapper:
		print_debug("Has gizmo")
		return true
	else:
		print_debug("Does not have gizmo, parent was " + str(node.get_parent()))
		return false

func _get_gizmo_name() -> String:
	return "ProtoGizmoWrapper"

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	print_debug("Redrawing gizmo")
	var node := gizmo.get_node_3d()
	var wrapper: ProtoGizmoWrapper = node.get_parent()
	wrapper.redraw_gizmos_for_child(gizmo, self, node)

func _set_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2) -> void:
	print_debug("Setting handle")
	var node := gizmo.get_node_3d()
	var wrapper: ProtoGizmoWrapper = node.get_parent()
	wrapper.set_handle_for_child(gizmo, handle_id, secondary, camera, screen_pos, node)
