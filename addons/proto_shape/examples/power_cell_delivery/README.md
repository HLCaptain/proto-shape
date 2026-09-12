# Power Cell Delivery

A compact playable ProtoShape showcase. Take either the broad cargo ramp or the optional maintenance stairs, follow the elevated ProtoWall rails to the cyan power cell, then descend the hollow return ramp and insert the cell into the relay terminal.

## Controls

- Move: <kbd>WASD</kbd>, arrow keys, D-pad, or left stick.
- Jump: <kbd>Space</kbd> or controller A.
- Interact: <kbd>E</kbd> or controller X.
- Restart or recover from a fall: <kbd>R</kbd> or controller Start.
- Release the mouse: <kbd>Esc</kbd> or controller Back.
- Capture the mouse again: left-click (`proto_shape_demo_capture_cursor`, remappable).

## Editing

The map is fully authored in [power_cell_delivery.tscn](power_cell_delivery.tscn). Its named `ProtoRamp`, `ProtoWall`, and native CSG nodes can be moved, reshaped, renamed, deleted, saved, and reloaded; no tool script regenerates or overwrites the scene. The controller references unique gameplay nodes such as `Player`, `PowerCell`, and the sockets: keep those names when experimenting with the blockout, or update the controller references when rewiring the objective.

Try widening `CargoRamp`, moving the `LeftCurvewalkRail` curve points, or changing a rail's count and thickness, then play the route again. The right-hand return ramp has its own landing and an open lane beside the deck; the high end leaves a walkable underpass below it.

Controls use named `proto_shape_demo_*` InputMap actions. Remap them in Project Settings → Input Map. When installed into another project, the shared [control helper](../proto_example_controls.gd) supplies only missing actions and preserves any mappings already defined by that project.

The staircase is an optional route because the intentionally small demo character has no automatic stair-stepping. The adjacent cargo ramp is the required walkable route.

![Power Cell Delivery](assets/power_cell_delivery_thumbnail.png)
