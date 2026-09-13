@tool
extends Node3D

const ProtoRamp = preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")
const ProtoWall = preload("res://addons/proto_shape/proto_wall/proto_wall.gd")

const SHOWCASE_BASE_CURVE_WIDTH := 4.1
const SHOWCASE_PAIR_GAP := 1.1

enum ExampleType {
	SOLID_WALLS,
	RAIL_TYPES,
	MIXED_BLOCKOUT,
	INTERPOLATION_SHOWCASE,
}

@export var example_type: ExampleType = ExampleType.SOLID_WALLS
@export_storage var setup_completed := false

var is_setting_up := false
var setup_generation := 0

func _enter_tree() -> void:
	setup_generation += 1
	if not setup_completed:
		call_deferred("_setup_async", setup_generation)

func _exit_tree() -> void:
	setup_generation += 1
	is_setting_up = false

func _setup_async(generation: int) -> void:
	if setup_completed or is_setting_up or not _can_continue_setup(generation):
		return
	is_setting_up = true

	_ensure_camera_and_light()
	if not await _yield_editor_setup_frame(generation):
		_finish_setup(generation)
		return

	var completed := true
	match example_type:
		ExampleType.SOLID_WALLS:
			_setup_solid_walls()
		ExampleType.RAIL_TYPES:
			_setup_rail_types()
		ExampleType.MIXED_BLOCKOUT:
			_setup_mixed_blockout()
		ExampleType.INTERPOLATION_SHOWCASE:
			completed = await _setup_interpolation_showcase(generation)

	if completed and _can_continue_setup(generation):
		setup_completed = true
	_finish_setup(generation)

func _finish_setup(generation: int) -> void:
	if generation == setup_generation:
		is_setting_up = false

func _can_continue_setup(generation: int) -> bool:
	return generation == setup_generation and is_inside_tree()

func _yield_editor_setup_frame(generation: int) -> bool:
	if not _can_continue_setup(generation):
		return false
	if Engine.is_editor_hint():
		var tree := get_tree()
		if tree == null:
			return false
		await tree.process_frame
	return _can_continue_setup(generation)

