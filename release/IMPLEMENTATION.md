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
- [ ] 6. Exact transforms, nullable projection, accepted/rejected drag begin.
- [ ] 7. Native ProtoWall curve lifecycle and non-destructive short paths.
- [ ] 7b. Invalidate thickness-dependent sampling.
- [ ] 8. Native bake-interval spacing.
- [ ] 9. Reversible rail fitting and merged touching profiles.
- [ ] 10. Ramp bounds and drift-free conversions with loading-order coverage.
- [ ] 11. Persist hidden staircase settings.
- [ ] 12. Clear transient drag state and omit no-op undo actions.
- [ ] 13. Clean first import, then explicit plugin enablement.
- [ ] 14. Self-contained InputMap-based example controls.
- [ ] 15. Document and verify the unbaked navigation workflow.
- [ ] 16. Preserve saved Wall example edits with stored initialization state.
- [ ] 16b. Playable, editable Power Cell Delivery map.
- [ ] 16c. Actual Godot-rendered 1920 x 1080 Store thumbnail.
- [ ] 17. Correct provider/wrapper documentation and material limits.
- [ ] 18. Refresh descriptions, example links, and Store installation guidance.
- [ ] 19. Package addon license, source art, and verified examples.
- [ ] 20. Final release notes and saved Asset Store metadata/version draft.

## Final evidence required

- [ ] Focused tests: process status, error logs, and completion marker checked.
- [ ] Runtime sample smoke checks and completed 80-shape editor generation.
- [ ] Real editor-context input, gizmo, lifecycle, and undo/redo checks.
- [ ] Fresh install from ZIP built from the reviewed commit SHA.
- [ ] Runtime export tested with matching export templates.
- [ ] Final manual editor interaction/feel and playable delivery-route check.
- [ ] ZIP SHA-256 and contents recorded; tests/caches excluded, source art kept.
- [ ] Draft PR created; no merge/tag/release publication performed.
- [ ] Authenticated Store draft reopened and saved uploads/metadata verified.

## Verification log

Implementation checks and remaining operational gates are recorded here as work
lands. An unchecked manual or external gate is not a passing result.

- Step 1: `godot --headless --path . --script tests/test_proto_ramp_gizmos.gd`
  passed with `PASS: ramp fill gizmos`; both fill handles, limits, and cancel.
- Step 2: migrated main scene ran 300 fixed frames without script errors;
  deleted legacy scene/script paths have no remaining resource references.
- Step 3: real editor scene test passed (`tests/test_proto_plugin.tscn` with
  `--editor --quit-after 240 -- --proto-shape-tests`). Custom `--editor --script`
  SceneTree execution was replaced because it bypassed normal editor cleanup.
- Step 4: ramp editor tests passed with repeated provider removal returning
  plugin references to baseline; fill/cancel and active-drag shutdown checked.
- Step 5: IDs round-trip through PackedInt32Array as 1..5, and matching IDs on
  two ramps dispatch to their owning node. Editor regression scene passes.
