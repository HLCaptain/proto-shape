# ProtoWall

ProtoWall is a path-based wall and rail shape for blocking out game environments. It extends `Path3D`, so the same node can create straight walls, curved walls, low cover, guardrails, fences, balcony rails, and ramp-side rails by changing the path and style.

<img src="icons/proto-wall-icon.svg" style="height: 30%; width: 30%; margin: 0 auto; display: block">

## Usage

Add `ProtoWall` from the Add Child Node menu. The default node creates a straight solid wall along a two-point `Path3D` curve.

Edit the path with Godot's normal `Path3D` curve tools. `ProtoWall` regenerates the generated CSG geometry whenever the curve changes.

## Use Cases

Use `ProtoWall` when a blockout needs path-driven geometry that is faster to reshape than individual CSG boxes:

- Solid room, corridor, arena, and perimeter walls.
- Low cover, parapets, platform lips, and collision blockers.
- Guardrails, bridge rails, balcony rails, fences, and temporary guide rails.
- Ramp-side rails and variable-elevation paths that need to follow a 3D curve.
- Curved or rounded wall sections where the path should remain editable with Godot's native `Curve3D` tools.

## Styles

### Solid

`Solid` creates a continuous wall body along the path. Use it for:

- Room and corridor walls
- Arena boundaries
- Low cover
- Parapets
- Platform lips
- Curved environment blockers

### Rail

`Rail` creates horizontal rail bars along the path and optional generated posts sampled along the curve. Use it for:

- Bridge rails
- Balcony rails
- Ramp-side rails
- Fences
- Arena safety rails
- Pipe-like temporary guides

## Properties

Common properties:

- `style` - Solid wall or rail generation.
- `height` - Total wall or rail height.
- `thickness` - Horizontal footprint width of the wall, rail bars, and rail posts.
- `side` - Align generated geometry on the path center, left side, or right side.
- `path_orientation` - Use `Path Perpendicular` to tilt the wall frame with sloped paths, or `Fixed Up` to keep wall height aligned to `Vector3.UP`.
- `path_interpolation` - Choose how the path is sampled for generated wall/rail geometry and posts.
- `corner_rounding` - For corner-based interpolation modes, controls how much of each adjacent segment is used to smooth corners.
- `corner_angle_step` - For corner-based modes and `Parallel Transport Bezier`, limits the angle per generated curved segment. Higher values reduce triangles.
- `sample_simplify_angle` - Reduces generated samples with a bounded-error simplifier. It is hidden for `Linear`, where the control points are already the final path samples. Set to `0` to disable simplification.
- `preserve_vertical_spikes` - Keeps abrupt vertical hills or dips as sharp points instead of smoothing through them. It appears only on smoothing modes where it changes generated samples, and is off by default so interpolation works in full 3D for vertical and horizontal path changes.
- `vertical_spike_aggressiveness` - Controls how easily `preserve_vertical_spikes` treats vertical hills/dips as protected sharp points. Lower values preserve only more extreme spikes; higher values preserve more vertical height changes. This is shown only when `preserve_vertical_spikes` is enabled.
- `path_sample_spacing` - ProtoWall's generated path sample spacing for wall/rail sections and posts. It is hidden for `Linear`, and hidden in `Follow Curved Path3D` when `follow_use_bake_interval` is enabled.
- `follow_use_bake_interval` - `Follow Curved Path3D` only. Uses `Curve3D.bake_interval` as the spacing between generated samples, clamped to ProtoWall's supported 0.01-2.0 range, and ignores `path_sample_spacing`.
- `direction_source` - Chooses whether sampled orientation and gizmos follow final generated segments or the selected interpolation mode's sampled tangents. Posts always align their depth to the generated rail segment they are placed on.
- `Curve3D` point tilt - When `path_orientation` is `Path Perpendicular`, point tilt is interpolated and applied as roll around the sampled path direction.
- `curve.closed` - Close the referenced `Path3D` curve itself to make looped walls and rails.
- `collisions_enabled` - Enables collision on generated CSG parts.
- `material` - Material applied to generated wall, rail, and post parts.

Generated wall/rail sweep meshes have positions and normals but no UV or tangent attributes. Use solid-color or world/triplanar materials for blockouts; UV-dependent textures and tangent-space normal maps need a later mesh-authoring step.

