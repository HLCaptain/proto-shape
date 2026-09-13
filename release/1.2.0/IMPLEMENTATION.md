# 1.2.0 implementation record

Baseline: `9254b63` on `feature/generic-proto-gizmos`, with three unpublished
commits and existing uncommitted ramp fill/sample changes. The latter are
preserved and committed separately before new repairs. Target: Godot 4.7;
validation environment: Godot 4.7.2.

Use [the reusable release checklist](../README.md) for the workflow and
[the 1.2.0 checklist](CHECKLIST.md) for this candidate's remaining checks.

## Decisions

- Preserve existing normal drag sensitivity, anchors, segment-aligned wall/post
  arrows, stable inspector ranges, and runtime/editor separation.
- Keep authored rail settings; fit generated geometry without destructive
  dependent-property changes. Merge touching rail profiles.
- Use native curve lifecycle and bake spacing; leave non-null short curves alone.
- Preserve source art and the full interpolation showcase.
- Ship an editable Power Cell Delivery map and the publisher-approved supplied thumbnail.
- Use namespaced InputMap actions for game/example controls without replacing
  host actions. Editor snapping does not register gameplay actions.
- Use ordered commits in one draft PR and one final manual editor session.
- Save an Asset Store draft under Illyan / proto-shape. The user handles Store
  review submission and GitHub merge, tagging, and release publication.

## Steps

- [x] 0. Record baseline and preserve existing changes.
- [x] 1. Commit existing fill correction with both-handle regression checks.
- [x] 2. Commit existing ramp example migration and stable UIDs.
- [x] 3. Isolate editor snapping from host InputMap.
- [x] 4. Release ramp provider references and use current callback plugin.
- [x] 5. Use small per-gizmo handle IDs.
- [x] 6. Exact transforms, nullable projection, accepted/rejected drag begin.
- [x] 7. Native ProtoWall curve lifecycle and non-destructive short paths.
- [x] 7b. Invalidate thickness-dependent sampling; freeze the active thickness drag frame.
- [x] 8. Native bake-interval spacing.
- [x] 9. Reversible rail fitting and merged touching profiles.
- [x] 10. Reversible Ramp bounds and drift-free conversions with loading-order coverage.
- [x] 11. Persist hidden staircase settings.
- [x] 12. Clear transient drag state and omit no-op undo actions.
- [x] 13. Clean first import, then explicit plugin enablement.
- [x] 14. Self-contained InputMap-based example controls.
- [x] 15. Document and verify the unbaked navigation workflow.
- [x] 16. Preserve saved Wall example edits with stored initialization state.
- [x] 16b. Playable, editable Power Cell Delivery map.
- [x] 16c. Initial Godot-rendered 1920 x 1080 thumbnail prepared; superseded by the publisher-approved supplied thumbnail below.
- [x] 17. Correct provider/wrapper documentation and material limits.
- [x] 18. Refresh descriptions, example links, and Store installation guidance.
- [x] 19. Include addon license, source art, and verified examples in archive rules.
- [x] 20a. Prepare final release notes and current Store metadata fields locally.
- [ ] 20b. Save and reopen the authenticated Asset Store asset/version draft.
- [x] 21. Fit posts to sloped and turning rail geometry while preserving placement settings and the post-width gizmo.
- [x] 22. Use continuous editable Power Cell Delivery rails and preserve the user's latest thumbnail.

## Final candidate evidence

Evidence below identifies the candidate containing the latest post, demo,
documentation, and supplied-thumbnail changes. Earlier results are retained
separately in the historical log.

