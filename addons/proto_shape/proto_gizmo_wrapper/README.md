# ProtoGizmoWrapper

ProtoGizmoWrapper connects custom `Node3D` children to ProtoShape's editor gizmos through signals. For a complete, runtime-safe implementation, open [ExampleWrappedVolume](../proto_gizmo/examples/wrapper_volume/example_wrapped_volume.gd) and its [scene](../proto_gizmo/examples/wrapper_volume/example_wrapped_volume.tscn).

<img src="../icons/proto-gizmo-wrapper-icon.svg" style="height: 40%; width: 40%; margin: 0 auto; display: block">

## Setup

Add `ProtoGizmoWrapper` from the Add Child Node menu and place your custom shape beneath it. In the child's `_enter_tree()`, connect these signals only when `Engine.is_editor_hint()` is true. Disconnect them in `_exit_tree()`. The working example includes both lifecycle methods.

```gdscript
signal redraw_gizmos_for_child_signal(gizmo, plugin)
signal set_handle_for_child_signal(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2)
signal commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool)
```

The wrapper broadcasts signals to subscribed children, so every callback must check `gizmo.get_node_3d() == self`. Keep `gizmo` and `plugin` dynamically typed in scripts that also load in exported games; editor-only classes are unavailable in export templates.

## Callback skeleton

Use small, stable handle IDs, such as `const HANDLE_WIDTH := 1`. IDs need to be unique only within this child's gizmo; they are not resource UIDs.

```gdscript
func redraw_gizmos(gizmo, plugin) -> void:
	if gizmo.get_node_3d() != self:
		return
	gizmo.clear()
	# Draw handles with plugin.get_material("proto_handler", gizmo).

func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	if gizmo.get_node_3d() != self:
		return
	# Project the pointer, ignore null projections, and apply the property edit.

func commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	if gizmo.get_node_3d() != self:
		return
	# Restore the original value on cancel; otherwise commit one undo action.
```

These are callback skeletons, not a complete editable shape. [ExampleWrappedVolume](../proto_gizmo/examples/wrapper_volume/example_wrapped_volume.gd) implements geometry, handles, drag state, snapping, and `plugin.undo_redo` together.

## Arrows and coordinates

Optional arrow methods are forwarded directly to the child because they return values. Implement `get_arrow_drag_segments()`, `begin_arrow_drag()`, `set_arrow_drag()`, and `commit_arrow_drag()` using the [generic provider contract](../proto_gizmo/README.md#generic-gizmo-providers). `begin_arrow_drag()` returns `true` only after a valid initial projection; returning `false` leaves the click unclaimed.

[ProtoGizmoUtils](../proto_gizmo/README.md#protogizmoutils) returns node-local `Vector3` points or `null` when projection is unsafe. Ignore invalid samples without changing the last valid property or initial pointer offset. Use the same local axis for projection and property calculation.

Expose `get_proto_gizmo_selection_nodes()` on your child to make its generated `CSGShape3D` or `MeshInstance3D` geometry selectable through the owner node.

## Upgrading to 1.2.0

The handle signal now consistently delivers `(gizmo, plugin, handle_id, secondary, camera, screen_pos)`, and `commit_handle` includes `plugin` as its second argument. Update handlers that compensated for the older argument order. The wrapper keeps one current contract; it does not adapt old callback signatures.
