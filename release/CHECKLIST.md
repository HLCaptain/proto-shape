# ProtoShape 1.2.0 Release Checklist

## Scope and version

- [ ] Confirm the final title is `ProtoShape - Ramps, Shapes and Gizmos`.
- [ ] Confirm `addons/proto_shape/plugin.cfg` and all release copy use version `1.2.0`.
- [ ] Confirm minimum Godot version `4.7`, validation version `4.7.2`, and no maximum Store version.
- [ ] Confirm the final integration commit contains only reviewed release work and the worktree is clean.

## Automated validation

- [ ] Run `godot --headless --editor --path . --quit-after 240 res://tests/test_proto_ramp_gizmos.tscn -- --proto-shape-tests` and check for its PASS marker and clean error log.
- [ ] Run a cache-free `godot --headless --path . --import` with the plugin initially disabled.
- [ ] Enable the plugin in the imported disposable project and run bounded `--editor --quit-after 120` startup.
- [ ] Run `bash tests/run.sh` from the repository root.
- [ ] Confirm the runner copies the project to a temporary directory before executing tests.
- [ ] Confirm runtime `SceneTree` scripts run directly and editor-only `@tool` `.tscn` tests run in editor mode with `--proto-shape-tests`.
- [ ] Confirm every test emits a `PASS:` completion marker and failures return a non-zero exit code.
- [ ] Confirm the runner scans combined stdout/stderr, including shutdown output, and rejects `SCRIPT ERROR`, `ERROR:`, leaked instances/resources, and leaked RID allocations.

## Focused regressions

- [ ] Verify `Path3D.curve_changed` refreshes active curves, detached old curves have no effect, short curves stay authored, and re-entry rebuilds off-tree edits.
- [ ] Verify edited thickness produces the same sampled cache as a fresh wall with the same final values.
- [ ] Verify `follow_use_bake_interval` follows native spacing direction within ProtoWall's 0.01-2.0 bounds.
- [ ] Verify authored rail thickness and lower height survive shrink/grow, undo/redo, and save/reload.
- [ ] Verify high rail counts and tiny heights fit and merge touching vertical intervals into clean sweep profiles.
- [ ] Verify tiny Ramp step values survive count/mode/type changes, cancel, undo/redo, duplication, and save/reload while generated dimensions remain valid.
- [ ] Verify invalid gizmo projections do not mutate shapes and all first-party providers use the nullable projection and boolean begin-drag contracts.

## Manual editor validation

- [ ] Enable ProtoShape and add `ProtoRamp` and `ProtoWall` from Add Child Node.
- [ ] Test every visible handle, arrow hover/drag, snapping, cancel, undo, and redo.
- [ ] Check all Ramp anchors and perspective/orthographic views under rotated and non-uniformly scaled parents; normal drag direction and sensitivity must still feel familiar.
- [ ] Confirm no first-click jumps, stationary-pointer drift, stale geometry, duplicated generated nodes, flicker, or sticky drag grids after commit/cancel. Repeat an edit after switching selected shapes.
- [ ] Confirm the lower-rail handle is hidden for one rail and starts at the effective rendered height for multiple rails.
- [ ] Test ProtoWall interpolation, orientation, posts, material, collision, and curve save/reload behavior.
- [ ] Run Power Cell Delivery from spawn through pickup and terminal delivery without jumping.
- [ ] Confirm its InputMap helper registers only missing namespaced demo actions and never changes or removes host-project mappings.
- [ ] Edit a ramp and wall in Power Cell Delivery, save/reload, and confirm authored scene changes persist.
- [ ] Confirm the standalone ProtoRamp navigation sample intentionally remains unbaked; do not apply that note to Power Cell Delivery.
- [ ] Confirm exported/runtime scenes do not depend on editor-only classes.

## Documentation and media

- [ ] Check all internal Markdown links and `res://` paths after the demo and API commits are integrated.
- [ ] Confirm the Power Cell Delivery thumbnail is an untouched 1920x1080 Godot render matching the delivered scene.
- [ ] Confirm no unresolved media placeholders or obsolete Asset Library submission fields remain; retain the existing hosted feature videos.
- [ ] Confirm `addons/proto_shape/LICENSE` is byte-identical to root `LICENSE`.

## Package

- [ ] Build `proto-shape-1.2.0.zip` from the final integrated commit, not an intermediate branch or dirty worktree.
- [ ] Confirm the ZIP root is `addons/proto_shape/` with no repository-name wrapper.
- [ ] Confirm it includes `LICENSE`, `README.md`, `plugin.cfg`, all runtime scripts, examples, the Store thumbnail, and all source art.
- [ ] Confirm it excludes root project files, `release/`, `.git*`, `.github/`, `.godot/`, and generated `.import` files.
- [ ] Install the exact ZIP into a fresh Godot 4.7.2 project and repeat the plugin, shape, demo, save/reload, and runtime checks.

## External ownership gates

- [ ] Push the reviewed feature branch and create one draft PR. Hand the final commit and release notes to the user; merging, tag creation/push, and GitHub release publication remain user-owned.
- [ ] After final validation, save the authorized Godot Asset Store draft metadata and upload the validated ZIP.
- [ ] Check Store `Stable` only after all final validation passes.
- [ ] Do not click Store `Publish` / `Submit for review`; review submission remains explicitly user-gated.
