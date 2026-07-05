# Godot Asset Library Copy Draft

## Short Description

Fast Godot 4.x blockout shapes with CSG generation, path-based walls and rails, and reusable editor gizmo tooling.

## Long Description

ProtoShape is a Godot 4.x editor plugin for quickly blocking out 3D levels and gameplay spaces with dynamic CSG-based shapes.

Version 1.2.0 includes:

- `ProtoRamp`: adjustable ramps and staircases with viewport gizmos, grid snapping, collision support, and navigation-mesh workflow support.
- `ProtoWall`: a new `Path3D`/`Curve3D`-based wall and rail shape for straight, curved, sloped, and variable-elevation paths.
- `ProtoGizmo`: reusable editor gizmo tooling for custom `Node3D` providers.
- `ProtoGizmoWrapper`: a signal-based bridge for adding gizmos to wrapped child nodes.

`ProtoWall` can be used for room walls, corridor walls, arena boundaries, low cover, parapets, platform lips, guardrails, bridge rails, fences, balcony rails, ramp-side rails, map perimeter fencing, and mountain-road style rails. Paths are edited with Godot's native curve tools, while ProtoShape gizmos adjust dimensions such as wall height, thickness, lower rail height, and post width.

The gizmo system now supports solid 3D arrow guides that highlight on cursor hover and can be dragged directly. Custom gizmo providers can expose arrow segments through a small callback interface while still using their own property math, snapping, cancel behavior, and undo/redo commits.

## Release Update Text

ProtoShape 1.2.0 adds a new path-based `ProtoWall` shape and reworks the shared gizmo system:

- New `ProtoWall` solid wall and rail generator based on `Path3D` and `Curve3D`.
- Hoverable, directly draggable arrow-body gizmos for faster viewport editing.
- Screen-space arrow-footprint picking for more accurate hover highlights.
- Modular provider callbacks for custom nodes and `ProtoGizmoWrapper` children.
- ProtoWall thickness and post-width gizmo alignment across interpolation modes.
- Shape-local icon folders for `ProtoRamp` and `ProtoWall`, plus a shared `addons/proto_shape/icons/` library.

## Media Links

- Cover screenshot: TODO `release/media/screenshots/assetlib-cover.png`
- ProtoWall overview screenshot: TODO `release/media/screenshots/proto-wall-overview.png`
- ProtoWall use-case screenshot: TODO `release/media/screenshots/proto-wall-solid-rail-use-cases.png`
- Gizmo arrow hover GIF: TODO `release/media/gifs/arrow-hover-and-drag.gif`
- ProtoWall overview video: TODO `release/media/videos/proto-wall-overview.mp4` or hosted URL
- 1.2.0 overview video: TODO `release/media/videos/proto-shape-1.2.0-overview.mp4` or hosted URL

## Compatibility

- Godot version: 4.7 target
- Addon version: 1.2.0