Rail-only properties:

- `rail_count` - Number of horizontal rails.
- `rail_thickness` - Authored vertical thickness of each rail bar. If the current height and rail count cannot fit it, generated geometry uses a smaller effective thickness without overwriting the Inspector value.
- `lower_rail_height` - Authored center height of the lowest rail when multiple rails are used. Generated geometry clamps an effective height so every rail fits without overwriting the Inspector value, making height and count changes reversible.
- `post_enabled` - Generates posts along the path.
- `post_placement` - Place posts by fixed spacing or by explicit count.
- `post_spacing` - Distance between posts along the baked curve when `post_placement` is `Spacing`.
- `post_count` - Number of posts distributed along the curve when `post_placement` is `Count`.
- `post_width` - Post width along the wall/rail path.
- `post_at_start` - Adds a post at the first path point.
- `post_at_end` - Adds a post at the final path point for open paths.

## Gizmos

`ProtoWall` uses the shared `ProtoGizmo` provider workflow. Solid 3D arrows start at each handle icon and point in the direction the handle can be dragged. Hovering an arrow highlights it, and dragging the arrow body edits the same property as the small handle icon. Select a `ProtoWall` node to edit:

- Height handle - adjusts `height`.
- Thickness handle - adjusts `thickness` according to the current `side` alignment.
- Lower rail handle - adjusts `lower_rail_height` when `style` is `Rail` and two or more rails are generated. The handle starts at the effective rendered height when the authored value is outside the current wall.
- Post width handle - adjusts the along-path `post_width` when posts are enabled.

Hold <kbd>Ctrl</kbd> for 1.0 unit snapping and <kbd>Ctrl</kbd> + <kbd>Shift</kbd> for 0.1 unit fine snapping.

## Examples

Open these scenes to test common game-development setups:

- `examples/proto_wall_solid_examples.tscn` - straight walls, low cover, curved walls, and path alignment.
- `examples/proto_wall_rail_examples.tscn` - guardrails, single rails, three-rail fences, curved rails, postless rails, and a variable-elevation rounded mountain rail.
- `examples/proto_wall_mixed_blockout.tscn` - closed boundary walls, balcony rails, ramp rails, map perimeter fencing, and mountain road rails.
- `examples/proto_wall_interpolation_showcase.tscn` - every interpolation mode compared against the same flat XZ and elevated curves, with both `Path Perpendicular` and `Fixed Up` orientation variants shown as solid wall and rail pairs.

Each launcher generates its editable nodes once. Save the scene after generation to retain your edits; later opens do not restore renamed or deleted examples. The interpolation showcase creates 80 `ProtoWall` nodes and may take several seconds to finish in the editor.

## Release Media Placeholders

Capture or link these before publishing 1.2.0:

- Overview video: `../../../release/media/videos/proto-wall-overview.mp4` or a hosted video link.
- Overview screenshot: `../../../release/media/screenshots/proto-wall-overview.png`.
- Solid and rail use-case screenshot: `../../../release/media/screenshots/proto-wall-solid-rail-use-cases.png`.
- Interpolation/thickness screenshot: `../../../release/media/screenshots/proto-wall-interpolation-thickness.png`.
- Post-width gizmo screenshot: `../../../release/media/screenshots/proto-wall-post-width.png`.
- Short interaction loop: `../../../release/media/gifs/proto-wall-thickness-interpolation.gif`.

## Implementation Notes

The runtime shape script owns generated CSG nodes and remains export-safe. Editor-only gizmo code is loaded only behind `Engine.is_editor_hint()`.

Generated solid walls and rail bars are closed `CSGMesh3D` sweep meshes built from sampled `Path3D` points. Rail posts are generated `CSGBox3D` nodes placed from the same sampled path cache, and their depth axis is aligned to the generated rail segment at the post offset so posts stay parallel to the rail span.

Rail thickness and lower height remain authored Inspector values. Rendering derives values that fit the current height and rail count, and touching or overlapping vertical rail intervals are merged before sweeping so they do not create duplicate internal rail surfaces.

