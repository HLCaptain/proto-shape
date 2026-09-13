# ProtoShape 1.2.0 Release Checklist

Release-specific checks supplement [the reusable release checklist](../README.md).
See [the implementation record](IMPLEMENTATION.md), [release notes](docs/RELEASE_NOTES_DRAFT.md),
[Store draft](docs/ASSET_STORE_SUBMISSION_DRAFT.md), and [thumbnail record](media/screenshots/README.md).

User sign-off on 2026-09-13: "Everything is fine" / "Go ahead". Preserve the
latest user-provided thumbnail and include the continuous demo rails and fitted
posts. The commit-built archive, fresh installation, native export, and draft PR
are verified below. Store authentication, upload, and saved draft checks remain pending.

## Scope and version

- [x] Confirm the final title is `ProtoShape - Ramps, Shapes and Gizmos`.
- [x] Confirm `addons/proto_shape/plugin.cfg` and release copy use version `1.2.0`.
- [x] Record minimum Godot version `4.7`, validation version `4.7.2`, and no maximum version in the prepared Store copy; saved Store fields remain pending.
- [x] Review the included release work at source commit `c2be7382d1d8a6a8271dc8dddaa6770bca66db03`; preserve the intentionally local `project.godot` editor setting outside the package.

## Automated validation

- [x] Pass the Ramp gizmo editor scene with `--proto-shape-tests`, its PASS marker, and clean logs through the test runner.
- [x] Complete a cache-free import with the plugin initially disabled in the disposable project.
- [x] Enable the plugin in the freshly installed disposable project and complete `--editor --quit-after 120` startup with clean logs.
- [x] Pass all 24 `bash tests/run.sh` stages in `/tmp/proto-shape-tests.xqPiFn`: preparation, import, 13 regressions, and nine sample smokes.
- [x] Retain prior real-window default/remapped cursor-capture evidence from `010d80d`; the controller and bindings are unchanged in the packaged source. This was not rerun in the current headless suite, which explicitly skips capture-state assertions.
- [x] Confirm the runner copies the project to a temporary directory before executing tests.
- [x] Confirm runtime `SceneTree` scripts run directly and editor-only `@tool` `.tscn` tests run in editor mode with `--proto-shape-tests`.
- [x] Require regression completion markers and successful exit status; bounded import/sample stages complete with clean logs.
- [x] Confirm the runner scans combined stdout/stderr through shutdown and rejects `SCRIPT ERROR`, `ERROR:`, and leaked-resource warnings.

## Focused regressions

- [x] Verify `Path3D.curve_changed` refreshes active curves, detached old curves have no effect, short curves stay authored, and re-entry rebuilds off-tree edits.
- [x] Verify edited thickness produces the same sampled cache as a fresh wall with the same final values.
- [x] Verify `follow_use_bake_interval` follows native spacing direction within ProtoWall's 0.01-2.0 bounds.
- [x] Verify authored rail thickness and lower height survive shrink/grow, undo/redo, and save/reload.
- [x] Verify high rail counts and tiny heights fit and merge touching vertical intervals into clean sweep profiles.
- [x] Verify fitted posts follow sloped and turning rails, retain full-width open ends, wrap closed seams, and preserve authored placement settings and the vertical-span fallback.
- [x] Verify tiny Ramp step values survive count/mode/type changes, cancel, undo/redo, duplication, and save/reload while generated dimensions remain valid.
- [x] Verify invalid gizmo projections do not mutate shapes and first-party providers use the nullable projection and boolean begin-drag contracts.

## Editor acceptance and runtime validation

- [x] Record the user's 2026-09-13 sign-off on the latest editor/demo changes.
- [x] Pass lower-rail handle visibility/rendered-height and shape save/reload regressions.
- [x] Pass the InputMap-driven physical Power Cell Delivery route through pickup and terminal delivery without jumping against the installed ZIP.
- [x] Verify InputMap defaults preserve host mappings in the control regressions and exported runtime probe.
- [x] Pass installed-addon Ramp/Wall/posts and editable delivery scene save/reload checks.
- [x] Pass the standalone ProtoRamp unbaked-navigation regression; this limitation does not describe Power Cell Delivery.
- [x] Pass the official Godot 4.7.2 Linux export probe for collision, InputMap, all nine samples, and the full 80-wall showcase with clean logs.

The user's overall acceptance is recorded above; individual manual gestures
were not independently observed in this verification. Use the generic checklist's
[editor procedure](../README.md#editor-and-runtime-checks) for any later manual
pass: Add Child Node, every handle/arrow, snapping, cancel/undo/redo, anchors,
transformed parents, perspective/orthographic views, selection changes, and
checks for jumps, drift, stale/duplicate geometry, flicker, or sticky drag state.

## Documentation and media

- [x] Resolve all 54 local Markdown links; clean import and all nine sample runs validate their loaded resource paths.
- [x] Preserve the publisher-approved supplied 3821x1912 thumbnail, SHA-256 `a9c60c02f99c10823262d243c9a21421967d51c0cfe36f4d4aa013984e5c4baa`, in the package.
- [x] Keep prepared media/Store copy free of unresolved placeholders and legacy Asset Library fields; retain existing hosted feature videos.
- [x] Confirm `addons/proto_shape/LICENSE` is byte-identical to root `LICENSE`.
- [ ] Validate the supplied thumbnail against current Store dimension/cropping requirements during upload.

## Package

- [x] Build `proto-shape-1.2.0.zip` from source commit `c2be7382d1d8a6a8271dc8dddaa6770bca66db03`, addon tree `be10005f27daab0f0412e719c98f88793b08632e`.
- [x] Record 4,528,298 bytes and ZIP SHA-256 `e44e6ea123e4248eb65b860a42f3690c9545c4d68a7c5ad4f147c34cb7428dd6`.
- [x] Confirm the ZIP root is `addons/proto_shape/` with no repository-name wrapper.
- [x] Confirm it includes `LICENSE`, `README.md`, `plugin.cfg`, runtime scripts, examples, the supplied thumbnail, and source art.
- [x] Confirm it excludes root project files, tests, `release/`, `.git*`, `.github/`, `.godot/`, and generated `.import` files.
- [x] Install the exact ZIP at `/tmp/proto-shape-release-handoff.Srp6OM/installed_project`; pass fresh import, plugin-enabled startup, shape/demo save/reload, physical route, and native export checks. Logs are in `/tmp/proto-shape-release-handoff.Srp6OM/logs`.

## External ownership gates

- [x] Push the reviewed feature branch and verify remote head `c2be7382d1d8a6a8271dc8dddaa6770bca66db03`.
- [x] Create [PR #40](https://github.com/HLCaptain/proto-shape/pull/40) after authorization; verify it is OPEN and DRAFT with that exact head.
- [ ] After final validation, save the authorized Godot Asset Store draft metadata and upload the validated ZIP.
- [ ] Set and verify Store `Stable` in the authenticated draft after validation.

The approved browser tooling is installed, but Store access is at the
`sso.godotengine.org` password form and needs the user's sign-in. No Store
metadata or uploads have been written. Merge, tag/release publication, and
Store review submission/publication remain user-owned; none were performed,
and the main branch was not changed.
