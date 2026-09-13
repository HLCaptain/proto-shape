# Release Checklist

Use this checklist for every release. Keep that release's decisions, checked
results, evidence, copy, and media records under `release/<version>/`. This
folder is excluded from the addon ZIP. A past release's passing result does
not validate a new candidate.

## Scope and compatibility

- [ ] Record the release version, title, included changes, migration notes, and known limitations.
- [ ] Choose the minimum supported Godot version, exact validation version, target export platforms, and any maximum compatibility claim.
- [ ] Inspect branch history and dirty changes; preserve unrelated work and identify the exact changes to include.
- [ ] Align `addons/proto_shape/plugin.cfg`, documentation, and release/Store copy with those decisions.

## Automated and import checks

- [ ] Run focused regressions for the changed behavior and `bash tests/run.sh`; follow [the test instructions](../tests/README.md) using the release's chosen Godot version.
- [ ] Require successful exit status, completion markers, and clean combined output through shutdown; reject script errors, errors, and leaked instances, resources, or RIDs.
- [ ] In a disposable project copy, remove existing import caches and complete a clean first import with the plugin disabled; the test runner prepares only its temporary copy this way.
- [ ] Enable the plugin in that imported copy and complete bounded `--editor --quit-after 120` startup with clean logs.
- [ ] Run display-dependent checks with a real display; record explicitly what headless checks cannot validate.

## Editor and runtime checks

- [ ] Enable the plugin and create affected shapes through Add Child Node.
- [ ] Exercise visible handles and arrows, grid snapping, cancel, undo/redo, selection changes, anchors, and transformed parents in perspective and orthographic views.
- [ ] Check normal drag direction and sensitivity, first-click jumps, stationary-pointer drift, stale geometry, duplicate nodes, flicker, and drag state after commit/cancel.
- [ ] Edit affected properties, curves, resources, and examples; save/reload and verify authored values and scenes survive.
- [ ] Play affected examples and check their InputMap setup preserves host mappings, remapping, and existing deadzones.
- [ ] Export and run affected examples with matching native export templates; verify generated geometry, collision, controls, and runtime independence from editor-only classes.
- [ ] Record manual sign-off with its date and tested scope. Leave unavailable checks pending.

## Documentation and media

- [ ] Update [the project README](../README.md), relevant addon docs, migration guidance, and release/Store copy for the delivered behavior.
- [ ] Check Markdown links, resource paths, installation instructions, and stated limitations.
- [ ] Verify the addon license matches the root license and retain required source art and notices.
- [ ] Check the current Store requirements for metadata, compatibility fields, media dimensions/cropping, and archive uploads.
- [ ] Review the selected thumbnail and any screenshots/videos against the delivered examples; preserve the publisher's chosen assets and remove unresolved placeholders.

## Exact package

- [ ] Review the final diff and included commits, then record the exact source commit SHA.
- [ ] Build the versioned addon ZIP from that commit, using the repository's archive rules.
- [ ] Verify the ZIP root is `addons/proto_shape/` without a repository wrapper; include the manifest, license, docs, scripts, examples, selected media, and source art.
- [ ] Verify root project files, release records, tests, Git metadata, import caches, and generated `.import` files are excluded.
- [ ] Record the ZIP filename, source SHA, byte size, and SHA-256 digest in the release record.
- [ ] Install that exact ZIP into a fresh project with the chosen Godot version; repeat import, plugin startup, affected editing/save/reload, example, and native export checks.
- [ ] If packaged source changes, rebuild the ZIP and repeat the affected checks before using its new digest.

## Publisher permissions and completion

Record each action's authorization and owner separately. Existing explicit
authorization remains valid within its stated scope; a passing check or
authorization for one action does not authorize the others.

- [ ] Confirm permission to push the reviewed branch and create/update a PR; verify the remote commit and required checks before handing it off.
- [ ] Confirm permission separately for merging, creating/pushing a tag, and publishing a GitHub release; verify any authorized action completed.
- [ ] Confirm permission to save Store draft metadata and upload the validated ZIP/media; verify the authenticated publisher and reopen the draft to check saved fields and uploads.
- [ ] Confirm stability and compatibility claims against the completed evidence.
- [ ] Confirm explicit permission for Store review submission or publication before taking either action; accepting publisher terms remains a separate owner decision.
- [ ] Record completed actions, links, source/artifact identity, and remaining owner actions in the version's release record. Queued checks and unsaved drafts remain pending.
