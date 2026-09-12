# 1.2.0 implementation record

Baseline: `9254b63` on `feature/generic-proto-gizmos`, with three unpublished
commits and existing uncommitted ramp fill/sample changes. The latter are
preserved and committed separately before new repairs. Target: Godot 4.7;
validation environment: Godot 4.7.2.

## Decisions

- Preserve existing normal drag sensitivity, anchors, segment-aligned wall/post
  arrows, stable inspector ranges, and runtime/editor separation.
- Keep authored rail settings; fit generated geometry without destructive
  dependent-property changes. Merge touching rail profiles.
- Use native curve lifecycle and bake spacing; leave non-null short curves alone.
- Preserve source art and the full interpolation showcase.
- Ship an editable Power Cell Delivery map and actual 16:9 Godot thumbnail.
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
- [x] 16c. Actual Godot-rendered 1920 x 1080 Store thumbnail.
- [x] 17. Correct provider/wrapper documentation and material limits.
- [x] 18. Refresh descriptions, example links, and Store installation guidance.
- [x] 19. Include addon license, source art, and verified examples in archive rules.
- [x] 20a. Prepare final release notes and current Store metadata fields locally.
- [ ] 20b. Save and reopen the authenticated Asset Store asset/version draft.

## Final evidence required

- [x] Focused tests: process status, error logs, and completion marker checked.
- [x] Runtime sample smoke checks and completed 80-shape editor generation.
- [x] Real editor-context input, gizmo, lifecycle, and undo/redo checks.
- [x] Fresh install from ZIP built from the reviewed commit SHA.
- [x] Runtime export tested with matching export templates.
- [ ] Final manual editor interaction/feel and playable delivery-route check.
- [x] ZIP contents verified; tests/caches excluded, source art kept. Final hashes are in the local `dist/RELEASE_RECORD.md`.
- [x] Reviewed feature branch pushed; no merge/tag/release publication performed.
- [ ] Draft PR created (approval review requires explicit permission).
- [ ] Authenticated Store draft reopened and saved uploads/metadata verified.

## Verification log

Implementation checks and remaining operational gates are recorded here as work
lands. An unchecked manual or external gate is not a passing result.

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