func _setup_solid_walls() -> void:
	_configure_wall("StraightSolidWall", Vector3(-8.0, 0.0, -2.0), _create_polyline_curve([Vector3.ZERO, Vector3(0, 0, 5)]), ProtoWall.Style.SOLID, 2.5, 0.3)
	_configure_label("StraightSolidWallLabel", Vector3(-8.0, 2.9, 0.5), "Straight solid wall\nDrag height/thickness handles")

	_configure_wall("LowCoverWall", Vector3(-3.5, 0.0, -2.0), _create_polyline_curve([Vector3.ZERO, Vector3(0, 0, 4)]), ProtoWall.Style.SOLID, 0.9, 0.45)
	_configure_label("LowCoverWallLabel", Vector3(-3.5, 1.4, 0.0), "Low cover wall\nShooter cover or platform edge")

	_configure_wall("CurvedArenaWall", Vector3(2.2, 0.0, -2.0), _create_arc_curve(3.0, 105.0, 12), ProtoWall.Style.SOLID, 1.5, 0.28, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.PATH_PERPENDICULAR, ProtoWall.PathInterpolation.CORNER_ROUNDED)
	_configure_label("CurvedArenaWallLabel", Vector3(1.4, 2.1, 2.0), "Curved arena wall\nRounded corners for arena boundaries")

	_configure_wall("CenterAlignedWall", Vector3(-8.0, 0.0, 5.0), _create_polyline_curve([Vector3.ZERO, Vector3(0, 0, 3)]), ProtoWall.Style.SOLID, 1.5, 0.25, ProtoWall.WallSide.CENTER)
	_configure_wall("LeftAlignedWall", Vector3(-4.0, 0.0, 5.0), _create_polyline_curve([Vector3.ZERO, Vector3(0, 0, 3)]), ProtoWall.Style.SOLID, 1.5, 0.25, ProtoWall.WallSide.LEFT)
	_configure_wall("RightAlignedWall", Vector3(0.0, 0.0, 5.0), _create_polyline_curve([Vector3.ZERO, Vector3(0, 0, 3)]), ProtoWall.Style.SOLID, 1.5, 0.25, ProtoWall.WallSide.RIGHT)
	_configure_label("AlignmentLabel", Vector3(-4.0, 2.0, 6.6), "Path alignment: Center, Left, Right\nUse side when the path is an edge instead of a centerline")

	_configure_wall("LinearMapBoundary", Vector3(5.0, 0.0, 5.0), _create_polyline_curve([Vector3(-2, 0, -1.4), Vector3(2, 0, -1.4), Vector3(2, 0, 1.4), Vector3(-1, 0, 1.4), Vector3(-1, 0, 0.2)]), ProtoWall.Style.SOLID, 1.35, 0.22, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.FIXED_UP, ProtoWall.PathInterpolation.LINEAR)
	_configure_label("LinearMapBoundaryLabel", Vector3(5.0, 2.0, 6.8), "Linear map boundary\nStraight control-point walls with mitered corners")

	_configure_wall("UnevenRetainingWall", Vector3(8.5, 0.0, -2.5), _create_mountain_curve(), ProtoWall.Style.SOLID, 1.15, 0.22, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.PATH_PERPENDICULAR, ProtoWall.PathInterpolation.FOLLOW_CURVED_PATH3D)
	_configure_box("UnevenRetainingWallTerrainA", Vector3(7.1, -0.15, -1.2), Vector3(2.4, 0.3, 2.0))
	_configure_box("UnevenRetainingWallTerrainB", Vector3(9.0, 0.35, 1.0), Vector3(2.5, 0.3, 2.2))
	_configure_box("UnevenRetainingWallTerrainC", Vector3(10.6, 0.85, 2.8), Vector3(2.3, 0.3, 2.0))
	_configure_label("UnevenRetainingWallLabel", Vector3(9.5, 2.5, 1.5), "Uneven retaining wall\nFollows a curved Path3D over changing elevation")

