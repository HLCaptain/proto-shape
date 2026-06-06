# AGENTS.md

Guidance for AI agents making changes in this repository.

## Project Summary

ProtoShape is a Godot 4.x editor plugin for fast 3D prototyping. It adds dynamic CSG-based shapes, currently `ProtoRamp`, and reusable editor gizmo tooling through `ProtoGizmo`, `ProtoGizmoUtils`, and `ProtoGizmoWrapper`.

The addon lives under `addons/proto_shape/`. Keep plugin resources, preloads, icons, scenes, and `plugin.cfg` paths compatible with Godot's `res://addons/proto_shape/...` layout.

## Change Principles

- Prefer small, focused changes that preserve existing editor behavior.
- Follow Godot's GDScript style guide and the local style: tabs for indentation, static typing where practical, and typed signals/properties unless editor-only types would break packaged games.
- Treat inspector-facing properties, signals, defaults, and `_property_can_revert` / `_property_get_revert` behavior as public API.
- Keep runtime-safe shape logic separate from editor-only gizmo/plugin logic. Use `Engine.is_editor_hint()` and dynamic typing around `EditorNode3DGizmo`, `EditorNode3DGizmoPlugin`, and related editor classes when needed to avoid export/package issues.
- Preserve gizmo workflows: handle dragging should update the node, redraw gizmos, support grid snapping, and use `EditorUndoRedoManager` for committed editor changes.
- Avoid adding broad abstractions unless a feature clearly needs reuse across multiple shapes or gizmos.

## Documentation

- Update `README.md` and the relevant `addons/proto_shape/**/README.md` when adding larger features, shapes, gizmos, or user-visible behavior.
- Keep feature docs understandable but not excessive, and link related files or docs when useful.
- Put diagrams, sketches, videos, or screenshots in an appropriate local `assets` folder only when they clarify the feature.

## Verification

No automated test suite is documented. If the `godot` command is available, run relevant CLI checks such as `godot --headless --path . --import`, `godot --headless --path . --editor --quit`, and script-specific parse/smoke checks when practical.

For code changes, validate in the Godot editor when possible: enable the `ProtoShape` plugin, add affected nodes from the Add Child Node menu, check for script errors, drag gizmo handles, test grid snapping and undo/redo, save/reload affected scenes, and confirm exported/runtime scenes do not depend on editor-only classes. If manual editor regression checks are necessary but cannot be run, clearly tell the user what still needs manual validation.
