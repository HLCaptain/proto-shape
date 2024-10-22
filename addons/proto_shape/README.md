# ProtoShape tooling

## Shapes

- [ProtoRamp](proto_ramp/README.md)

## Gizmos

The gizmo for `ProtoRamp` supports setting 3 properties:

- Width
- Height
- Depth

It utilizes `ProtoGizmoUtils` for advanced 3D math calculations and plane projections to get the desired handle drag offset and set the properties accordingly.

### Undo/Redo support

[ProtoRampGizmos](proto_ramp/proto_ramp_gizmos.gd) supports scene-wide undo/redo functionality. It uses the `EditorUndoRedoManager` to set up ramp properties, so the editor takes gizmo-based modifications into account! Editor now warns you to save on exit if you have unsaved changes made with the gizmos.

### [ProtoGizmoWrapper](proto_gizmo_wrapper/README.md)

`ProtoGizmoWrapper` is an advanced wrapper for creating gizmo functionality for custom 3D nodes. It exposes 2 signals to implement custom gizmos for your nodes to *redraw* and *update* the properties of your node.

The gizmo is an `EditorNode3DGizmoPlugin` and is visible when the `ProtoRamp` node or a children of `ProtoGizmoWrapper` is selected. Selection hightlights the mesh with a transparent blue color and shows handles, which you can drag to adjust the shape.

https://github.com/HLCaptain/proto-shape/assets/22623259/1db3f18d-4d90-400f-9d33-7b03d44f62c7