func _setup_rail_types() -> void:
	_configure_wall("TwoRailGuardRail", Vector3(-8.0, 0.0, -2.0), _create_polyline_curve([Vector3.ZERO, Vector3(0, 0, 5)]), ProtoWall.Style.RAIL, 1.1, 0.18)
	_configure_rail("TwoRailGuardRail", 2, 0.12, 0.45, true, ProtoWall.PostPlacement.SPACING, 1.25, 4, 0.18)
	_configure_label("TwoRailGuardRailLabel", Vector3(-8.0, 1.6, 0.5), "Two-rail guard rail\nBalconies, bridges, platform edges")

	_configure_wall("SingleRailBarrier", Vector3(-3.5, 0.0, -2.0), _create_polyline_curve([Vector3.ZERO, Vector3(0, 0, 4)]), ProtoWall.Style.RAIL, 0.9, 0.2)
	_configure_rail("SingleRailBarrier", 1, 0.14, 0.45, true, ProtoWall.PostPlacement.SPACING, 1.0, 4, 0.2)
	_configure_label("SingleRailBarrierLabel", Vector3(-3.5, 1.4, 0.0), "Single-rail barrier\nLightweight boundary or pipe rail")

	_configure_wall("ThreeRailFence", Vector3(1.0, 0.0, -2.0), _create_polyline_curve([Vector3.ZERO, Vector3(0, 0, 5)]), ProtoWall.Style.RAIL, 1.4, 0.2)
	_configure_rail("ThreeRailFence", 3, 0.1, 0.35, true, ProtoWall.PostPlacement.COUNT, 1.0, 6, 0.22)
	_configure_label("ThreeRailFenceLabel", Vector3(1.0, 1.9, 0.5), "Three-rail fence\nReadable outdoor or arena boundary")

	_configure_wall("CurvedGuardRail", Vector3(-6.0, 0.0, 5.0), _create_arc_curve(3.0, 140.0, 16), ProtoWall.Style.RAIL, 1.1, 0.18, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.PATH_PERPENDICULAR, ProtoWall.PathInterpolation.CORNER_ROUNDED)
	_configure_rail("CurvedGuardRail", 2, 0.12, 0.45, true, ProtoWall.PostPlacement.SPACING, 0.9, 4, 0.18)
	_configure_label("CurvedGuardRailLabel", Vector3(-6.8, 1.7, 7.3), "Curved guard rail\nRound platforms and arena edges")

	_configure_wall("PostlessHandRail", Vector3(1.5, 0.0, 5.0), _create_polyline_curve([Vector3.ZERO, Vector3(0, 0, 4.5)]), ProtoWall.Style.RAIL, 1.0, 0.14)
	_configure_rail("PostlessHandRail", 2, 0.1, 0.5, false, ProtoWall.PostPlacement.SPACING, 1.5, 4, 0.14)
	_configure_label("PostlessHandRailLabel", Vector3(1.5, 1.5, 7.0), "Postless hand rail\nPipes, trims, or temporary guides")

	_configure_wall("MountainRail", Vector3(5.5, 0.0, 2.5), _create_mountain_curve(), ProtoWall.Style.RAIL, 1.1, 0.16, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.PATH_PERPENDICULAR, ProtoWall.PathInterpolation.CORNER_ROUNDED)
	_configure_rail("MountainRail", 2, 0.1, 0.45, true, ProtoWall.PostPlacement.SPACING, 0.75, 4, 0.16)
	_configure_box("MountainRailTerrainA", Vector3(4.2, -0.15, 3.6), Vector3(2.0, 0.3, 2.0))
	_configure_box("MountainRailTerrainB", Vector3(6.0, 0.35, 5.6), Vector3(2.2, 0.3, 2.2))
	_configure_box("MountainRailTerrainC", Vector3(7.8, 0.9, 7.3), Vector3(2.0, 0.3, 2.0))
	_configure_label("MountainRailLabel", Vector3(6.6, 2.6, 6.0), "Rounded mountain rail\nVariable X/Y/Z elevation and point tilt")

	_configure_wall("LinearFence", Vector3(7.5, 0.0, -2.0), _create_polyline_curve([Vector3(-1.8, 0, 0), Vector3(0.0, 0, 0.8), Vector3(1.8, 0, 0.0), Vector3(3.2, 0, 0.7)]), ProtoWall.Style.RAIL, 1.35, 0.18, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.FIXED_UP, ProtoWall.PathInterpolation.LINEAR)
	_configure_rail("LinearFence", 3, 0.09, 0.35, true, ProtoWall.PostPlacement.COUNT, 1.0, 5, 0.2)
	_configure_label("LinearFenceLabel", Vector3(8.5, 1.9, -0.4), "Linear zig-zag fence\nMitered corners keep rail thickness consistent")

