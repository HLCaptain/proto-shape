# ProtoShape tooling

## Shapes

### [ProtoRamp](proto_ramp/README.md)

## Gizmos

There is a custom Gizmo made for ProtoRamp editing, but I plan on adding more shapes and more ways of editing them.

The gizmo only supports setting 3 properties:

- Width
- Height
- Depth

The gizmo is an `EditorNode3DGizmoPlugin` and is only visible when the `ProtoRamp` node is selected. Selection hightlights the mesh with a transparent blue color and shows handles, which you can drag to adjust the shape.

<video controls>
  <source src="assets/videos/use_gizmos.mp4" type="video/mp4">
</video>