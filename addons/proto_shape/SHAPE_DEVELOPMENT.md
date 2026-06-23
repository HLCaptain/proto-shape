# Shape Development Guide

This guide describes the shared pattern for adding new ProtoShape nodes. New shapes should help level designers and gameplay programmers block out environments faster than raw CSG nodes, while staying simple enough to adjust directly in the editor.

## Goals

- Prefer practical map-building workflows over mathematically complete modeling tools.
- Keep each shape reactive: inspector changes and gizmo drags should regenerate the generated CSG safely.
- Keep runtime-safe shape logic separate from editor-only gizmo code.
- Make every user-facing shape easy to discover, test, and understand through docs, media, and example scenes.

## Required Files

For a new shape named `ProtoWall`, use this structure:

```text
addons/proto_shape/proto_wall/
  proto_wall.gd
  proto_wall_gizmos.gd
  README.md
  examples/
    proto_wall_example.tscn
  assets/
    proto_wall_screenshot.png
```

The custom type icon should live in the shared icon folder:

```text
addons/proto_shape/icon/proto-wall-icon.png
addons/proto_shape/icon/proto-wall-icon.svg
```

## Runtime Shape Script

The runtime script owns the public API, inspector properties, generated CSG nodes, and selection hook.

```gdscript
@tool
extends Node3D

var generated_shape: CSGShape3D = null
var gizmos = null

func get_proto_gizmo_provider() -> Variant:
	return gizmos

func get_proto_gizmo_selection_nodes() -> Array:
	return [generated_shape]

func _enter_tree() -> void:
	refresh_shape()
	if Engine.is_editor_hint():
		var ProtoWallGizmos = load("res://addons/proto_shape/proto_wall/proto_wall_gizmos.gd")
		gizmos = ProtoWallGizmos.new()
		gizmos.attach_shape(self)
```

Shape scripts should:

- Use `@tool` so the editor updates generated geometry immediately.
- Use exported inspector properties with setters/getters.
- Clamp dimensions to valid positive values.
- Call `refresh_shape()` after relevant property changes.
- Call `update_gizmos()` after property changes that affect handles.
- Implement `_property_can_revert()` and `_property_get_revert()` for inspector-facing properties.
- Return generated CSG or mesh nodes from `get_proto_gizmo_selection_nodes()` so users can click the generated shape to select the owner node.
- Guard `remove_child()` calls with `child.get_parent() == self` when cleaning up generated children.

## Gizmo Provider Script

The gizmo provider is editor-only and should be loaded only behind `Engine.is_editor_hint()`.

```gdscript
const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo_utils.gd")

var shape = null
var gizmo_utils := ProtoGizmoUtils.new()

func attach_shape(node) -> void:
	shape = node

func remove_shape() -> void:
	shape = null

func redraw_gizmos(gizmo, plugin) -> void:
	gizmo.clear()
	# Add handles and optional guide lines here.

func set_handle(gizmo, plugin, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	# Use ProtoGizmoUtils to project cursor motion onto a dynamic local axis or plane.

func commit_handle(gizmo, plugin, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	# Use plugin.undo_redo for committed property changes.
```

Gizmo providers should:

- Draw handles with `plugin.get_material("proto_handler", gizmo)`.
- Use dynamic handle axes when shape state changes the direction of a drag.
- Support normal snapping through `plugin.snapping` and fine snapping through `plugin.fine_snapping`.
- Use `EditorUndoRedoManager` through `plugin.undo_redo` in `commit_handle()`.
- Avoid owning shape state that must survive save/reload.

## Public API

Treat these as public API once released:

- Inspector property names, default values, ranges, and enum options.
- Signals emitted by property setters.
- Anchor behavior and coordinate conventions.
- `_property_can_revert()` / `_property_get_revert()` values.
- Save/reload behavior of generated shapes.

Avoid backward-compatibility shims before release, but be careful once a property has shipped in a tagged version.

## Documentation Requirements

Every new user-facing shape must include:

- A shape README explaining the use case, properties, gizmo handles, snapping, collision behavior, and limitations.
- At least one example scene that can be opened directly in Godot.
- A custom Add Node icon in `addons/proto_shape/icon/`.
- A screenshot, GIF, video, or linked external video showing the shape in use.
- Links from the root `README.md` and `addons/proto_shape/README.md`.

Use local `assets/` folders for committed screenshots, sketches, and diagrams. If a video is hosted externally, link it from the shape README and keep a small local screenshot as the stable preview.

## Example Scene Requirements

Each shape example scene should demonstrate:

- The default shape.
- At least one non-default configuration.
- Gizmo handles in a practical blockout layout.
- Collision/navigation behavior when the shape supports it.
- Save/reload-safe generated geometry.

Keep example scenes inside the shape folder unless they are shared showcase scenes:

```text
addons/proto_shape/proto_wall/examples/proto_wall_example.tscn
```

## ProtoWall Design Notes

`ProtoWall` is path-based and should cover both wall and rail workflows. Its value is faster environment blocking for walls, fences, guardrails, parapets, room edges, and curved boundaries.

Compared with a regular `CSGBox3D`, `ProtoWall` provides:

- Path-based generation by extending `Path3D`.
- Solid wall and rail styles through one shape.
- Wall-focused properties: `height`, `thickness`, side alignment, collisions, and material.
- Rail-focused properties: rail count, rail thickness, lower rail height, post spacing, and post size.
- Path orientation, interpolation, corner rounding, sample simplification, and point tilt for sloped or irregular paths, including ramp-side rails and variable-elevation rails that change across all 3 axes.
- Drag handles for wall dimensions without switching to scale mode.
- Native Godot path editing for straight and curved wall paths.
- Grid-snapped handle editing for map blockouts.
- Click-selection through generated geometry.
- Future wall-specific extensions such as openings, trim, fence modes, or connection helpers.

The first implementation uses generated closed `CSGMesh3D` sweep meshes for solid walls and rail bars, plus generated `CSGBox3D` posts sampled along the same path cache. The selected path orientation, interpolation, corner rounding, sample simplification, and point tilt must apply to both the sweep mesh and generated post basis so irregular 3D rails do not mix different pitch, roll, or offset calculations. Door/window openings, trims, and extra fence styles can follow after the path workflow is proven.

## Verification Checklist

For each new shape, run available CLI checks:

```sh
godot --headless --path . --check-only --script addons/proto_shape/proto_wall/proto_wall.gd
godot --headless --path . --check-only --script addons/proto_shape/proto_wall/proto_wall_gizmos.gd
godot --headless --path . --editor --quit
```

Manual editor checks are required for gizmo behavior:

- Add the shape from the Add Child Node menu.
- Drag every handle.
- Test `Ctrl` snapping and `Ctrl + Shift` fine snapping.
- Test undo/redo after handle edits.
- Click the generated shape to select the owner node.
- Save and reload example scenes.
- Confirm exported/runtime scenes do not depend on editor-only classes.