func _setup_mixed_blockout() -> void:
	_configure_wall("RoomBoundary", Vector3(-5.0, 0.0, 0.0), _create_polyline_curve([Vector3(-3, 0, -2), Vector3(3, 0, -2), Vector3(3, 0, 2), Vector3(-3, 0, 2)]), ProtoWall.Style.SOLID, 1.8, 0.25, ProtoWall.WallSide.CENTER, true, ProtoWall.PathOrientation.FIXED_UP, ProtoWall.PathInterpolation.LINEAR)
	_configure_label("RoomBoundaryLabel", Vector3(-5.0, 2.3, 0.0), "Closed solid wall path\nFast room or arena boundary")

	_configure_wall("BalconyRail", Vector3(3.0, 0.0, 0.0), _create_arc_curve(2.4, 180.0, 16), ProtoWall.Style.RAIL, 1.1, 0.18, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.PATH_PERPENDICULAR, ProtoWall.PathInterpolation.CORNER_ROUNDED)
	_configure_rail("BalconyRail", 2, 0.11, 0.45, true, ProtoWall.PostPlacement.COUNT, 0.8, 7, 0.2)
	_configure_label("BalconyRailLabel", Vector3(1.8, 1.6, 1.8), "Curved balcony rail\nPosts follow the sampled curve")

	_configure_ramp("Ramp", Vector3(1.0, 0.0, 5.0), 1.4, 1.0, 4.0)
	_configure_wall("RampLeftRail", Vector3(1.0, 0.0, 5.0), _create_polyline_curve([Vector3(-0.7, 0, 0), Vector3(-0.7, 1.0, 4.0)]), ProtoWall.Style.RAIL, 1.1, 0.16, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.PATH_PERPENDICULAR)
	_configure_rail("RampLeftRail", 2, 0.1, 0.45, true, ProtoWall.PostPlacement.SPACING, 1.0, 4, 0.16)
	_configure_wall("RampRightRail", Vector3(1.0, 0.0, 5.0), _create_polyline_curve([Vector3(0.7, 0, 0), Vector3(0.7, 1.0, 4.0)]), ProtoWall.Style.RAIL, 1.1, 0.16, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.PATH_PERPENDICULAR)
	_configure_rail("RampRightRail", 2, 0.1, 0.45, true, ProtoWall.PostPlacement.SPACING, 1.0, 4, 0.16)
	_configure_label("RampRailsLabel", Vector3(1.0, 2.3, 7.0), "Sloped ProtoWall rails beside ProtoRamp\nPath rises from Y=0 to Y=1")

	_configure_wall("MapPerimeterFence", Vector3(8.0, 0.0, -1.0), _create_polyline_curve([Vector3(-2.5, 0, -1.5), Vector3(2.5, 0, -1.5), Vector3(2.5, 0, 1.5), Vector3(-2.5, 0, 1.5)]), ProtoWall.Style.RAIL, 1.25, 0.18, ProtoWall.WallSide.CENTER, true, ProtoWall.PathOrientation.FIXED_UP, ProtoWall.PathInterpolation.LINEAR)
	_configure_rail("MapPerimeterFence", 3, 0.08, 0.35, true, ProtoWall.PostPlacement.COUNT, 1.0, 10, 0.18)
	_configure_label("MapPerimeterFenceLabel", Vector3(8.0, 1.8, -1.0), "Closed perimeter fence\nLinear mode for map boundaries and compounds")

	_configure_wall("MountainRoadRail", Vector3(6.0, 0.0, 5.0), _create_mountain_curve(), ProtoWall.Style.RAIL, 1.1, 0.16, ProtoWall.WallSide.CENTER, false, ProtoWall.PathOrientation.PATH_PERPENDICULAR, ProtoWall.PathInterpolation.FOLLOW_CURVED_PATH3D)
	_configure_rail("MountainRoadRail", 2, 0.09, 0.45, true, ProtoWall.PostPlacement.SPACING, 0.8, 5, 0.16)
	_configure_follow("MountainRoadRail", false, ProtoWall.DirectionSource.GENERATED_SEGMENT)
	_configure_box("MountainRoadTerrainA", Vector3(4.6, -0.15, 6.2), Vector3(2.2, 0.3, 2.2))
	_configure_box("MountainRoadTerrainB", Vector3(6.5, 0.35, 8.2), Vector3(2.4, 0.3, 2.4))
	_configure_box("MountainRoadTerrainC", Vector3(8.1, 0.9, 9.9), Vector3(2.2, 0.3, 2.2))
	_configure_label("MountainRoadRailLabel", Vector3(7.0, 2.8, 8.5), "Mountain road rail\nFollow Curved Path3D over uneven terrain")

