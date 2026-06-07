# ProtoGizmo Examples

These examples show how to use `ProtoGizmo` and `ProtoGizmoUtils` for custom reactive `Node3D` shapes.

## Provider Box

Open `provider_box/example_proto_box.tscn` to see the direct provider pattern. The shape exposes `get_proto_gizmo_provider()` and returns an editor-only helper that draws width, height, and depth handles.

## Directional Beam

Open `directional_beam/example_directional_beam.tscn` to see dynamic handle axes. The length and thickness handle directions are recalculated from the current `direction_degrees` value every time the gizmo is redrawn or dragged.

## Wrapped Volume

Open `wrapper_volume/example_wrapped_volume.tscn` to see the `ProtoGizmoWrapper` signal pattern. The child shape connects to wrapper signals instead of exposing a provider directly.

Each example supports handle dragging, grid snapping through `Ctrl`, fine snapping through `Ctrl + Shift`, and undo/redo through `EditorUndoRedoManager`.

The example shapes expose `get_proto_gizmo_selection_nodes()` so their generated CSG bodies can be clicked to select the owner node, not just the small gizmo handles.
