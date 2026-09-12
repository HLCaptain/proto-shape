# Godot Asset Store Submission Draft

This sheet targets the new `store.godotengine.org` platform. It does not contain legacy Asset Library icon URLs or download-commit fields.

## Initial asset page

- Publisher: existing `Illyan` publisher
- Asset Name: `ProtoShape - Ramps, Shapes and Gizmos`
- Asset URL slug: `proto-shape`
- Asset type: `Addon`

The publisher selection and immutable slug must be confirmed in the user's authenticated Store session. Acceptance of Store terms is user-owned.

## Settings

### Asset Summary

ProtoShape adds fast CSG ramps, staircases, path-driven walls, and rails for Godot 4.7, with viewport gizmos, snapping, collisions, reusable gizmo tooling, and an editable Power Cell Delivery example map.

### Detailed Description

```markdown
# ProtoShape

ProtoShape is a Godot 4.7 editor addon for quickly building and reshaping 3D blockouts with dynamic CSG geometry.

## Included shapes

- **ProtoRamp** creates adjustable ramps and staircases with viewport handles, grid snapping, collision support, fill controls, and a navigation-mesh workflow.
- **ProtoWall** creates solid walls and rails along editable `Path3D` and `Curve3D` paths, including straight, curved, sloped, and variable-elevation layouts.

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

Set AI usage to yes and use:

> Generative AI tools were used to assist with code implementation, refactoring, documentation, examples, and code review for version 1.2.0.

Do not add a claim that the publisher personally reviewed or manually tested every AI-assisted change unless the publisher confirms it.

## Media

- Thumbnail upload: `addons/proto_shape/examples/power_cell_delivery/assets/power_cell_delivery_thumbnail.png`
- Expected file: untouched 1920x1080 PNG rendered from the delivered Godot scene
- Screenshots: none beyond the required thumbnail
- Featured image: none
- YouTube/video: none

## Version 1.2.0

- ZIP: `proto-shape-1.2.0.zip`, built after all core and example commits are integrated
- Version Name: `1.2.0`
- Stable: check only after final validation passes
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
- Corrected ProtoGizmoWrapper callback ordering and added provider and wrapper examples.
- Added the editable Power Cell Delivery prototype map and its native Godot-rendered thumbnail.
- Moved shared and shape-specific icons into their documented 1.2.0 paths.
```

### Additional Information

> Version 1.2.0, validated with Godot 4.7.2. Includes the editable Power Cell Delivery example; the separate ProtoRamp navigation sample ships unbaked.

## ZIP requirements

- ZIP root: `addons/proto_shape/`, with no repository-name wrapper.
- Include the addon `LICENSE`, README, plugin manifest, scripts, examples, 1920x1080 thumbnail, and all source art.
- Exclude root project files, `release/`, `.git*`, `.github/`, `.godot/`, and generated `.import` files.
- Upload only the artifact built and freshly installed after final core integration.

## Pricing and reviews

- Price: free
- Donation URL: publisher choice
- Reviews enabled/disabled: publisher choice

## Authorization boundary

Authorized after final integration and validation:

- Save the Store draft settings.
- Upload the validated ZIP as version 1.2.0.

Not authorized:

- Do not click `Publish` or `Submit for review`.
- Do not perform GitHub merge, tag, push, or release publication; those actions belong to the user.