func _setup_interpolation_showcase(generation: int) -> bool:
	_configure_label("ShowcaseTitle", Vector3(0.0, 4.0, -4.0), "ProtoWall interpolation showcase\nEach mode uses the same flat and elevated Path3D curves\nEach group: solid wall left / matching rail right")
	var groups := _get_interpolation_showcase_groups()
	for group_index in range(groups.size()):
		var group: Dictionary = groups[group_index]
		_configure_label("%sHeader" % String(group["name"]), Vector3(float(group["x"]) + 1.8, 2.8, -1.0), String(group["title"]))
		if not await _yield_editor_setup_frame(generation):
			return false

	var modes := _get_interpolation_showcase_modes()
	for index in range(modes.size()):
		var info: Dictionary = modes[index]
		var z := float(index) * 7.0
		var mode: int = info["mode"]
		var title: String = info["title"]
		var note: String = info["note"]
		_configure_label("%sLabel" % String(info["name"]), Vector3(-31.0, 2.4, z + 1.2), "%s\n%s" % [title, note])
		if not await _yield_editor_setup_frame(generation):
			return false
		for group in groups:
			var group_info: Dictionary = group
			var group_name := String(group_info["name"])
			var group_x := float(group_info["x"])
			var xz_scale := float(group_info["xz_scale"])
			var curve_width := SHOWCASE_BASE_CURVE_WIDTH * xz_scale
			var pair_center_x := group_x + 1.85
			var solid_x := pair_center_x - ((curve_width * 2.0 + SHOWCASE_PAIR_GAP) * 0.5)
			var rail_x := solid_x + curve_width + SHOWCASE_PAIR_GAP
			var curve := _create_showcase_curve(bool(group_info["elevated"]), xz_scale)
			_configure_showcase_pair(
				"%s%s" % [String(info["name"]), group_name],
				Vector3(solid_x, 0.0, z),
				Vector3(rail_x, 0.0, z),
				curve,
				mode,
				int(group_info["orientation"])
			)
			if not await _yield_editor_setup_frame(generation):
				return false
	return true

func _configure_showcase_pair(prefix: String, solid_position: Vector3, rail_position: Vector3, curve_resource: Curve3D, mode: int, path_orientation: int) -> void:
	var solid_name := "%sSolid" % prefix
	var rail_name := "%sRail" % prefix
	_configure_wall(solid_name, solid_position, curve_resource.duplicate(true), ProtoWall.Style.SOLID, 1.15, 0.18, ProtoWall.WallSide.CENTER, false, path_orientation, mode)
	_configure_wall(rail_name, rail_position, curve_resource.duplicate(true), ProtoWall.Style.RAIL, 1.1, 0.14, ProtoWall.WallSide.CENTER, false, path_orientation, mode)
	_configure_rail(rail_name, 2 if mode != ProtoWall.PathInterpolation.LINEAR else 3, 0.07, 0.42, true, ProtoWall.PostPlacement.SPACING, 0.85, 5, 0.14)
	_configure_showcase_quality(solid_name, mode)
	_configure_showcase_quality(rail_name, mode)

func _configure_showcase_quality(node_name: String, mode: int) -> void:
	var wall := _get_or_create_wall(node_name)
	if wall == null:
		return

	if wall.curve != null:
		wall.curve.bake_interval = 0.35
	wall.path_sample_spacing = 0.12
	wall.corner_rounding = 0.24
	wall.corner_angle_step = 6.0
	wall.sample_simplify_angle = 0.35
	wall.preserve_vertical_spikes = false
	if mode == ProtoWall.PathInterpolation.FOLLOW_CURVED_PATH3D:
		wall.follow_use_bake_interval = false
	wall.direction_source = ProtoWall.DirectionSource.INTERPOLATION_TANGENT

