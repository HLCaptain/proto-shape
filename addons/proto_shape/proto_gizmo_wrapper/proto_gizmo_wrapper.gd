@tool
extends Node

# Editor tool plugins removed to avoid game packaging errors
# signal redraw_gizmos_for_child_signal(gizmo: EditorNode3DGizmo, plugin: EditorNode3DGizmoPlugin)
# signal set_handle_for_child_signal(gizmo: EditorNode3DGizmo, plugin: EditorNode3DGizmoPlugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2)
signal redraw_gizmos_for_child_signal(gizmo, plugin)
signal set_handle_for_child_signal(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2)

func redraw_gizmos_for_child(gizmo, plugin) -> void:
	redraw_gizmos_for_child_signal.emit(gizmo, plugin)

func set_handle_for_child(
	gizmo,
	plugin,
	handle_id: int,
	secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2) -> void:
	set_handle_for_child_signal.emit(gizmo, handle_id, secondary, camera, screen_pos, plugin)
