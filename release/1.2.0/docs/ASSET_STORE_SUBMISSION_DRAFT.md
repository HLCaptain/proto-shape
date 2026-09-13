# Godot Asset Store Submission Draft

This sheet targets the new `store.godotengine.org` platform. It does not contain legacy Asset Library icon URLs or download-commit fields.

Store work was CANCELLED by the user on 2026-09-13: "Don't upload the asset
to the store". Retain this local metadata as reference only. Authentication,
metadata saves, ZIP/thumbnail uploads, cropping validation, and `Stable` changes
are out of scope and are not pending release blockers.

## Initial asset page

- Publisher: existing `Illyan` publisher
- Asset Name: `ProtoShape - Ramps, Shapes and Gizmos`
- Asset URL slug: `proto-shape`
- Asset type: `Addon`

The publisher selection and immutable slug were not confirmed in an authenticated Store session. Store authentication is cancelled; acceptance of Store terms remains user-owned.

## Settings

### Asset Summary

ProtoShape adds fast CSG ramps, staircases, path-driven walls, and rails for Godot 4.7, with viewport gizmos, snapping, collisions, reusable gizmo tooling, and an editable Power Cell Delivery example map.

### Detailed Description

```markdown
# ProtoShape

ProtoShape is a Godot 4.7 editor addon for quickly building and reshaping 3D blockouts with dynamic CSG geometry.

## Included shapes

- **ProtoRamp** creates adjustable ramps and staircases with viewport handles, grid snapping, collision support, fill controls, and a navigation-mesh workflow.
- **ProtoWall** creates solid walls and rails along editable `Path3D` and `Curve3D` paths, including straight, curved, sloped, and variable-elevation layouts, with posts fitted to slopes and corners.

## Gizmo tooling

- **ProtoGizmo** provides reusable point and arrow-body editor gizmos for custom `Node3D` providers.
- **ProtoGizmoWrapper** lets wrapped child nodes implement redraw, drag, commit, snapping, cancel, and undo/redo behavior.

## Playable example

Power Cell Delivery is an editable prototype map built from varied ProtoRamp and ProtoWall configurations. Retrieve the power cell, carry it through the blockout, and deliver it to the relay terminal. It is a hands-on addon example, not a standalone game.

## Installation

Extract the ZIP into the project root so the addon is located at `addons/proto_shape`, then enable ProtoShape under **Project -> Project Settings -> Plugins**.

## Current limitations

Generated ProtoWall meshes do not contain UV or tangent attributes. UV-dependent and tangent-space workflows are unsupported; solid-color and world/triplanar materials may work.

The separate ProtoRamp navigation example intentionally ships with an unbaked `NavigationMesh`; bake it in the editor when testing navigation generation.

Documentation and source:
https://github.com/HLCaptain/proto-shape
```

### Tags and license

- Tags: `3D`, `GDScript`, `Editor`, `Level Design`
- License: `MIT`
- Source code: `https://github.com/HLCaptain/proto-shape`

### AI usage disclosure

Prepared AI usage value: yes. Disclosure copy:

> Generative AI tools were used to assist with code implementation, refactoring, documentation, examples, and code review for version 1.2.0.

Do not add a claim that the publisher personally reviewed or manually tested every AI-assisted change unless the publisher confirms it.

## Media

- Local thumbnail: `addons/proto_shape/examples/power_cell_delivery/assets/power_cell_delivery_thumbnail.png`
- Expected file: publisher-approved supplied thumbnail, preserved unchanged; 3821x1912 PNG
- SHA-256: `a9c60c02f99c10823262d243c9a21421967d51c0cfe36f4d4aa013984e5c4baa`
- Store upload and dimension/cropping validation: CANCELLED by the user on 2026-09-13
- Screenshots: none beyond the required thumbnail
- Featured image: none
- YouTube/video: none

## Version 1.2.0

- ZIP: `proto-shape-1.2.0.zip`, built after all core and example commits are integrated
- Archive source: `314e8920cead1e67f4b3957474da6304805e30bf`; 4,528,365 bytes
- ZIP SHA-256: `48c6825d3f7e7974565932ca310e8d94a46ecc650f3344042a4f70724b92d0fc`
- Version Name: `1.2.0`
- Stable: saving/verifying CANCELLED by the user on 2026-09-13
- Minimum required Godot version: `4.7`
- Maximum compatible Godot version: unset
- Validation version: `4.7.2`

### Version Changelog

```markdown
- Added ProtoWall for path-based solid walls and rails.
- Added hoverable, directly draggable solid gizmo arrows with screen-space picking.
- Added nullable projection results and boolean begin-drag contracts so invalid projections do not mutate shapes.
- Added thickness-aware path-cache invalidation and native Curve3D bake-interval spacing.
- Preserved authored rail thickness and lower height while deriving fitted, merged rail geometry.
- Fitted posts to sloped and turning rails while retaining authored placement and full-width open ends.
- Corrected ProtoGizmoWrapper callback ordering and added provider and wrapper examples.
- Added the editable Power Cell Delivery prototype map and its publisher-approved supplied thumbnail.
- Moved shared and shape-specific icons into their documented 1.2.0 paths.
```

### Additional Information

> Version 1.2.0, validated with Godot 4.7.2. Includes the editable Power Cell Delivery example; the separate ProtoRamp navigation sample ships unbaked.

## ZIP requirements

- ZIP root: `addons/proto_shape/`, with no repository-name wrapper.
- Include the addon `LICENSE`, README, plugin manifest, scripts, examples, publisher-approved supplied thumbnail, and all source art.
- Exclude root project files, `release/`, `.git*`, `.github/`, `.godot/`, and generated `.import` files.
- Keep the artifact built and freshly installed after final core integration locally; Store upload is CANCELLED.

## Pricing and reviews

- Price: free
- Donation URL: publisher choice
- Reviews enabled/disabled: publisher choice

## Authorization boundary

The user accepted the latest editor/demo changes on 2026-09-13 ("Everything is
fine" / "Go ahead") and subsequently CANCELLED Store work: "Don't upload the
asset to the store". This supersedes the earlier authorization to save metadata
and upload the ZIP/thumbnail. No Store metadata or uploads have been written.
The latest selected thumbnail must be preserved locally.

Not authorized:

- Store authentication, metadata saves, ZIP/thumbnail uploads, cropping validation, or `Stable` changes.
- Do not click `Publish` or `Submit for review`.
- The feature branch has been pushed and [draft PR #40](https://github.com/HLCaptain/proto-shape/pull/40) was created after the user's go-ahead. GitHub merge, tag creation/push, and release publication belong to the user.