func _configure_wall(
	node_name: String,
	node_position: Vector3,
	curve_resource: Curve3D,
	wall_style: int,
	wall_height: float,
	wall_thickness: float,
	wall_side: ProtoWall.WallSide = ProtoWall.WallSide.CENTER,
	curve_closed: bool = false,
	path_orientation: int = ProtoWall.PathOrientation.PATH_PERPENDICULAR,
	path_interpolation: int = ProtoWall.PathInterpolation.CORNER_ROUNDED) -> void:
	var wall := _get_or_create_wall(node_name)
	if wall == null:
		return

	curve_resource.closed = curve_closed
	wall.position = node_position
	wall.curve = curve_resource
	wall.style = wall_style
	wall.height = wall_height
	wall.thickness = wall_thickness
	wall.side = wall_side
	wall.path_orientation = path_orientation
	wall.path_interpolation = path_interpolation
	wall.path_sample_spacing = 0.18
	wall.corner_rounding = 0.22
	wall.corner_angle_step = 8.0
	wall.sample_simplify_angle = 1.0
	wall.collisions_enabled = true

func _configure_rail(
	node_name: String,
	rail_count: int,
	rail_size: float,
	lower_height: float,
	posts: bool,
	placement: int,
	spacing: float,
	post_count: int,
	post_width: float) -> void:
	var wall := _get_or_create_wall(node_name)
	if wall == null:
		return

	wall.rail_count = rail_count
	wall.rail_thickness = rail_size
	wall.lower_rail_height = lower_height
	wall.post_enabled = posts
	wall.post_placement = placement
	wall.post_spacing = spacing
	wall.post_count = post_count
	wall.post_width = post_width

func _configure_follow(node_name: String, use_bake_interval: bool, direction_source: int) -> void:
	var wall := _get_or_create_wall(node_name)
	if wall == null:
		return
	wall.follow_use_bake_interval = use_bake_interval
	wall.direction_source = direction_source

func _configure_ramp(node_name: String, node_position: Vector3, ramp_width: float, ramp_height: float, ramp_depth: float) -> void:
	var ramp_node := get_node_or_null(NodePath(node_name))
	if ramp_node == null:
		ramp_node = ProtoRamp.new()
		ramp_node.name = node_name
		_add_scene_child(ramp_node)
	if ramp_node is ProtoRamp:
		var ramp: ProtoRamp = ramp_node
		ramp.position = node_position
		ramp.type = ProtoRamp.Type.RAMP
		ramp.width = ramp_width
		ramp.height = ramp_height
		ramp.depth = ramp_depth
		ramp.fill = 1.0

func _configure_box(node_name: String, node_position: Vector3, box_size: Vector3) -> void:
	var box_node := get_node_or_null(NodePath(node_name))
	if box_node == null:
		box_node = CSGBox3D.new()
		box_node.name = node_name
		_add_scene_child(box_node)
	if box_node is CSGBox3D:
		var box: CSGBox3D = box_node
		box.position = node_position
		box.size = box_size
		box.use_collision = true

func _configure_label(node_name: String, node_position: Vector3, label_text: String) -> void:
	var label_node := get_node_or_null(NodePath(node_name))
	if label_node == null:
		label_node = Label3D.new()
		label_node.name = node_name
		_add_scene_child(label_node)
	if label_node is Label3D:
		var label: Label3D = label_node
		label.position = node_position
		label.text = label_text
		label.font_size = 48
		label.outline_size = 4

func _get_or_create_wall(node_name: String) -> ProtoWall:
	var wall_node := get_node_or_null(NodePath(node_name))
	if wall_node == null:
		var wall := ProtoWall.new()
		wall.name = node_name
		_add_scene_child(wall)
		return wall
	if wall_node is ProtoWall:
		return wall_node
	return null

