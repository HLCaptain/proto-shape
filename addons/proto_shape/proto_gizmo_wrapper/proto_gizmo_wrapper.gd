@tool
extends Node

const ProtoGizmoPlugin := preload("res://addons/proto_shape/proto_gizmo/proto_gizmo.gd")

signal redraw_gizmos_for_child_signal(gizmo: EditorNode3DGizmo, plugin: ProtoGizmoPlugin, child: Node)
signal set_handle_for_child_signal(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2, child: Node)

var initialized_children: Array[Node] = []

func redraw_gizmos_for_child(gizmo: EditorNode3DGizmo, plugin: ProtoGizmoPlugin, child: Node) -> void:
    redraw_gizmos_for_child_signal.emit(gizmo, plugin, child)
    print_debug("Redrawing gizmos for node " + child.get_name())

func set_handle_for_child(
    gizmo: EditorNode3DGizmo,
    handle_id: int,
    secondary: bool,
    camera: Camera3D,
    screen_pos: Vector2,
    child: Node) -> void:
    set_handle_for_child_signal.emit(gizmo, handle_id, secondary, camera, screen_pos, child)
    print_debug("Setting handle for node " + child.get_name())