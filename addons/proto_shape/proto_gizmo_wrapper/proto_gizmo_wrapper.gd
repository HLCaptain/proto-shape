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

func subgizmos_intersect_ray_for_child(gizmo, plugin, camera: Camera3D, screen_pos: Vector2) -> int:
	var child: Variant = gizmo.get_node_3d()
	if child != null and child.has_method("subgizmos_intersect_ray"):
		return child.subgizmos_intersect_ray(gizmo, plugin, camera, screen_pos)
	return -1

func get_subgizmo_transform_for_child(gizmo, plugin, subgizmo_id: int) -> Transform3D:
	var child: Variant = gizmo.get_node_3d()
	if child != null and child.has_method("get_subgizmo_transform"):
		return child.get_subgizmo_transform(gizmo, plugin, subgizmo_id)
	return Transform3D.IDENTITY

func set_subgizmo_transform_for_child(gizmo, plugin, subgizmo_id: int, transform: Transform3D) -> void:
	var child: Variant = gizmo.get_node_3d()
	if child != null and child.has_method("set_subgizmo_transform"):
		child.set_subgizmo_transform(gizmo, plugin, subgizmo_id, transform)

func commit_subgizmos_for_child(
	gizmo,
	plugin,
	ids: PackedInt32Array,
	restores: Array[Transform3D],
	cancel: bool) -> void:

	var child: Variant = gizmo.get_node_3d()
	if child != null and child.has_method("commit_subgizmos"):
		child.commit_subgizmos(gizmo, plugin, ids, restores, cancel)