func _ensure_camera_and_light() -> void:
	var light := get_node_or_null("DirectionalLight3D")
	if light == null:
		light = DirectionalLight3D.new()
		light.name = "DirectionalLight3D"
		_add_scene_child(light)
	if light is DirectionalLight3D:
		(light as DirectionalLight3D).rotation = Vector3(-0.8, 0.7, 0.0)

	var camera := get_node_or_null("Camera3D")
	if camera == null:
		camera = Camera3D.new()
		camera.name = "Camera3D"
		_add_scene_child(camera)
	if camera is Camera3D:
		var camera_3d := camera as Camera3D
		match example_type:
			ExampleType.INTERPOLATION_SHOWCASE:
				camera_3d.position = Vector3(2.0, 42.0, 36.0)
				camera_3d.rotation = Vector3(-0.95, 0.0, 0.0)
			ExampleType.MIXED_BLOCKOUT:
				camera_3d.position = Vector3(2.5, 10.0, 16.0)
				camera_3d.rotation = Vector3(-0.58, 0.0, 0.0)
			_:
				camera_3d.position = Vector3(1.0, 9.0, 16.0)
				camera_3d.rotation = Vector3(-0.56, 0.02, 0.0)

func _add_scene_child(node: Node) -> void:
	add_child(node)
	var scene_owner := owner if owner != null else self
	if scene_owner != null:
		node.owner = scene_owner

func _create_polyline_curve(points: Array) -> Curve3D:
	var new_curve := Curve3D.new()
	new_curve.bake_interval = 0.2
	for point in points:
		new_curve.add_point(point)
	return new_curve

func _create_showcase_curve(elevated: bool, xz_scale: float = 1.0) -> Curve3D:
	var curve := Curve3D.new()
	curve.bake_interval = 0.35
	var heights := [0.0, 0.55, -0.15, 0.8, 0.2] if elevated else [0.0, 0.0, 0.0, 0.0, 0.0]
	curve.add_point(_scale_showcase_xz(Vector3(0.0, heights[0], 0.0), xz_scale), Vector3.ZERO, _scale_showcase_xz(Vector3(0.7, 0.0, 0.35), xz_scale))
	curve.add_point(_scale_showcase_xz(Vector3(1.1, heights[1], 0.9), xz_scale), _scale_showcase_xz(Vector3(-0.5, 0.0, -0.4), xz_scale), _scale_showcase_xz(Vector3(0.65, 0.0, 0.45), xz_scale))
	curve.add_point(_scale_showcase_xz(Vector3(2.3, heights[2], 0.2), xz_scale), _scale_showcase_xz(Vector3(-0.6, 0.0, -0.45), xz_scale), _scale_showcase_xz(Vector3(0.7, 0.0, 0.35), xz_scale))
	curve.add_point(_scale_showcase_xz(Vector3(3.4, heights[3], 1.15), xz_scale), _scale_showcase_xz(Vector3(-0.6, 0.0, -0.45), xz_scale), _scale_showcase_xz(Vector3(0.65, 0.0, 0.2), xz_scale))
	curve.add_point(_scale_showcase_xz(Vector3(4.1, heights[4], 0.35), xz_scale), _scale_showcase_xz(Vector3(-0.45, 0.0, -0.35), xz_scale), Vector3.ZERO)
	return curve

func _scale_showcase_xz(point: Vector3, xz_scale: float) -> Vector3:
	return Vector3(point.x * xz_scale, point.y, point.z * xz_scale)

func _create_mountain_curve() -> Curve3D:
	var new_curve := Curve3D.new()
	new_curve.bake_interval = 0.35
	new_curve.add_point(Vector3(-2.2, 0.0, 0.0), Vector3.ZERO, Vector3(0.8, 0.4, 0.7))
	new_curve.add_point(Vector3(-0.8, 0.85, 1.2), Vector3(-0.7, -0.25, -0.4), Vector3(0.9, 0.35, 0.65))
	new_curve.add_point(Vector3(0.8, 0.35, 2.4), Vector3(-0.8, 0.25, -0.55), Vector3(0.9, 0.65, 0.55))
	new_curve.add_point(Vector3(2.2, 1.55, 3.7), Vector3(-0.7, -0.55, -0.55), Vector3(0.7, 0.1, 0.8))
	new_curve.add_point(Vector3(3.1, 1.15, 5.1), Vector3(-0.5, 0.25, -0.8), Vector3.ZERO)
	new_curve.set_point_tilt(1, deg_to_rad(8.0))
	new_curve.set_point_tilt(2, deg_to_rad(-6.0))
	new_curve.set_point_tilt(3, deg_to_rad(10.0))
	return new_curve

