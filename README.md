# ProtoShape - Godot Prototyping Extension for CSG and Gizmos

<img src="addons/proto_shape/icon/proto-shape-icon.png" style="height: 25%; width: 25%; margin: 0 auto; display: block">

ProtoShape is a Godot plugin that adds a library of dynamic shapes based on Godot's Constructive Solid Geometry (CSG) and custom gizmo utilities to create your own dynamic nodes. It is designed to be used for prototyping levels and game mechanics.

[Feature Showcase](https://youtube.com/playlist?list=PL1C7-40JVAoKh9hsaS_wFPziyKAF1DTJ2&si=0ItpHT7-StKODXbC)

## Installation

Install plugin from the AssetLib inside Godot or download the latest release from the [releases page](https://github.com/HLCaptain/proto-shape/releases/latest).

Enable the plugin inside Godot. `Project` -> `Project Settings` -> `Plugins` -> Enable `ProtoShape`.

## Usage

Add these shapes to your scene by searching for them in the `Add Child Node` menu.

### [ProtoRamp](addons/proto_shape/proto_ramp/README.md)

Ramp/staircase with adjustable height, width and length. Can adjust step count and various other parameters. Supports custom gizmos.

https://github.com/HLCaptain/proto-shape/assets/22623259/730a527c-d6ba-4eaa-93b6-dbcbbd8aba52

> [!TIP]
> `ProtoRamp` supports [undo/redo](addons/proto_shape/README.md#undoredo-support) and [grid snapping](addons/proto_shape/proto_ramp/README.md#grid-snapping).

### [ProtoGizmoWrapper](addons/proto_shape/proto_gizmo_wrapper/README.md)

Nest your custom nodes under the `ProtoGizmoWrapper` and start adding custom gizmo functionality with a few lines of code. Embrace the power of dragging your cursor on the screen, with all the complex 3D math handled for you with [ProtoGizmoUtils](addons/proto_shape/proto_gizmo/README.md#protogizmoutils).

Supports only `Node3D` nodes for now! Read the [documentation](addons/proto_shape/proto_gizmo_wrapper/README.md) to get to know gizmos and how to make your custom nodes compatible.

## Contributing

Feel free to open an issue for any bugs or feature requests. See more in [CONTRIBUTING.md](CONTRIBUTING.md).

The library is written in `GDScript` and (mostly) follows the [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).

Extend the library of shapes by creating an issue or pull request! Share your idea for a shape or feature you would like to see added to the library.

If you find any bugs, feel free to create an issue.

## License

[MIT](https://choosealicense.com/licenses/mit/)
