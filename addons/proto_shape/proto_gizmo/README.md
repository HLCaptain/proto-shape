# ProtoGizmo

ProtoGizmo is an `EditorNode3DGizmoPlugin` that provides a base for creating custom gizmos in the Godot editor. It is used to create custom gizmos for the `ProtoShape` addon. With the use of `ProtoGizmoWrapper`, you can create custom gizmos for your 3D nodes.

## Default materials

- `proto_handler` - Same as internal "handlers" material for gizmo handles, but blue instead of redish color.
- `selected` - Material for selected nodes (bluish transparent color).
- `main` - Base redish color material for general or debuging use. (Used for drawing camera projected debug planes).

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