`path_orientation` controls both mesh sweep sections and post transforms. `Path Perpendicular` follows each interpolation mode's sampled 3D tangent and applies interpolated `Curve3D` point tilt as explicit roll, which is useful for rails on top of `ProtoRamp` where the curve rises from `Y=0` to `Y=1`. `Fixed Up` follows the path horizontally while keeping wall height upright.

`path_interpolation` controls the shared sample path:

- `Baked Linear` - predictable segmented sampling from Godot's baked curve.
- `Baked Cubic` - smoother sampling between Godot's baked points.
- `Bezier` - evaluates each `Curve3D` segment from its in/out handles before building arc-length samples.
- `Corner Rounded` - keeps control-point segments straight except for bounded cubic blends near corners, reducing overshoot on tight or steep Y-shifted points. Corners that are too tight for the current thickness use a short rounded fallback instead of a single flat bevel.
- `Fillet Path` - keeps control-point segments straight and uses circular fillets in each local 3D corner plane.
- `Centripetal Catmull-Rom` - creates a continuous smooth curve through the control points with less overshoot than uniform Catmull-Rom.
- `Arc Line` - keeps straight spans and uses horizontal circular turning arcs with linear elevation between corner entry and exit points, useful for road-like or mountain rail layouts. Corners that are too tight for the current thickness use the same short rounded fallback as `Corner Rounded`.
- `Parallel Transport Bezier` - uses adaptive Bezier sampling in both orientations, with rotation-minimizing transported frames when `path_orientation` is `Path Perpendicular`. Use this when you need twist-minimized Bezier rails; other modes use local tangent frames to avoid slope pitch propagating through later segments.
- `Follow Curved Path3D` - samples Godot's baked `Curve3D` directly with cubic interpolation. Use this when you want generated geometry to follow the edited `Path3D` curve as closely as Godot's own baked path cache allows. By default, generated samples are placed every `path_sample_spacing` units along the curve without changing `Curve3D.bake_interval`.
- `Linear` - connects the `Curve3D` control points with straight segments and ignores Bezier handles. `path_sample_spacing` and `sample_simplify_angle` are not used. Corner frames use the angle bisector between incoming and outgoing segments, and corner sections apply miter scaling so the wall or rail thickness stays consistent through turns.

Godot's `Curve3D.bake_interval` controls the distance between cached baked curve points inside the `Curve3D` resource. ProtoWall leaves that value alone. In `Follow Curved Path3D`, enable `follow_use_bake_interval` to use that interval between generated samples within ProtoWall's 0.01-2.0 spacing range: lower values create more sections and higher values create fewer. When enabled, `path_sample_spacing` is ignored.

Corner-based modes are optimized for long rail paths: straight spans generate only endpoints and rounded corners use adaptive subdivisions. All non-Linear interpolation modes use `sample_simplify_angle` to reduce redundant sections after their initial sampling pass. The simplifier is Ramer-Douglas-Peucker-like: it removes points only when the resulting segment stays within a small chord-distance tolerance derived from the angle threshold and does not exceed tangent or tilt error limits. Structural anchors such as endpoints, control points, and corner entry/exit points are preserved, while generated interior subdivision points can be removed safely.

`direction_source` controls how sampled orientation is computed. `Generated Segment` rebuilds sample directions from the final simplified polyline and uses the containing generated segment's direction directly, keeping sampled wall sections parallel to the optimized wall/rail segment. `Interpolation Tangent` uses tangents from the selected interpolation mode and interpolates those basis vectors for smoother orientation. The thickness and post-width gizmos use segment-aligned axes so their drag arrows stay parallel or perpendicular to the visible generated span. Rail posts are always segment-aligned so their rectangular depth stays parallel to the visible rail span.

By default, interpolation treats vertical and horizontal control-point changes the same way, so modes such as `Centripetal Catmull-Rom`, `Corner Rounded`, `Fillet Path`, and `Bezier` can smooth hills and dips even when the path is mostly straight in the XZ plane. Enable `preserve_vertical_spikes` when you need a short, mostly vertical hill or dip to stay sharp instead of being smoothed through. Use `vertical_spike_aggressiveness` to tune how easily those vertical points are protected.

For best results, keep paths mostly horizontal or gently sloped. Advanced twisting/vertical path cases are not the primary target of the first implementation.
