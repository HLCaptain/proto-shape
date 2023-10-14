# ProtoRamp

ProtoRamp is a dynamic ramp/staircase shape based on Godot's Constructive Solid Geometry (CSG). It is designed to be used for prototyping levels and game mechanics.

<!-- Icon (addons/proto_shape/icon/proto-shape-icon.png) -->
<img src="../icon/proto-ramp-icon.png" style="height: 40%; width: 40%; margin: 0 auto; display: block">

## Usage

### Create a ProtoRamp

When adding a new child node, search for `ProtoRamp` and add it to the scene.

<!-- <video controls>
  <source src="assets/videos/create_protoramp.mp4" type="video/mp4">
</video> -->

https://youtu.be/wKXBYw4ZvnQ

### Use Gizmos

ProtoRamp supports custom gizmos to adjust the shape.

<!-- <video controls>
  <source src="assets/videos/use_gizmos.mp4" type="video/mp4">
</video> -->

https://youtu.be/hQj8q3X_WAY

### Adjust parameters

Modify height, width, depth, anchor position and more!

<!-- <video controls>
  <source src="assets/videos/modify_dimensions.mp4" type="video/mp4">
</video> -->

### Change step counts in multiple ways

There are two ways of changing the step count:

- Fitting into `Staircase` dimensions: current width-height-depth of the staircase is respected, step dimensions will adjust.
- Using `Step` dimensions as a base: step dimensions are constant, staircase will shrink or grow to fit the steps.

Fitting in more steps:

<!-- <video controls>
  <source src="assets/videos/change_step_count.mp4" type="video/mp4">
</video> -->

https://youtu.be/9xVp4eIWSm4

You can use both!

<!-- <video controls>
  <source src="assets/videos/change_step_count_2.mp4" type="video/mp4">
</video> -->

https://youtu.be/akGBTcYx5GY
