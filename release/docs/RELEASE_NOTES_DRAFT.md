# Release Notes Draft

## Title

`ProtoShape 1.2.0`

## Summary

ProtoShape 1.2.0 expands the addon from `ProtoRamp` into a broader 3D blockout toolkit. This release adds `ProtoWall`, reworks the shared gizmo system with hoverable and directly draggable arrow bodies, and documents the provider interface for custom editor gizmos.

## Highlights

- New `ProtoWall` shape for path-based solid walls and rails using `Path3D` and `Curve3D`.
- Reworked `ProtoGizmo` arrow workflow with screen-space arrow hover, highlight, and direct arrow dragging.
- Modular gizmo provider interface for custom `Node3D` tools, including provider examples and wrapper examples.
- ProtoWall gizmos now align thickness and post-width arrows to the generated wall or rail segment across interpolation modes.
- ProtoWall post count editing is inspector-only; the 3D viewport keeps height, thickness, lower rail height, and post width handles focused.
- Icon assets moved into `addons/proto_shape/icons/` for shared tools and shape-local `icons/` folders for `ProtoRamp` and `ProtoWall`.

## Changes

### Gizmos

- Solid 3D arrows can be highlighted by cursor hover and dragged directly, without relying on Godot's native transform gizmo arrows.
- Arrow picking uses the projected screen-space shaft and head footprint, so hover matches the visible arrow more closely.
- Providers can expose arrow bodies with `get_arrow_drag_segments()`, `begin_arrow_drag()`, `set_arrow_drag()`, and `commit_arrow_drag()`.
- Arrow dragging uses the same snapping, cancel, redraw, and `EditorUndoRedoManager` commit paths as point handles.
- `ProtoGizmoWrapper` forwards optional arrow-drag callbacks from wrapped child nodes.

### ProtoWall

- Added `ProtoWall`, a `Path3D`-based wall and rail generator for level blockouts.
- Supports solid wall and rail styles, with generated CSG geometry following editable `Curve3D` paths.
- Useful for room and corridor walls, arena boundaries, low cover, parapets, platform lips, guardrails, fences, balcony rails, ramp-side rails, and variable-elevation rails.
- Includes multiple interpolation modes for flat, curved, corner-rounded, filleted, Bezier, Catmull-Rom, arc-line, parallel-transport, and linear path workflows.
- Includes example scenes for solid walls, rail use cases, mixed blockouts, and interpolation comparisons.
- Thickness and post-width gizmos now use segment-aligned axes so the arrows stay parallel or perpendicular to the visible generated span.
- `post_count` remains available in the inspector when post placement uses count mode, but it no longer has a dedicated 3D viewport gizmo.

### Documentation

- Updated root README and addon README with `ProtoWall` and the reworked gizmo workflow.
- Updated `ProtoGizmo` docs with the provider callback interface, arrow selection behavior, and examples.
- Updated `ProtoWall` README with use cases, properties, examples, and media placeholders.
- Updated shape-development docs with the shape-local icon convention.

## Media Placeholders

Add final media links before publishing:

- Overview video: `release/media/videos/proto-shape-1.2.0-overview.mp4` or hosted URL.
- ProtoWall overview video: `release/media/videos/proto-wall-overview.mp4` or hosted URL.
- ProtoWall overview screenshot: `release/media/screenshots/proto-wall-overview.png`.
- ProtoWall use-case screenshot: `release/media/screenshots/proto-wall-solid-rail-use-cases.png`.
- ProtoWall interpolation/thickness screenshot: `release/media/screenshots/proto-wall-interpolation-thickness.png`.
- ProtoWall post-width screenshot: `release/media/screenshots/proto-wall-post-width.png`.
- Gizmo arrow hover screenshot: `release/media/screenshots/proto-gizmo-arrow-hover.png`.
- Arrow hover and drag GIF: `release/media/gifs/arrow-hover-and-drag.gif`.

## Upgrade Notes

- If you reference addon icons directly, update paths from `addons/proto_shape/icon/` to the new `icons/` layout.
- `ProtoRamp` icon: `addons/proto_shape/proto_ramp/icons/proto-ramp-icon.png`.
- `ProtoWall` icon: `addons/proto_shape/proto_wall/icons/proto-wall-icon.png`.
- Shared addon and tool icons: `addons/proto_shape/icons/`.
- For `ProtoWall`, edit `post_count` through the inspector instead of a 3D viewport gizmo.

## Validation

- [ ] `godot --headless --path . --import`
- [ ] `godot --headless --path . --editor --quit`
- [ ] Manual editor check: add `ProtoRamp`, hover and drag arrow bodies, test snapping, cancel, undo, and redo.
- [ ] Manual editor check: add `ProtoWall`, test height, thickness, lower rail height, and post width handles across interpolation modes.
- [ ] Manual editor check: save and reload the ProtoWall example scenes.
