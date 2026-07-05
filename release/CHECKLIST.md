# Release Checklist

## Versioning

- [ ] Choose release version.
- [ ] Update version references in `README.md`, `addons/proto_shape/plugin.cfg`, and any release text.
- [ ] Confirm target Godot version.

## Validation

- [ ] Run `godot --headless --path . --import`.
- [ ] Run `godot --headless --path . --editor --quit`.
- [ ] Open the project in the Godot editor.
- [ ] Enable the `ProtoShape` plugin.
- [ ] Add `ProtoRamp` and verify point handles, arrow hover, arrow drag, snapping, undo/redo, and cancel.
- [ ] Add `ProtoWall` and verify wall height, thickness, lower rail height, and post width handles.
- [ ] Test ProtoWall interpolation modes with thickness and post-width gizmos.
- [ ] Save and reload example scenes.
- [ ] Confirm exported/runtime scenes do not depend on editor-only classes.

## Documentation

- [ ] Update root `README.md`.
- [ ] Update `addons/proto_shape/README.md`.
- [ ] Update `addons/proto_shape/proto_gizmo/README.md`.
- [ ] Update `addons/proto_shape/proto_wall/README.md`.
- [ ] Update `addons/proto_shape/proto_ramp/README.md` if ramp media or behavior changed.
- [ ] Fill `release/docs/RELEASE_NOTES_DRAFT.md`.
- [ ] Fill `release/docs/ASSETLIB_COPY_DRAFT.md`.

## Media

- [ ] Capture screenshots listed in `release/media/screenshots/README.md`.
- [ ] Capture GIFs listed in `release/media/gifs/README.md`.
- [ ] Capture videos listed in `release/media/videos/README.md`.
- [ ] Add final media links to the relevant README files.

## Publishing

- [ ] Create release package.
- [ ] Create git tag.
- [ ] Publish GitHub release.
- [ ] Update Godot Asset Library listing.
- [ ] Verify install from a fresh project.