func _create_arc_curve(radius: float, angle_degrees: float, segments: int) -> Curve3D:
	return _create_polyline_curve(_arc_points(radius, angle_degrees, segments))

func _arc_points(radius: float, angle_degrees: float, segments: int) -> Array:
	var points: Array = []
	for index in range(segments + 1):
		var ratio := float(index) / float(segments)
		var angle := deg_to_rad(angle_degrees * ratio)
		points.append(Vector3(cos(angle) * radius - radius, 0, sin(angle) * radius))
	return points

func _get_interpolation_showcase_groups() -> Array[Dictionary]:
	return [
		{"name": "FlatPathPerp", "title": "Flat XZ\nPath Perpendicular", "x": -24.0, "elevated": false, "xz_scale": 1.0, "orientation": ProtoWall.PathOrientation.PATH_PERPENDICULAR},
		{"name": "FlatFixedUp", "title": "Flat XZ\nFixed Up", "x": -8.0, "elevated": false, "xz_scale": 1.0, "orientation": ProtoWall.PathOrientation.FIXED_UP},
		{"name": "ElevatedPathPerp", "title": "Elevated 1.75x\nPath Perpendicular", "x": 8.0, "elevated": true, "xz_scale": 1.75, "orientation": ProtoWall.PathOrientation.PATH_PERPENDICULAR},
		{"name": "ElevatedFixedUp", "title": "Elevated\nFixed Up", "x": 24.0, "elevated": true, "xz_scale": 1.0, "orientation": ProtoWall.PathOrientation.FIXED_UP},
	]

func _get_interpolation_showcase_modes() -> Array[Dictionary]:
	return [
		{"name": "BakedLinear", "title": "Baked Linear", "mode": ProtoWall.PathInterpolation.BAKED_LINEAR, "note": "Predictable generated sections from baked curve samples."},
		{"name": "BakedCubic", "title": "Baked Cubic", "mode": ProtoWall.PathInterpolation.BAKED_CUBIC, "note": "Smoother cubic interpolation between baked samples."},
		{"name": "Bezier", "title": "Bezier", "mode": ProtoWall.PathInterpolation.BEZIER, "note": "Direct Bezier handle evaluation for authored curves."},
		{"name": "CornerRounded", "title": "Corner Rounded", "mode": ProtoWall.PathInterpolation.CORNER_ROUNDED, "note": "Straight spans with rounded, bounded corners."},
		{"name": "FilletPath", "title": "Fillet Path", "mode": ProtoWall.PathInterpolation.FILLET_PATH, "note": "Circular 3D fillets at control-point corners."},
		{"name": "CatmullRom", "title": "Centripetal Catmull-Rom", "mode": ProtoWall.PathInterpolation.CENTRIPETAL_CATMULL_ROM, "note": "Smooth curve through points with reduced overshoot."},
		{"name": "ArcLine", "title": "Arc Line", "mode": ProtoWall.PathInterpolation.ARC_LINE, "note": "Road-like horizontal arcs with linear elevation."},
		{"name": "ParallelTransport", "title": "Parallel Transport Bezier", "mode": ProtoWall.PathInterpolation.PARALLEL_TRANSPORT_BEZIER, "note": "Adaptive Bezier path with twist-minimized frames."},
		{"name": "FollowCurved", "title": "Follow Curved Path3D", "mode": ProtoWall.PathInterpolation.FOLLOW_CURVED_PATH3D, "note": "Follows Godot's baked Path3D curve with follow options."},
		{"name": "Linear", "title": "Linear", "mode": ProtoWall.PathInterpolation.LINEAR, "note": "Straight control-point segments with mitered corners."},
	]