- [x] Focused tests: process status, error logs, and completion marker checked.
- [x] Runtime sample smoke checks and completed 80-shape editor generation.
- [x] Real editor-context input, gizmo, lifecycle, and undo/redo checks.
- [x] Fresh install from ZIP built from reviewed commit `c2be7382d1d8a6a8271dc8dddaa6770bca66db03`.
- [x] Runtime export tested with matching official Godot 4.7.2 Linux export templates.
- [x] User's final editor/demo sign-off received on 2026-09-13: "Everything is fine" / "Go ahead".
- [x] Final ZIP contents verified; tests/caches excluded, source art and the user's latest thumbnail kept. Artifact identity is recorded below.
- [x] Reviewed source commit pushed and remote SHA verified; no merge/tag/release publication performed.
- [x] [PR #40](https://github.com/HLCaptain/proto-shape/pull/40) created after authorization and verified OPEN/DRAFT at the reviewed source commit.
- [ ] Authenticated Store draft reopened and saved uploads/metadata verified.
- [ ] Store thumbnail dimension/cropping requirements checked and Stable field saved/verified.

### Source and package

- ZIP source commit: `c2be7382d1d8a6a8271dc8dddaa6770bca66db03`.
- Addon tree: `be10005f27daab0f0412e719c98f88793b08632e`.
- ZIP: `proto-shape-1.2.0.zip`, 4,528,298 bytes.
- ZIP SHA-256: `e44e6ea123e4248eb65b860a42f3690c9545c4d68a7c5ad4f147c34cb7428dd6`.
- Supplied thumbnail: 3821x1912 PNG, SHA-256 `a9c60c02f99c10823262d243c9a21421967d51c0cfe36f4d4aa013984e5c4baa`, unchanged in the package.

Evidence-only commits may follow the archive source commit. They are excluded
from the package; the addon tree and validated ZIP above remain unchanged.

### Completed validation and remaining access

- `bash tests/run.sh` passed all 24 stages in `/tmp/proto-shape-tests.xqPiFn`:
  preparation, clean import, 13 regressions, and nine sample scenes. Required
  markers, process status, and logs through shutdown were checked.
- The exact ZIP was installed into
  `/tmp/proto-shape-release-handoff.Srp6OM/installed_project`. Fresh import,
  plugin-enabled `--editor --quit-after 120` startup, Ramp/Wall/posts regressions,
  demo edit/save/reload, and the physical delivery route all passed with clean
  output. Logs are in `/tmp/proto-shape-release-handoff.Srp6OM/logs`.
- Its official Godot 4.7.2 Linux exported-runtime probe passed generated
  collision, InputMap setup, all nine scenes, and the complete 80-wall showcase.
  The probe is validation-only and is excluded from the addon ZIP.
- Real-window default/remapped cursor-capture evidence comes from source
  `010d80d`; controller code and bindings are unchanged in the packaged source.
  Capture-state checks were not rerun in the current headless suite.
- All 54 local Markdown links resolve, addon/root licenses match, archive
  contents retain source art, and the root `project.godot` changes remain local.
- The user accepted the latest editor/demo state on 2026-09-13. This is overall
  manual acceptance, not a claim that every editor gesture was independently
  observed during the automated verification.
- PR #40 is OPEN/DRAFT; its remote head was verified as the ZIP source commit.
  No merge, tag creation, release, main-branch change, or publication occurred.
- Browser tooling is approved and installed (`agent-browser` 0.37.1, Chrome
  for Testing 153.0.8010.36). The browser is at the `sso.godotengine.org` password
  form and needs the user's sign-in. No Store writes occurred; draft metadata,
  ZIP/thumbnail upload, cropping validation, and Stable remain pending.

## Historical verification log

The entries below preserve the implementation history, including superseded
candidate archives, thumbnails, and earlier approval failures. Current status
and artifact identity are recorded above.

- Step 1: initial focused fill checks passed; the final version runs as
  `tests/test_proto_ramp_gizmos.tscn` in real editor context and prints
  `PASS: ramp fill gizmos`; both fill handles, limits, and cancel are covered.
- Step 2: migrated main scene ran 300 fixed frames without script errors;
  deleted legacy scene/script paths have no remaining resource references.
- Step 3: real editor scene test passed (`tests/test_proto_plugin.tscn` with
  `--editor --quit-after 240 -- --proto-shape-tests`). Custom `--editor --script`
  SceneTree execution was replaced because it bypassed normal editor cleanup.
- Step 4: ramp editor tests passed with repeated provider removal returning
  plugin references to baseline; fill/cancel and active-drag shutdown checked.
- Step 5: IDs round-trip through PackedInt32Array as 1..5, and matching IDs on
  two ramps dispatch to their owning node. Editor regression scene passes.
- Baseline geometry was captured in an isolated copy before shape changes:
  default Ramp polygon, all nine anchor offsets, and all ten Wall interpolation
  sample paths for the same three-point curve. Simple wall creation took
  45–450 microseconds on this host; this is a diagnostic baseline, not a
  cross-machine performance guarantee.
- Official Godot 4.7.2 export templates downloaded to temporary storage. SHA-256
  `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`
  matches the official GitHub release asset digest. Linux debug/release templates
  are available for the final isolated export test.
- Store upload remains an operational gate: automatic approval review rejected
  downloading/executing `npx --yes agent-browser` because the unreviewed package
  could access authenticated browser sessions. No Store metadata was written.
- Demo review found its first deck covered the return ramp. The revised scene
  has an open return lane and landing. A physics-driven, InputMap-action route
  reaches the actual pickup and terminal areas without jumping, traverses the
  underpass, and verifies restart and fall recovery. The thumbnail was recaptured
  from the corrected scene using Godot Vulkan/Forward+ at 1920 x 1080.
- Integrated default Ramp polygons, all nine anchor offsets, and all ten Wall
  interpolation sample paths match the captured baseline exactly (timing fields
  excluded). The intended bake-spacing change has separate coverage.
- `bash tests/run.sh` passed all 22 checks in `/tmp/proto-shape-tests.yHM2kE`:
  clean import, 12 regression tests, and nine runtime scene smokes. This includes
  actual plugin enable/disable and full 80-wall editor showcase completion.
- All 50 local Markdown links resolve. The final thumbnail was recaptured after
  matching the player mesh to its collider and inspected at 1920 x 1080.
- Final interaction review found stationary-pointer thickness feedback after
  corner resampling; `000e498` fixes it by retaining the drag reference frame
  until the next edit. The regression starts at 0.05, drags to 0.65, then confirms
  a repeated pointer event remains at 0.65 instead of drifting to 0.897584.
- Step 10 follow-up: eight 0.000125-unit steps changed to four exposed a
  destructive dependent clamp. `77ba757` preserves authored dimensions and
  applies the minimum only to generated geometry; `65daf05` retains exact raw
  values for zero-motion, returned, canceled, and undone gizmo edits. The final
  isolated suite passed all 22 checks in `/tmp/proto-shape-tests.SgJD0n`.
- Export preflight used the matching official Linux release template. A
  temporary export-only probe (not shipped in the addon) passed real generated
  collision, addon-only InputMap setup, all nine sample scenes, and completed
  80-wall generation with no runtime errors.
- The commit-built ZIP passed fresh import and 120-frame plugin-enabled editor
  startup in `/tmp/proto-shape-final-install.ZIXHQ2`. Tests against the installed
  addon passed Ramp/Wall state and save/reload, delivery scene editing, and the
  full physical route. Its official release-template export also passed the
  runtime probe with clean logs. Final artifact hashes and source SHA are kept
  in the local `dist/RELEASE_RECORD.md`, outside the addon archive.
- The feature branch was pushed successfully. Automatic approval review then
  rejected draft PR creation under the user's GitHub publishing boundary.
  No PR was created; the prepared body is retained locally. Explicit approval
  is required before retrying. No merge, tag, or GitHub release was created.
- Step 14 completion audit found that mouse recapture still used a hard-coded
  left-click. It now uses `proto_shape_demo_capture_cursor` with the same default.
  A real-window regression passed default capture, remapping to a custom key,
  removal of the old binding, and preservation of host events/deadzone. Headless
  capture-state assertions are explicitly skipped; the windowed check is part
  of the release checklist. The refreshed candidate record includes its log.
- 2026-09-13 follow-up: rail posts now use fitted sweep geometry through slopes
  and corners, preserve full-width open ends and authored spacing/count, wrap
  closed seams, and retain box fallback for unusable vertical footprints.
  The post-width gizmo remains segment-aligned. Power Cell Delivery uses two
  continuous Fixed Up rail paths with matching rail/post profiles; the inner
  rail continues down the stairs, and the power cell is at `(-1, 3.02, -4)`.
  Preserve the user's ramp-fill and camera edits. The publisher-approved
  supplied thumbnail is 3821 x 1912 PNG with SHA-256
  `a9c60c02f99c10823262d243c9a21421967d51c0cfe36f4d4aa013984e5c4baa`;
  do not recapture or replace it. Store cropping/validation remains to be checked.
  The user reported "Everything is fine" and authorized "Go ahead";
  this records manual acceptance, while exact final package and external checks
  remain separately tracked above.
- Current candidate validation: `bash tests/run.sh` passed all 24 stages in
  `/tmp/proto-shape-tests.xqPiFn` (preparation, clean import, 13 regressions, nine
  sample scenes). The physical route now targets the authored cell position and
  crosses the landing before descending. Rail checks allow the inner path to
  extend down the stairs. The user's scene and thumbnail were not reverted.
- The runner now disables plugins only in its disposable project via Godot's
  native `ConfigFile`. Recovery mode alone still parsed the enabled plugin
  before icon import in this build, so it was not retained as the solution.
  The root `project.godot` plugin-enabled/editor serialization changes remain
  local, outside the release commits and addon ZIP.
- Browser tooling approval succeeded after the user's go-ahead: pinned
  `agent-browser` 0.37.1 and Chrome for Testing 153.0.8010.36 are available.
  Store authentication and saved draft verification are still pending.
