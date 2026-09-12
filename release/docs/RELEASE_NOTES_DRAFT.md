# ProtoShape 1.2.0

ProtoShape 1.2.0 expands the addon from `ProtoRamp` into a broader Godot 4.7 blockout toolkit. It adds the path-driven `ProtoWall`, safer reusable gizmo contracts, reversible rail editing, and an editable Power Cell Delivery example map.

## Highlights

- Added `ProtoWall` for path-based solid walls and rails using `Path3D` and `Curve3D`.
- Added hoverable, directly draggable solid gizmo arrows with screen-space picking, snapping, cancel, and undo/redo.
- Added Power Cell Delivery, a short playable example that combines varied ramps, walls, rails, and a power-cell delivery objective.
- Added a native 1920x1080 Godot-rendered thumbnail of the delivered example.

## ProtoWall

- Supports solid walls, rails, posts, side alignment, collision, material assignment, path orientation, point tilt, and multiple interpolation modes.
- Uses native `Path3D.curve_changed` lifecycle updates instead of editor polling and preserves intentionally empty or one-point curves.
- Invalidates sampled paths when wall thickness changes, keeping edited caches equivalent to freshly configured walls.
- Uses `Curve3D.bake_interval` in its native spacing direction for Follow Curved Path3D, within ProtoWall's supported 0.01-2.0 range.
- Preserves authored rail thickness and lower-rail height through height/count changes, undo/redo, and save/reload.
- Derives effective rail values that fit the current height/count and merges touching vertical intervals before generating sweep geometry.
- Starts the lower-rail gizmo at its effective rendered height while retaining the raw authored value for cancel and undo. The handle is hidden when only one rail is generated.
- Keeps the thickness drag reference frame fixed during an edit, so resampling a corner cannot feed back into a stationary pointer. The next drag uses the updated frame.

## Gizmos

- Generalized `ProtoGizmo` around reusable providers and `ProtoGizmoWrapper` children.
- Projection helpers return a nullable `Vector3`; unresolved camera-plane intersections are rejected without mutating the edited shape.
- `begin_arrow_drag()` returns `bool` so providers can reject an invalid drag before it becomes active.
- Updated all first-party providers and wrapper forwarding to the nullable projection and boolean begin-drag contracts.
- `ProtoGizmoWrapper.set_handle_for_child_signal` passes `plugin` as its second argument, and `commit_handle` now includes `plugin` in the same position.
- Generated `CSGShape3D` and `MeshInstance3D` nodes can provide click-selection geometry for their owning custom node.
- Editor snapping no longer registers or deletes host InputMap actions. Ramp providers release their plugin references and use stable per-node handle IDs.
- Completed Ramp drags clear transient grids and omit unchanged undo actions.

## ProtoRamp

- Validates dimensions and step count without inflating small per-step values during scene loading.
- Preserves the total silhouette through repeated calculation/type conversions, without accumulated epsilon drift.
- Retains authored tiny step dimensions when changing step count; generated dimensions apply the minimum without making undo destructive.
- Stores hidden staircase calculation and step-count settings while displaying a ramp.
- Corrects both fill arrows and their relative drag projection.

## Examples and documentation

- Added direct-provider, dynamic-axis, and wrapper gizmo examples.
- Added ProtoWall scenes covering solid walls, rail layouts, mixed blockouts, elevation, and interpolation modes.
- Added the editable Power Cell Delivery map as a hands-on addon example, not a standalone game.
- Demo controls use namespaced InputMap actions exposed in the example project's settings; installed examples register only missing defaults.
- ProtoWall showcase initialization is stored, so saved property changes, additions, renames, and deletions survive reopening.
- Updated shape, gizmo, wrapper, and development documentation.
- Moved shared icons to `addons/proto_shape/icons/` and shape icons into shape-local `icons/` folders.

## Upgrade notes

- ProtoShape 1.2.0 requires Godot 4.7 or later and is validated with Godot 4.7.2.
- Custom gizmo providers must handle nullable projection results and return success from `begin_arrow_drag()`.
- Wrapped children must use the corrected callback argument order described above.
- No compatibility bridge is provided for older wrapper callback signatures or the pre-release arrow-provider contract.
- Direct icon references must move from `addons/proto_shape/icon/` to the new shared or shape-local paths.

## Current limitations

- Generated ProtoWall sweep meshes contain positions, normals, and indices, but no UV or tangent attributes. UV-dependent and tangent-space workflows are unsupported; solid-color and world/triplanar materials may work.
- The standalone ProtoRamp example intentionally ships with an unbaked `NavigationMesh`; bake it in the editor to test navigation generation. This does not describe the Power Cell Delivery map.

## Issue

ProtoWall implements the core request tracked in [#11](https://github.com/HLCaptain/proto-shape/issues/11).
