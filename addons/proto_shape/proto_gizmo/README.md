# ProtoGizmo

ProtoGizmo is an `EditorNode3DGizmoPlugin` that provides a base for creating custom gizmos in the Godot editor. It is used to create custom gizmos for the `ProtoShape` addon. With the use of `ProtoGizmoWrapper`, you can create custom gizmos for your 3D nodes.

## Generic gizmo providers

`ProtoGizmo` can draw and edit any `Node3D` that exposes a gizmo provider:

```gdscript
func get_proto_gizmo_provider() -> Variant:
	return gizmos
```

The returned provider must implement these editor-only methods:

```gdscript
func redraw_gizmos(gizmo, plugin) -> void
func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void
func commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void
```

`commit_handle` is optional for draw-only gizmos, but editable handles should implement it and use `EditorUndoRedoManager` through the `plugin.undo_redo` reference.

Providers can also make solid arrow guides hoverable and directly draggable by implementing these optional methods. `ProtoGizmo` handles `EditorPlugin._forward_3d_gui_input()`, picks the closest selected arrow in screen space, and forwards drag updates to the provider:

```gdscript
func get_arrow_drag_segments(plugin) -> Array
func begin_arrow_drag(plugin, handle_id: int, camera: Camera3D, screen_pos: Vector2) -> void
func set_arrow_drag(plugin, handle_id: int, camera: Camera3D, screen_pos: Vector2) -> void
func commit_arrow_drag(plugin, handle_id: int, cancel: bool) -> void
```

Use the same id for a point handle and its arrow segment when both edit the same property. `get_arrow_drag_segments()` should return local-space dictionaries in the form `{"id": handle_id, "from": from_position, "to": to_position}`.

Arrow selection does not use Godot's native transform gizmo arrows. `ProtoGizmo` projects each provider arrow into screen space, tests the shaft and head footprint against the cursor, highlights the closest selected arrow, and forwards drag events to the provider. This lets custom nodes expose native-feeling hover and drag behavior while keeping their own property math, snapping, and undo/redo flow.

Nodes or providers can optionally expose generated visual nodes for click-selection:

```gdscript
func get_proto_gizmo_selection_nodes() -> Array:
	return [generated_csg_shape]
```

`ProtoGizmo` uses these nodes to add collision triangles and a selected outline in the gizmo, so clicking the generated shape selects the owner node. `CSGShape3D` and `MeshInstance3D` nodes are supported.

Keep editor-only provider scripts loaded behind `Engine.is_editor_hint()` when they use `EditorNode3DGizmo`, `EditorNode3DGizmoPlugin`, or `EditorUndoRedoManager` types. `ProtoRamp` uses this provider pattern through `proto_ramp_gizmos.gd`.

Handle direction vectors do not need to be static. A provider can calculate the handle position and local direction axis on every `redraw_gizmos` and `set_handle` call, then pass that dynamic axis into `ProtoGizmoUtils`.

Use `ProtoGizmoUtils.add_arrow_mesh(gizmo, material, from_position, to_position)` to draw a solid 3D arrow along a handle's drag direction. Place the `gizmo.add_handles()` point at `from_position` so the handle icon sits at the arrow base, then point the arrow toward the direction that increases or adjusts the value.

`add_arrow_mesh()` also adds a collision segment for normal gizmo hit testing, while direct arrow-body hover and drag uses the provider's `get_arrow_drag_segments()` data and the projected shaft/head footprint. Use `plugin.get_handle_arrow_material(gizmo, handle_id)` for arrows that should use the highlighted material during hover or drag. Providers can implement `is_handle_highlighted(gizmo, plugin, handle_id, secondary)` to share their current editing state.

See [examples](examples/README.md) for provider-based custom shapes, dynamic handle axes, and `ProtoGizmoWrapper` signal usage.

## Default materials

- `proto_handler` - Same as internal "handlers" material for gizmo handles, but blue instead of redish color.
- `selected` - Material for selected nodes (bluish transparent color).
- `main` - Base reddish color material for solid arrows, general guides, and debugging use. It is also used for drawing camera-projected debug planes.

## ProtoGizmoUtils

ProtoGizmoUtils are advanced 3D math utilities used for calculating handle offsets and projecting planes for gizmos based on the camera position and screen coordinates. The projected plane, the user can drag the handles on can be drawn via `ProtoGizmoUtils::debug_draw_handle_grid` on gizmo *redraw*.

### Calculate handle offset in 3D space

`ProtoGizmoUtils::get_handle_offset` calculates the offset of the dragged handle in the 3D space on a camera projected plane.

Properties:

- `camera: Camera3D` - Camera used for calculating the plane the `screen_pos` is projected on.
- `screen_pos: Vector2` - Screen position of the mouse cursor.
- `local_gizmo_position: Vector3` - Gizmo position in the node's local space.
- `local_offset_axis: Vector3` - Axis the handle can be dragged on in node's local space. Used for calculating the plane the `screen_pos` is projected on.
- `node: Node3D` - Node the gizmo is attached to. Used to get global transform and position.

Returns: `Vector3` - Offset of the dragged handle in the 3D space on a camera projected plane in global space.

Unfortunately, to get the proper offsets, projections, offsets and drawing of the gizmos, some transitions must be made between the local and global space to get the result. The `camera.position` is in global space, so the `local_gizmo_position` and `local_offset_axis` must be transformed to global space to get the proper offset from projecting `screen_pos` onto a global space plane.

#### Get camera oriented plane

The global plane is created by using 3 points:

- `global_gizmo_position` - The gizmo position in global space, transformed from `local_gizmo_position` with the Node3D's `global_position` and `global_transform.basis`.
- `global_offset_axis` - The axis the handle can be dragged on in global space, transformed from `local_offset_axis` with the Node3D's `global_transform.basis`.
- A point on the line defined by `camera.position` closest to another line defined by `global_gizmo_position` and `global_offset_axis`. The line with point `camera.position` is perpendicular to the other line and its axis is the plane's normal vector, so the plane is always oriented to the camera. The calculation is found in `ProtoGizmoUtils::get_camera_oriented_plane`.

The plane can be visualized by drawing a grid with `ProtoGizmoUtils::debug_draw_handle_grid`.
