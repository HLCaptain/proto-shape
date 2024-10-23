@tool
extends Node

## Editor tool plugins removed to avoid game packaging errors.
## [gizmo] is [EditorNode3DGizmo].
## [plugin] is [EditorNode3DGizmoPlugin].
signal redraw_gizmos_for_child_signal(gizmo, plugin)

## Editor tool plugins removed to avoid game packaging errors.
## [gizmo] is [EditorNode3DGizmo].
## [plugin] is [EditorNode3DGizmoPlugin].
signal set_handle_for_child_signal(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2)

## Editor tool plugins removed to avoid game packaging errors.
## [gizmo] is [EditorNode3DGizmo].
## [plugin] is [EditorNode3DGizmoPlugin].
signal commit_handle(gizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool)

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
