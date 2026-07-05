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
signal commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool)

func redraw_gizmos_for_child(gizmo, plugin) -> void:
	redraw_gizmos_for_child_signal.emit(gizmo, plugin)

func set_handle_for_child(
	gizmo,
	plugin,
	handle_id: int,
	secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2) -> void:
	set_handle_for_child_signal.emit(gizmo, plugin, handle_id, secondary, camera, screen_pos)

func commit_handle_for_child(
	gizmo,
	plugin,
	handle_id: int,
	secondary: bool,
	restore: Variant,
	cancel: bool) -> void:
	commit_handle.emit(gizmo, plugin, handle_id, secondary, restore, cancel)

func is_handle_highlighted_for_child(gizmo, plugin, handle_id: int, secondary: bool) -> bool:
	var child: Variant = gizmo.get_node_3d()
	if child != null and child.has_method("is_handle_highlighted"):
		return child.is_handle_highlighted(gizmo, plugin, handle_id, secondary)
	return false

func get_arrow_drag_segments_for_child(child, plugin) -> Array:
	if child != null and child.has_method("get_arrow_drag_segments"):
		var segments: Variant = child.get_arrow_drag_segments(plugin)
		if segments is Array:
			return segments
	return []

func begin_arrow_drag_for_child(
	child,
	plugin,
	handle_id: int,
	camera: Camera3D,
	screen_pos: Vector2) -> void:

	if child != null and child.has_method("begin_arrow_drag"):
		child.begin_arrow_drag(plugin, handle_id, camera, screen_pos)

func set_arrow_drag_for_child(
	child,
	plugin,
	handle_id: int,
	camera: Camera3D,
	screen_pos: Vector2) -> void:

	if child != null and child.has_method("set_arrow_drag"):
		child.set_arrow_drag(plugin, handle_id, camera, screen_pos)

func commit_arrow_drag_for_child(child, plugin, handle_id: int, cancel: bool) -> void:
	if child != null and child.has_method("commit_arrow_drag"):
		child.commit_arrow_drag(plugin, handle_id, cancel)
