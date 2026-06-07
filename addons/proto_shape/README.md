# ProtoShape tooling

## Shapes

- [ProtoRamp](proto_ramp/README.md)

## Gizmos

The gizmo for `ProtoRamp` supports editing these properties in the 3D viewport:

- Width
- Height
- Depth
- Fill

It utilizes `ProtoGizmoUtils` for advanced 3D math calculations and plane projections to get the desired handle drag offset and set the properties accordingly.

`ProtoGizmo` is a reusable `EditorNode3DGizmoPlugin`. Custom `Node3D` shapes can expose a provider through `get_proto_gizmo_provider()` or use `ProtoGizmoWrapper` as a signal bridge for child nodes.

See [ProtoGizmo examples](proto_gizmo/examples/README.md) for custom shapes using provider-based gizmos, dynamic handle axes, and wrapper signals.

### Undo/Redo support

[ProtoRampGizmos](proto_ramp/proto_ramp_gizmos.gd) supports scene-wide undo/redo functionality. It uses the `EditorUndoRedoManager` to set up ramp properties, so the editor takes gizmo-based modifications into account! Editor now warns you to save on exit if you have unsaved changes made with the gizmos.

### [ProtoGizmoWrapper](proto_gizmo_wrapper/README.md)

`ProtoGizmoWrapper` is an advanced wrapper for creating gizmo functionality for custom 3D nodes. It exposes signals to implement custom gizmos for your nodes to *redraw*, *update*, and *commit* property changes.

The gizmo is an `EditorNode3DGizmoPlugin` and is visible when a node with a gizmo provider or a child of `ProtoGizmoWrapper` is selected. Selection highlights the mesh with a transparent blue color and shows handles, which you can drag to adjust the shape.

https://github.com/HLCaptain/proto-shape/assets/22623259/1db3f18d-4d90-400f-9d33-7b03d44f62c7
