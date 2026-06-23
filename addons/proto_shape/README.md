# ProtoShape tooling

## Shapes

- [ProtoRamp](proto_ramp/README.md)
- [ProtoWall](proto_wall/README.md)

## Gizmos

The gizmo for `ProtoRamp` supports editing these properties in the 3D viewport:

- Width
- Height
- Depth
- Fill

It utilizes `ProtoGizmoUtils` for advanced 3D math calculations and plane projections to get the desired handle drag offset and set the properties accordingly.

The gizmo for `ProtoWall` supports editing these properties in the 3D viewport:

- Height
- Thickness
- Lower rail height for rail-style walls
- Post width and post count for rail-style walls with posts

`ProtoWall` is a `Path3D`-based shape, so the wall or rail path is edited with Godot's native path tools while ProtoShape gizmos handle wall dimensions. Its `path_orientation` can tilt geometry with sloped paths or keep wall height upright, `path_interpolation` controls how the shared rail/post sample path is generated, and `Curve3D` point tilt is applied in path-perpendicular mode. Corner-based interpolation modes keep straight spans light while adaptively smoothing corners.

`ProtoGizmo` is a reusable `EditorNode3DGizmoPlugin`. Custom `Node3D` shapes can expose a provider through `get_proto_gizmo_provider()` or use `ProtoGizmoWrapper` as a signal bridge for child nodes.

See [ProtoGizmo examples](proto_gizmo/examples/README.md) for custom shapes using provider-based gizmos, dynamic handle axes, and wrapper signals.

See [Shape Development Guide](SHAPE_DEVELOPMENT.md) for the shared implementation pattern and documentation requirements for new shapes.

### Undo/Redo support

[ProtoRampGizmos](proto_ramp/proto_ramp_gizmos.gd) supports scene-wide undo/redo functionality. It uses the `EditorUndoRedoManager` to set up ramp properties, so the editor takes gizmo-based modifications into account! Editor now warns you to save on exit if you have unsaved changes made with the gizmos.

### [ProtoGizmoWrapper](proto_gizmo_wrapper/README.md)

`ProtoGizmoWrapper` is an advanced wrapper for creating gizmo functionality for custom 3D nodes. It exposes signals to implement custom gizmos for your nodes to *redraw*, *update*, and *commit* property changes.

The gizmo is an `EditorNode3DGizmoPlugin` and is visible when a node with a gizmo provider or a child of `ProtoGizmoWrapper` is selected. Selection highlights the mesh with a transparent blue color and shows handles, which you can drag to adjust the shape.

https://github.com/HLCaptain/proto-shape/assets/22623259/1db3f18d-4d90-400f-9d33-7b03d44f62c7
