@tool
extends Path3D
## Path-based CSG wall and rail generator for fast 3D blockouts.
##
## ProtoWall uses this node's [member Path3D.curve] as the source path and
## generates child CSG meshes for solid walls, rail bars, and optional posts.

## Emitted when [member style] changes.
signal style_changed
## Emitted when [member height] changes.
signal height_changed
## Emitted when [member thickness] changes.
signal thickness_changed
## Emitted when [member side] changes.
signal side_changed
## Emitted when [member collisions_enabled] changes.
signal collisions_enabled_changed
## Emitted when [member material] changes.
signal material_changed
## Emitted when a path sampling or orientation property changes.
signal path_settings_changed
## Emitted when a rail or post property changes.
signal rail_settings_changed

## Selects whether ProtoWall generates one continuous wall body or rail bars.
enum Style {
	## Generates a continuous swept wall mesh.
	SOLID,
	## Generates horizontal rail bars and optional posts.
	RAIL,
}

## Selects how generated geometry is offset relative to the path centerline.
enum Side {
	## Centers the generated width on the path.
	CENTER,
	## Places generated geometry to the path's left side.
	LEFT,
	## Places generated geometry to the path's right side.
	RIGHT,
}

## Selects how wall height and side axes are built from the sampled path.
enum PathOrientation {
	## Uses the sampled 3D path tangent as the wall forward axis.
	PATH_PERPENDICULAR,
	## Keeps wall height aligned to [constant Vector3.UP].
	FIXED_UP,
}

## Selects how [member Path3D.curve] is converted into generated wall samples.
enum PathInterpolation {
	## Samples Godot's baked curve linearly using [member path_sample_spacing].
	BAKED_LINEAR,
	## Samples Godot's baked curve cubically using [member path_sample_spacing].
	BAKED_CUBIC,
	## Evaluates each Curve3D Bezier segment directly from its control handles.
	BEZIER,
	## Keeps straight spans and rounds corners with bounded cubic blends.
	CORNER_ROUNDED,
	## Keeps straight spans and rounds corners with circular 3D fillets.
	FILLET_PATH,
	## Creates a smooth centripetal Catmull-Rom curve through control points.
	CENTRIPETAL_CATMULL_ROM,
	## Keeps straight spans and uses horizontal arc turns with linear elevation.
	ARC_LINE,
	## Uses adaptive Bezier samples and optional rotation-minimizing frames.
	PARALLEL_TRANSPORT_BEZIER,
	## Follows Godot's edited Path3D curve through cubic baked sampling.
	FOLLOW_CURVED_PATH3D,
	## Connects control points with straight segments and mitered corner frames.
	LINEAR,
}

## Selects how ProtoWall computes orientation along generated samples.
enum FollowDirectionSource {
	## Aligns direction to the final generated segment after simplification.
	GENERATED_SEGMENT,
	## Uses tangents from the selected interpolation mode.
	CURVE_TANGENT,
}

## Selects how rail posts are distributed along the generated path.
enum PostPlacement {
	## Places posts at a fixed distance interval.
	SPACING,
	## Places an explicit number of posts across the full path length.
	COUNT,
}

const GENERATED_PREFIX := "GeneratedProtoWall"
const MIN_DIMENSION := 0.001
const MAX_HEIGHT := 5.0
const MAX_THICKNESS := 1.0
const MIN_PATH_SAMPLE_SPACING := 0.01
const MAX_PATH_SAMPLE_SPACING := 2.0
const MIN_POST_SPACING := 0.1
const MAX_CORNER_SEGMENT_SHARE := 0.75
const MAX_LINEAR_MITER_SCALE := 8.0
const VERTICAL_SPIKE_PLANAR_ANGLE := 60.0
const VERTICAL_SPIKE_HEIGHT_RATIO := 0.35
const VERTICAL_SPIKE_THICKNESS_RATIO := 1.25
const MIN_VERTICAL_SPIKE_AGGRESSIVENESS := 0.1
const MAX_VERTICAL_SPIKE_AGGRESSIVENESS := 4.0

const _default_style := Style.SOLID
const _default_height := 2.0
const _default_thickness := 0.25
const _default_side := Side.CENTER
const _default_path_orientation := PathOrientation.PATH_PERPENDICULAR
const _default_path_interpolation := PathInterpolation.CORNER_ROUNDED
const _default_corner_rounding := 0.05
const _default_corner_angle_step := 10.0
const _default_sample_simplify_angle := 1.0
const _default_preserve_vertical_spikes := false
const _default_vertical_spike_aggressiveness := 1.0
const _default_follow_use_bake_interval := false
const _default_direction_source := FollowDirectionSource.CURVE_TANGENT
const _default_collisions_enabled := true
const _default_path_sample_spacing := 0.25
const _default_rail_count := 2
const _default_rail_thickness := 0.12
const _default_lower_rail_height := 0.45
const _default_post_enabled := true
const _default_post_placement := PostPlacement.SPACING
const _default_post_spacing := 1.5
const _default_post_count := 4
const _default_post_width := 0.18
const _default_post_at_start := true
const _default_post_at_end := true

var _style: int = _default_style
var _height := _default_height
var _thickness := _default_thickness
var _side: int = _default_side
var _path_orientation: int = _default_path_orientation
var _path_interpolation: int = _default_path_interpolation
var _corner_rounding := _default_corner_rounding
var _corner_angle_step := _default_corner_angle_step
var _sample_simplify_angle := _default_sample_simplify_angle
var _preserve_vertical_spikes := _default_preserve_vertical_spikes
var _vertical_spike_aggressiveness := _default_vertical_spike_aggressiveness
var _follow_use_bake_interval := _default_follow_use_bake_interval
var _direction_source: int = _default_direction_source
var _collisions_enabled := _default_collisions_enabled
var _path_sample_spacing := _default_path_sample_spacing
var _rail_count := _default_rail_count
var _rail_thickness := _default_rail_thickness
var _lower_rail_height := _default_lower_rail_height
var _post_enabled := _default_post_enabled
var _post_placement: int = _default_post_placement
var _post_spacing := _default_post_spacing
var _post_count := _default_post_count
var _post_width := _default_post_width
var _post_at_start := _default_post_at_start
var _post_at_end := _default_post_at_end
var _material: Material = null

## Selects the generated shape type. [enum Style.SOLID] creates one swept wall
## body; [enum Style.RAIL] creates rail bars and optional posts.
var style: int: set = set_style, get = get_style
## Total generated wall or rail height in local units. Rail bars and posts are
## clamped to fit inside this height.
var height: float: set = set_height, get = get_height
## Width of the generated wall footprint, rail bars, and rail posts. This is
## measured perpendicular to the sampled path.
var thickness: float: set = set_thickness, get = get_thickness
## Controls whether generated geometry is centered on the path, offset left, or
## offset right according to the sampled wall side axis.
var side: int: set = set_side, get = get_side
## Controls whether generated sections pitch with the sampled 3D path tangent or
## keep their height upright against [constant Vector3.UP].
var path_orientation: int: set = set_path_orientation, get = get_path_orientation
## Controls how [member Path3D.curve] is sampled before walls, rails, posts, and
## gizmos are generated.
var path_interpolation: int: set = set_path_interpolation, get = get_path_interpolation
## Corner smoothing amount for corner-based modes. Higher values use more of each
## adjacent segment for the corner blend or arc.
var corner_rounding: float: set = set_corner_rounding, get = get_corner_rounding
## Maximum angular step for generated corner arcs and adaptive Bezier sampling.
## Higher values generate fewer curved sections.
var corner_angle_step: float: set = set_corner_angle_step, get = get_corner_angle_step
## Bounded-error simplification tolerance in degrees. Set to [code]0[/code] to
## keep all generated samples from the selected interpolation mode.
var sample_simplify_angle: float: set = set_sample_simplify_angle, get = get_sample_simplify_angle
## When enabled, abrupt vertical hills or dips on otherwise straight XZ spans are
## kept as sharp control points instead of being smoothed by interpolation.
var preserve_vertical_spikes: bool: set = set_preserve_vertical_spikes, get = get_preserve_vertical_spikes
## Controls how easily [member preserve_vertical_spikes] treats vertical changes
## as protected sharp points. Higher values preserve more hills and dips.
var vertical_spike_aggressiveness: float: set = set_vertical_spike_aggressiveness, get = get_vertical_spike_aggressiveness
## Follow Curved Path3D only. When enabled, [member Curve3D.bake_interval] drives
## generated sample density and [member path_sample_spacing] is ignored.
var follow_use_bake_interval: bool: set = set_follow_use_bake_interval, get = get_follow_use_bake_interval
## Chooses whether orientation follows final generated segments or the selected
## interpolation mode's sampled tangents.
var direction_source: int: set = set_direction_source, get = get_direction_source
var follow_direction_source: int: set = set_follow_direction_source, get = get_follow_direction_source
## Enables collision on generated CSG wall, rail, and post nodes.
var collisions_enabled: bool: set = set_collisions_enabled, get = get_collisions_enabled
## Distance between generated samples for modes that sample by path length. Lower
## values create more sections; higher values create simpler geometry.
var path_sample_spacing: float: set = set_path_sample_spacing, get = get_path_sample_spacing
## Rail style only. Number of horizontal rail bars to generate.
var rail_count: int: set = set_rail_count, get = get_rail_count
## Rail style only. Vertical thickness of each rail bar, clamped so bars can fit
## within the total rail height.
var rail_thickness: float: set = set_rail_thickness, get = get_rail_thickness
## Rail style only. Center height of the lowest rail bar. The inspector range and
## setter are clamped between half rail thickness and the top valid center height.
var lower_rail_height: float: set = set_lower_rail_height, get = get_lower_rail_height
## Rail style only. Enables generated post boxes along the sampled rail path.
var post_enabled: bool: set = set_post_enabled, get = get_post_enabled
## Rail posts only. Chooses fixed spacing or explicit count distribution.
var post_placement: int: set = set_post_placement, get = get_post_placement
## Rail posts only. Distance between posts when [member post_placement] is
## [enum PostPlacement.SPACING].
var post_spacing: float: set = set_post_spacing, get = get_post_spacing
## Rail posts only. Number of posts when [member post_placement] is
## [enum PostPlacement.COUNT].
var post_count: int: set = set_post_count, get = get_post_count
## Rail posts only. Post depth measured along the sampled path direction.
var post_width: float: set = set_post_width, get = get_post_width
## Rail posts only. Adds a post at the start of the path when using spacing mode.
var post_at_start: bool: set = set_post_at_start, get = get_post_at_start
## Rail posts only. Adds a post at the end of an open path when using spacing mode.
var post_at_end: bool: set = set_post_at_end, get = get_post_at_end
## Material assigned to generated wall meshes, rail meshes, and posts.
var material: Variant: set = set_material, get = get_material

var generated_shapes: Array[Node3D] = []
var gizmos = null
var is_refreshing := false
var connected_curve: Curve3D = null
var sampled_path_points := PackedVector3Array()
var sampled_path_offsets := PackedFloat32Array()
var sampled_path_tilts := PackedFloat32Array()
var sampled_path_forwards := PackedVector3Array()
var sampled_path_keep: Array = []
var sampled_path_bases: Array = []
var sampled_path_length := 0.0
var sampled_path_dirty := true
var sampled_basis_dirty := true
var tracked_curve_bake_interval := -1.0

func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"name": "Proto Wall", "type": TYPE_NIL, "usage": PROPERTY_USAGE_CATEGORY},
		{"name": "style", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Solid,Rail"},
		{"name": "collisions_enabled", "type": TYPE_BOOL},
		{"name": "material", "type": TYPE_OBJECT, "hint": PROPERTY_HINT_RESOURCE_TYPE, "hint_string": "BaseMaterial3D,ShaderMaterial", "usage": PROPERTY_USAGE_DEFAULT},
		{"name": "Path", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP},
		{"name": "side", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Center,Left,Right"},
		{"name": "path_orientation", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Path Perpendicular,Fixed Up"},
		{"name": "path_interpolation", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Baked Linear,Baked Cubic,Bezier,Corner Rounded,Fillet Path,Centripetal Catmull-Rom,Arc Line,Parallel Transport Bezier,Follow Curved Path3D,Linear"},
	]
	if path_interpolation == PathInterpolation.FOLLOW_CURVED_PATH3D:
		list.append({"name": "follow_use_bake_interval", "type": TYPE_BOOL})
		if _uses_path_sample_spacing():
			list.append({"name": "path_sample_spacing", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.01,2,0.01"})
	elif _uses_path_sample_spacing():
		list.append({"name": "path_sample_spacing", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.01,2,0.01"})

	list.append({"name": "direction_source", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Generated Segment,Interpolation Tangent"})

	if _uses_corner_settings():
		list.append({"name": "corner_rounding", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,1.00,0.01"})

	if _uses_angle_step_setting():
		list.append({"name": "corner_angle_step", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "1,45,1"})

	if _uses_sample_simplify():
		list.append({"name": "sample_simplify_angle", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,15,0.1"})

	if _uses_vertical_spike_protection():
		list.append({"name": "preserve_vertical_spikes", "type": TYPE_BOOL})
		if preserve_vertical_spikes:
			list.append({"name": "vertical_spike_aggressiveness", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.1,4,0.05"})

	list += [
		{"name": "Dimensions", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP},
		{"name": "height", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,5,0.01"},
		{"name": "thickness", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,1,0.01"},
	]

	if style == Style.RAIL:
		list += [
			{"name": "Rail", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP},
			{"name": "rail_count", "type": TYPE_INT, "hint": PROPERTY_HINT_RANGE, "hint_string": "1,8,1,or_greater"},
			{"name": "rail_thickness", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,1,0.01"},
			{"name": "lower_rail_height", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0,5,0.01"},
			{"name": "post_enabled", "type": TYPE_BOOL},
		]

		if post_enabled:
			list += [
				{"name": "Posts", "type": TYPE_NIL, "usage": PROPERTY_USAGE_GROUP},
				{"name": "post_placement", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Spacing,Count"},
			]
			if post_placement == PostPlacement.SPACING:
				list += [
					{"name": "post_spacing", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.1,100,0.1,or_greater"},
					{"name": "post_at_start", "type": TYPE_BOOL},
					{"name": "post_at_end", "type": TYPE_BOOL},
				]
			else:
				list.append({"name": "post_count", "type": TYPE_INT, "hint": PROPERTY_HINT_RANGE, "hint_string": "1,128,1,or_greater"})
			list += [
				{"name": "post_width", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,1,0.01"},
			]

	return list

func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"style":
			set_style(value)
			return true
		&"height":
			set_height(value)
			return true
		&"thickness":
			set_thickness(value)
			return true
		&"side":
			set_side(value)
			return true
		&"path_orientation":
			set_path_orientation(value)
			return true
		&"path_interpolation":
			set_path_interpolation(value)
			return true
		&"corner_rounding":
			set_corner_rounding(value)
			return true
		&"corner_angle_step":
			set_corner_angle_step(value)
			return true
		&"sample_simplify_angle":
			set_sample_simplify_angle(value)
			return true
		&"preserve_vertical_spikes":
			set_preserve_vertical_spikes(value)
			return true
		&"vertical_spike_aggressiveness":
			set_vertical_spike_aggressiveness(value)
			return true
		&"follow_use_bake_interval":
			set_follow_use_bake_interval(value)
			return true
		&"direction_source":
			set_direction_source(value)
			return true
		&"follow_direction_source":
			set_follow_direction_source(value)
			return true
		&"collisions_enabled":
			set_collisions_enabled(value)
			return true
		&"path_sample_spacing":
			set_path_sample_spacing(value)
			return true
		&"rail_count":
			set_rail_count(value)
			return true
		&"rail_thickness":
			set_rail_thickness(value)
			return true
		&"lower_rail_height":
			set_lower_rail_height(value)
			return true
		&"post_enabled":
			set_post_enabled(value)
			return true
		&"post_placement":
			set_post_placement(value)
			return true
		&"post_spacing":
			set_post_spacing(value)
			return true
		&"post_count":
			set_post_count(value)
			return true
		&"post_width":
			set_post_width(value)
			return true
		&"post_at_start":
			set_post_at_start(value)
			return true
		&"post_at_end":
			set_post_at_end(value)
			return true
		&"material":
			set_material(value)
			return true
	return false

func _property_can_revert(property: StringName) -> bool:
	return property in [
		&"style",
		&"height",
		&"thickness",
		&"side",
		&"path_orientation",
		&"path_interpolation",
		&"corner_rounding",
		&"corner_angle_step",
		&"sample_simplify_angle",
		&"preserve_vertical_spikes",
		&"vertical_spike_aggressiveness",
		&"follow_use_bake_interval",
		&"direction_source",
		&"follow_direction_source",
		&"collisions_enabled",
		&"path_sample_spacing",
		&"rail_count",
		&"rail_thickness",
		&"lower_rail_height",
		&"post_enabled",
		&"post_placement",
		&"post_spacing",
		&"post_count",
		&"post_width",
		&"post_at_start",
		&"post_at_end",
		&"material",
	]

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"style":
			return _default_style
		&"height":
			return _default_height
		&"thickness":
			return _default_thickness
		&"side":
			return _default_side
		&"path_orientation":
			return _default_path_orientation
		&"path_interpolation":
			return _default_path_interpolation
		&"corner_rounding":
			return _default_corner_rounding
		&"corner_angle_step":
			return _default_corner_angle_step
		&"sample_simplify_angle":
			return _default_sample_simplify_angle
		&"preserve_vertical_spikes":
			return _default_preserve_vertical_spikes
		&"vertical_spike_aggressiveness":
			return _default_vertical_spike_aggressiveness
		&"follow_use_bake_interval":
			return _default_follow_use_bake_interval
		&"direction_source":
			return _default_direction_source
		&"follow_direction_source":
			return _default_direction_source
		&"collisions_enabled":
			return _default_collisions_enabled
		&"path_sample_spacing":
			return _default_path_sample_spacing
		&"rail_count":
			return _default_rail_count
		&"rail_thickness":
			return _default_rail_thickness
		&"lower_rail_height":
			return _default_lower_rail_height
		&"post_enabled":
			return _default_post_enabled
		&"post_placement":
			return _default_post_placement
		&"post_spacing":
			return _default_post_spacing
		&"post_count":
			return _default_post_count
		&"post_width":
			return _default_post_width
		&"post_at_start":
			return _default_post_at_start
		&"post_at_end":
			return _default_post_at_end
		&"material":
			return null
	return null

func get_proto_gizmo_provider() -> Variant:
	return gizmos

func get_proto_gizmo_selection_nodes() -> Array:
	return generated_shapes

func get_style() -> int:
	return _style

func get_height() -> float:
	return _height

func get_thickness() -> float:
	return _thickness

func get_side() -> int:
	return _side

func get_path_orientation() -> int:
	return _path_orientation

func get_path_interpolation() -> int:
	return _path_interpolation

func get_corner_rounding() -> float:
	return _corner_rounding

func get_corner_angle_step() -> float:
	return _corner_angle_step

func get_sample_simplify_angle() -> float:
	return _sample_simplify_angle

func get_preserve_vertical_spikes() -> bool:
	return _preserve_vertical_spikes

func get_vertical_spike_aggressiveness() -> float:
	return _vertical_spike_aggressiveness

func get_follow_use_bake_interval() -> bool:
	return _follow_use_bake_interval

func get_direction_source() -> int:
	return _direction_source

func get_follow_direction_source() -> int:
	return get_direction_source()

func get_collisions_enabled() -> bool:
	return _collisions_enabled

func get_path_sample_spacing() -> float:
	return _path_sample_spacing

func get_rail_count() -> int:
	return _rail_count

func get_rail_thickness() -> float:
	return _rail_thickness

func get_lower_rail_height() -> float:
	return _get_clamped_lower_rail_height(_lower_rail_height)

func get_post_enabled() -> bool:
	return _post_enabled

func get_post_placement() -> int:
	return _post_placement

func get_post_spacing() -> float:
	return _post_spacing

func get_post_count() -> int:
	return _post_count

func get_post_width() -> float:
	return _post_width

func get_post_at_start() -> bool:
	return _post_at_start

func get_post_at_end() -> bool:
	return _post_at_end

func get_material() -> Variant:
	return _material

func set_style(value: int) -> void:
	_style = value
	notify_property_list_changed()
	refresh_shape()
	style_changed.emit()
	update_gizmos()

func set_height(value: float) -> void:
	_height = clamp(value, MIN_DIMENSION, MAX_HEIGHT)
	refresh_shape()
	height_changed.emit()
	update_gizmos()

func set_thickness(value: float) -> void:
	_thickness = clamp(value, MIN_DIMENSION, MAX_THICKNESS)
	refresh_shape()
	thickness_changed.emit()
	update_gizmos()

func set_side(value: int) -> void:
	_side = value
	refresh_shape()
	side_changed.emit()
	update_gizmos()

func set_path_orientation(value: int) -> void:
	_path_orientation = clampi(value, PathOrientation.PATH_PERPENDICULAR, PathOrientation.FIXED_UP)
	_mark_sampled_basis_dirty()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func set_path_interpolation(value: int) -> void:
	_path_interpolation = clampi(value, PathInterpolation.BAKED_LINEAR, PathInterpolation.LINEAR)
	_mark_sampled_path_dirty()
	notify_property_list_changed()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func _uses_corner_settings() -> bool:
	return path_interpolation in [
		PathInterpolation.CORNER_ROUNDED,
		PathInterpolation.FILLET_PATH,
		PathInterpolation.ARC_LINE,
	]

func _uses_angle_step_setting() -> bool:
	return _uses_corner_settings() or path_interpolation == PathInterpolation.PARALLEL_TRANSPORT_BEZIER

func _uses_parallel_transport() -> bool:
	return path_interpolation == PathInterpolation.PARALLEL_TRANSPORT_BEZIER and path_orientation == PathOrientation.PATH_PERPENDICULAR

func _uses_path_sample_spacing() -> bool:
	if path_interpolation == PathInterpolation.LINEAR:
		return false
	if path_interpolation == PathInterpolation.FOLLOW_CURVED_PATH3D and follow_use_bake_interval:
		return false
	return true

func _uses_sample_simplify() -> bool:
	return path_interpolation != PathInterpolation.LINEAR

func _uses_vertical_spike_protection() -> bool:
	return path_interpolation in [
		PathInterpolation.BEZIER,
		PathInterpolation.CORNER_ROUNDED,
		PathInterpolation.FILLET_PATH,
		PathInterpolation.CENTRIPETAL_CATMULL_ROM,
		PathInterpolation.ARC_LINE,
		PathInterpolation.PARALLEL_TRANSPORT_BEZIER,
	]

func set_corner_rounding(value: float) -> void:
	_corner_rounding = clamp(value, 0.0, 1.0)
	_mark_sampled_path_dirty()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func set_corner_angle_step(value: float) -> void:
	_corner_angle_step = clamp(value, 1.0, 45.0)
	_mark_sampled_path_dirty()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func set_sample_simplify_angle(value: float) -> void:
	_sample_simplify_angle = clamp(value, 0.0, 15.0)
	_mark_sampled_path_dirty()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func set_preserve_vertical_spikes(value: bool) -> void:
	_preserve_vertical_spikes = value
	_mark_sampled_path_dirty()
	notify_property_list_changed()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func set_vertical_spike_aggressiveness(value: float) -> void:
	_vertical_spike_aggressiveness = clamp(value, MIN_VERTICAL_SPIKE_AGGRESSIVENESS, MAX_VERTICAL_SPIKE_AGGRESSIVENESS)
	_mark_sampled_path_dirty()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func set_follow_use_bake_interval(value: bool) -> void:
	_follow_use_bake_interval = value
	_mark_sampled_path_dirty()
	notify_property_list_changed()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func set_direction_source(value: int) -> void:
	_direction_source = clampi(value, FollowDirectionSource.GENERATED_SEGMENT, FollowDirectionSource.CURVE_TANGENT)
	_mark_sampled_path_dirty()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func set_follow_direction_source(value: int) -> void:
	set_direction_source(value)

func set_collisions_enabled(value: bool) -> void:
	_collisions_enabled = value
	refresh_shape()
	collisions_enabled_changed.emit()

func set_path_sample_spacing(value: float) -> void:
	_path_sample_spacing = clamp(value, MIN_PATH_SAMPLE_SPACING, MAX_PATH_SAMPLE_SPACING)
	_mark_sampled_path_dirty()
	refresh_shape()
	path_settings_changed.emit()
	update_gizmos()

func set_rail_count(value: int) -> void:
	_rail_count = max(1, value)
	_rail_thickness = _get_clamped_rail_thickness(_rail_thickness)
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_rail_thickness(value: float) -> void:
	_rail_thickness = _get_clamped_rail_thickness(value)
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_lower_rail_height(value: float) -> void:
	_lower_rail_height = _get_clamped_lower_rail_height(value)
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_post_enabled(value: bool) -> void:
	_post_enabled = value
	notify_property_list_changed()
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_post_placement(value: int) -> void:
	_post_placement = value
	notify_property_list_changed()
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_post_spacing(value: float) -> void:
	_post_spacing = max(MIN_POST_SPACING, value)
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_post_count(value: int) -> void:
	_post_count = max(1, value)
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_post_width(value: float) -> void:
	_post_width = clamp(value, MIN_DIMENSION, MAX_THICKNESS)
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_post_at_start(value: bool) -> void:
	_post_at_start = value
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_post_at_end(value: bool) -> void:
	_post_at_end = value
	refresh_shape()
	rail_settings_changed.emit()
	update_gizmos()

func set_material(value: Variant) -> void:
	_material = value if value is Material else null
	refresh_shape()
	material_changed.emit()

func refresh_shape() -> void:
	if not is_inside_tree():
		return
	if is_refreshing:
		return

	is_refreshing = true
	_ensure_default_curve()
	_connect_curve_changed()
	_ensure_sampled_path()
	_ensure_sampled_bases()
	_clear_generated_shapes()

	match style:
		Style.SOLID:
			_create_solid_wall()
		Style.RAIL:
			_create_rails()
			_create_posts()
	is_refreshing = false

func get_path_length() -> float:
	_ensure_sampled_path()
	return sampled_path_length

func is_curve_closed() -> bool:
	return curve != null and curve.closed

func get_middle_path_offset() -> float:
	return get_path_length() / 2.0

func get_path_point(offset: float) -> Vector3:
	_ensure_sampled_path()
	if sampled_path_points.is_empty():
		return Vector3.ZERO
	return _sample_path_point(offset)

func get_path_forward(offset: float) -> Vector3:
	return _sample_path_basis(offset).z

func get_wall_up_axis(offset: float) -> Vector3:
	return _sample_path_basis(offset).y

func get_wall_basis(offset: float) -> Basis:
	return _sample_path_basis(offset)

func get_path_side_axis(offset: float) -> Vector3:
	return -_sample_path_basis(offset).x

func get_wall_side_axis(offset: float) -> Vector3:
	return _sample_path_basis(offset).x

func get_side_center_offset(width: float) -> float:
	match side:
		Side.LEFT:
			return -width / 2.0
		Side.RIGHT:
			return width / 2.0
	return 0.0

func get_side_outer_offset(width: float) -> float:
	match side:
		Side.LEFT:
			return -width
		Side.RIGHT:
			return width
	return width / 2.0

func get_rail_center_height(index: int) -> float:
	var top_center := max(rail_thickness / 2.0, height - rail_thickness / 2.0)
	if rail_count <= 1:
		return top_center

	var bottom_center := _get_clamped_lower_rail_height(lower_rail_height)
	var ratio := float(index) / float(max(1, rail_count - 1))
	return lerp(bottom_center, top_center, ratio)

func _enter_tree() -> void:
	set_process(Engine.is_editor_hint())
	_ensure_default_curve()
	refresh_shape()
	_connect_curve_changed()
	if Engine.is_editor_hint():
		var ProtoWallGizmos = load("res://addons/proto_shape/proto_wall/proto_wall_gizmos.gd")
		gizmos = ProtoWallGizmos.new()
		gizmos.attach_shape(self)

func _exit_tree() -> void:
	set_process(false)
	_disconnect_curve_changed()
	_clear_generated_shapes()
	if Engine.is_editor_hint() and gizmos != null:
		gizmos.remove_shape()
		gizmos = null

func _process(_delta: float) -> void:
	if _should_rebuild_for_curve_bake_interval_change():
		_mark_sampled_path_dirty()
		refresh_shape()
		update_gizmos()

func _ensure_default_curve() -> void:
	if curve == null:
		curve = Curve3D.new()
		_mark_sampled_path_dirty()
	if curve.get_point_count() < 2:
		curve.clear_points()
		curve.add_point(Vector3.ZERO)
		curve.add_point(Vector3(0, 0, 4))
		_mark_sampled_path_dirty()

func _ensure_sampled_path() -> void:
	if _should_rebuild_for_curve_bake_interval_change():
		_mark_sampled_path_dirty()
	if sampled_path_dirty and curve != null:
		_rebuild_sampled_path()

func _should_rebuild_for_curve_bake_interval_change() -> bool:
	return curve != null \
		and path_interpolation == PathInterpolation.FOLLOW_CURVED_PATH3D \
		and follow_use_bake_interval \
		and not is_equal_approx(tracked_curve_bake_interval, curve.bake_interval)

func _ensure_sampled_bases() -> void:
	_ensure_sampled_path()
	if sampled_basis_dirty:
		_rebuild_sampled_bases()

func _mark_sampled_path_dirty() -> void:
	sampled_path_dirty = true
	sampled_basis_dirty = true

func _mark_sampled_basis_dirty() -> void:
	sampled_basis_dirty = true

func _rebuild_sampled_path() -> void:
	sampled_path_points.clear()
	sampled_path_offsets.clear()
	sampled_path_tilts.clear()
	sampled_path_forwards.clear()
	sampled_path_keep.clear()
	sampled_path_bases.clear()
	sampled_path_length = 0.0

	if curve == null or curve.get_point_count() < 2:
		return

	match path_interpolation:
		PathInterpolation.BAKED_LINEAR:
			_build_baked_sampled_path(false)
		PathInterpolation.BAKED_CUBIC:
			_build_baked_sampled_path(true)
		PathInterpolation.BEZIER:
			_build_bezier_sampled_path()
		PathInterpolation.CORNER_ROUNDED:
			_build_corner_rounded_sampled_path()
		PathInterpolation.FILLET_PATH:
			_build_fillet_sampled_path()
		PathInterpolation.CENTRIPETAL_CATMULL_ROM:
			_build_catmull_rom_sampled_path()
		PathInterpolation.ARC_LINE:
			_build_arc_line_sampled_path()
		PathInterpolation.PARALLEL_TRANSPORT_BEZIER:
			_build_parallel_transport_bezier_sampled_path()
		PathInterpolation.FOLLOW_CURVED_PATH3D:
			_build_follow_curved_path3d_sampled_path()
		PathInterpolation.LINEAR:
			_build_linear_sampled_path()

	_remove_closed_duplicate_sample()
	_simplify_sampled_path()
	if direction_source == FollowDirectionSource.GENERATED_SEGMENT:
		_rebuild_sampled_forwards_from_segments()
	_rebuild_sample_offsets()
	_track_curve_bake_interval()
	sampled_path_dirty = false
	sampled_basis_dirty = true

func _track_curve_bake_interval() -> void:
	tracked_curve_bake_interval = curve.bake_interval if curve != null else -1.0

func _build_baked_sampled_path(cubic: bool) -> void:
	if _has_vertical_spike_corner():
		_build_bezier_sampled_path()
		return

	var length := curve.get_baked_length()
	if length <= MIN_DIMENSION:
		return

	var offset := 0.0
	while offset < length:
		_append_sample(curve.sample_baked(offset, cubic), _sample_control_tilt_by_baked_offset(offset, length), offset <= MIN_DIMENSION, _sample_baked_forward(offset, length, cubic))
		offset += path_sample_spacing
	if not is_curve_closed():
		_append_sample(curve.sample_baked(length, cubic), _sample_control_tilt_by_baked_offset(length, length), true, _sample_baked_forward(length, length, cubic))

func _build_follow_curved_path3d_sampled_path() -> void:
	var length := curve.get_baked_length()
	if length <= MIN_DIMENSION:
		return
	if follow_use_bake_interval:
		_build_follow_bake_interval_sampled_path(length)
		return

	var offset := 0.0
	while offset < length:
		_append_sample(
			curve.sample_baked(offset, true),
			_sample_control_tilt_by_baked_offset(offset, length),
			offset <= MIN_DIMENSION,
			_sample_follow_curve_forward(offset, length)
		)
		offset += path_sample_spacing
	if not is_curve_closed():
		_append_sample(
			curve.sample_baked(length, true),
			_sample_control_tilt_by_baked_offset(length, length),
			true,
			_sample_follow_curve_forward(length, length)
		)

func _build_follow_bake_interval_sampled_path(length: float) -> void:
	var spacing := _get_follow_bake_interval_sample_spacing()
	var offset := 0.0
	while offset < length:
		_append_sample(
			curve.sample_baked(offset, true),
			_sample_control_tilt_by_baked_offset(offset, length),
			offset <= MIN_DIMENSION,
			_sample_follow_curve_forward(offset, length)
		)
		offset += spacing
	if not is_curve_closed():
		_append_sample(
			curve.sample_baked(length, true),
			_sample_control_tilt_by_baked_offset(length, length),
			true,
			_sample_follow_curve_forward(length, length)
		)

func _get_follow_bake_interval_sample_spacing() -> float:
	var detail := max(0.01, curve.bake_interval if curve != null else 1.0)
	return clamp(_default_path_sample_spacing / detail, MIN_PATH_SAMPLE_SPACING, MAX_PATH_SAMPLE_SPACING)

func _build_bezier_sampled_path() -> void:
	var point_count := curve.get_point_count()
	var segment_count := point_count if is_curve_closed() else point_count - 1
	for segment_index in range(segment_count):
		var next_index := (segment_index + 1) % point_count
		if _segment_has_vertical_spike(segment_index, next_index):
			var from_point := curve.get_point_position(segment_index)
			var to_point := curve.get_point_position(next_index)
			if sampled_path_points.is_empty():
				_append_sample(from_point, curve.get_point_tilt(segment_index), true, _get_control_segment_forward(segment_index, next_index))
			_append_line_samples(from_point, to_point, curve.get_point_tilt(segment_index), curve.get_point_tilt(next_index))
			continue
		var p0 := curve.get_point_position(segment_index)
		var p1 := p0 + curve.get_point_out(segment_index)
		var p3 := curve.get_point_position(next_index)
		var p2 := p3 + curve.get_point_in(next_index)
		var estimated_length := _estimate_bezier_length(p0, p1, p2, p3)
		var steps := max(1, ceili(estimated_length / path_sample_spacing))
		for step in range(steps + 1):
			if segment_index > 0 and step == 0:
				continue
			if is_curve_closed() and segment_index == segment_count - 1 and step == steps:
				continue
			var t := float(step) / float(steps)
			_append_sample(
				_sample_bezier(p0, p1, p2, p3, t),
				lerp_angle(curve.get_point_tilt(segment_index), curve.get_point_tilt(next_index), t),
				step == 0 or step == steps,
				_sample_bezier_tangent(p0, p1, p2, p3, t)
			)

func _build_parallel_transport_bezier_sampled_path() -> void:
	var point_count := curve.get_point_count()
	var segment_count := point_count if is_curve_closed() else point_count - 1
	for segment_index in range(segment_count):
		var next_index := (segment_index + 1) % point_count
		if _segment_has_vertical_spike(segment_index, next_index):
			var from_point := curve.get_point_position(segment_index)
			var to_point := curve.get_point_position(next_index)
			if sampled_path_points.is_empty():
				_append_sample(from_point, curve.get_point_tilt(segment_index), true, _get_control_segment_forward(segment_index, next_index))
			_append_line_samples(from_point, to_point, curve.get_point_tilt(segment_index), curve.get_point_tilt(next_index))
			continue
		var p0 := curve.get_point_position(segment_index)
		var p1 := p0 + curve.get_point_out(segment_index)
		var p3 := curve.get_point_position(next_index)
		var p2 := p3 + curve.get_point_in(next_index)
		if segment_index == 0:
			_append_sample(p0, curve.get_point_tilt(segment_index), true, _sample_bezier_tangent(p0, p1, p2, p3, 0.0))
		_append_adaptive_bezier_samples(
			p0,
			p1,
			p2,
			p3,
			0.0,
			1.0,
			curve.get_point_tilt(segment_index),
			curve.get_point_tilt(next_index),
			0
		)

func _append_adaptive_bezier_samples(
	p0: Vector3,
	p1: Vector3,
	p2: Vector3,
	p3: Vector3,
	from_t: float,
	to_t: float,
	from_tilt: float,
	to_tilt: float,
	depth: int
) -> void:
	var from_point := _sample_bezier(p0, p1, p2, p3, from_t)
	var to_point := _sample_bezier(p0, p1, p2, p3, to_t)
	var from_tangent := _sample_bezier_tangent(p0, p1, p2, p3, from_t)
	var to_tangent := _sample_bezier_tangent(p0, p1, p2, p3, to_t)
	var angle_limit := deg_to_rad(corner_angle_step)
	var needs_split := from_point.distance_to(to_point) > path_sample_spacing or from_tangent.angle_to(to_tangent) > angle_limit
	if needs_split and depth < 12:
		var middle_t := (from_t + to_t) * 0.5
		_append_adaptive_bezier_samples(p0, p1, p2, p3, from_t, middle_t, from_tilt, to_tilt, depth + 1)
		_append_adaptive_bezier_samples(p0, p1, p2, p3, middle_t, to_t, from_tilt, to_tilt, depth + 1)
		return

	var tilt_ratio := to_t
	_append_sample(to_point, lerp_angle(from_tilt, to_tilt, tilt_ratio), to_t >= 1.0 - 0.000001, _sample_bezier_tangent(p0, p1, p2, p3, to_t))

func _build_corner_rounded_sampled_path() -> void:
	var point_count := curve.get_point_count()
	if point_count < 2:
		return
	if point_count < 3 or corner_rounding <= 0.0:
		_build_control_polyline_sampled_path()
		return

	if is_curve_closed():
		_build_closed_corner_rounded_sampled_path()
	else:
		_build_open_corner_rounded_sampled_path()

func _build_control_polyline_sampled_path() -> void:
	var point_count := curve.get_point_count()
	_append_sample(curve.get_point_position(0), curve.get_point_tilt(0), true, _get_control_point_forward(0))
	var segment_count := point_count if is_curve_closed() else point_count - 1
	for index in range(segment_count):
		var next_index := (index + 1) % point_count
		_append_sample(curve.get_point_position(next_index), curve.get_point_tilt(next_index), true, _get_control_point_forward(next_index))

func _build_linear_sampled_path() -> void:
	var point_count := curve.get_point_count()
	if point_count < 2:
		return
	var sample_count := point_count if is_curve_closed() else point_count
	for index in range(sample_count):
		var keep := not is_curve_closed() and (index == 0 or index == point_count - 1)
		_append_sample(curve.get_point_position(index), curve.get_point_tilt(index), keep, _get_linear_control_point_forward(index))

func _build_open_corner_rounded_sampled_path() -> void:
	var point_count := curve.get_point_count()
	_append_sample(curve.get_point_position(0), curve.get_point_tilt(0), true, _get_control_segment_forward(0, 1))
	for index in range(1, point_count - 1):
		var corner := _get_corner_data(index)
		if corner["vertical_spike"]:
			_append_vertical_spike_corner_sample(index)
			continue
		_append_sample(corner["entry_point"], corner["entry_tilt"], true, corner["incoming_forward"])
		_append_corner_rounded_samples(corner)
	_append_sample(curve.get_point_position(point_count - 1), curve.get_point_tilt(point_count - 1), true, _get_control_segment_forward(point_count - 2, point_count - 1))

func _build_closed_corner_rounded_sampled_path() -> void:
	var point_count := curve.get_point_count()
	var first_corner := _get_corner_data(0)
	if first_corner["vertical_spike"]:
		_append_vertical_spike_corner_sample(0)
	else:
		_append_sample(first_corner["exit_point"], first_corner["exit_tilt"], true, first_corner["outgoing_forward"])
	for index in range(1, point_count):
		var corner := _get_corner_data(index)
		if corner["vertical_spike"]:
			_append_vertical_spike_corner_sample(index)
			continue
		_append_sample(corner["entry_point"], corner["entry_tilt"], true, corner["incoming_forward"])
		_append_corner_rounded_samples(corner)
	if not first_corner["vertical_spike"]:
		_append_sample(first_corner["entry_point"], first_corner["entry_tilt"], true, first_corner["incoming_forward"])
		_append_corner_rounded_samples(first_corner)

func _build_fillet_sampled_path() -> void:
	_build_corner_sampled_path(Callable(self, "_append_fillet_samples"))

func _build_arc_line_sampled_path() -> void:
	_build_corner_sampled_path(Callable(self, "_append_arc_line_samples"))

func _build_corner_sampled_path(corner_appender: Callable) -> void:
	var point_count := curve.get_point_count()
	if point_count < 2:
		return
	if point_count < 3 or corner_rounding <= 0.0:
		_build_control_polyline_sampled_path()
		return

	if is_curve_closed():
		var first_corner := _get_corner_data(0)
		if first_corner["vertical_spike"]:
			_append_vertical_spike_corner_sample(0)
		else:
			_append_sample(first_corner["exit_point"], first_corner["exit_tilt"], true, first_corner["outgoing_forward"])
		for index in range(1, point_count):
			var corner := _get_corner_data(index)
			if corner["vertical_spike"]:
				_append_vertical_spike_corner_sample(index)
				continue
			_append_sample(corner["entry_point"], corner["entry_tilt"], true, corner["incoming_forward"])
			corner_appender.call(corner)
		if not first_corner["vertical_spike"]:
			_append_sample(first_corner["entry_point"], first_corner["entry_tilt"], true, first_corner["incoming_forward"])
			corner_appender.call(first_corner)
		return

	_append_sample(curve.get_point_position(0), curve.get_point_tilt(0), true, _get_control_segment_forward(0, 1))
	for index in range(1, point_count - 1):
		var corner := _get_corner_data(index)
		if corner["vertical_spike"]:
			_append_vertical_spike_corner_sample(index)
			continue
		_append_sample(corner["entry_point"], corner["entry_tilt"], true, corner["incoming_forward"])
		corner_appender.call(corner)
	_append_sample(curve.get_point_position(point_count - 1), curve.get_point_tilt(point_count - 1), true, _get_control_segment_forward(point_count - 2, point_count - 1))

func _build_catmull_rom_sampled_path() -> void:
	var point_count := curve.get_point_count()
	if point_count < 2:
		return

	var segment_count := point_count if is_curve_closed() else point_count - 1
	for index in range(segment_count):
		if _segment_has_vertical_spike(index, (index + 1) % point_count):
			var from_point := curve.get_point_position(index)
			var to_point := curve.get_point_position((index + 1) % point_count)
			if sampled_path_points.is_empty():
				_append_sample(from_point, curve.get_point_tilt(index), true, _get_control_segment_forward(index, (index + 1) % point_count))
			_append_line_samples(from_point, to_point, curve.get_point_tilt(index), curve.get_point_tilt((index + 1) % point_count))
			continue
		var p1 := curve.get_point_position(index)
		var p2 := curve.get_point_position((index + 1) % point_count)
		var p0 := _get_catmull_point(index - 1)
		var p3 := _get_catmull_point(index + 2)
		var estimated_length := _estimate_catmull_rom_length(p0, p1, p2, p3)
		var steps := max(1, ceili(estimated_length / path_sample_spacing))
		for step in range(steps + 1):
			if index > 0 and step == 0:
				continue
			if is_curve_closed() and index == segment_count - 1 and step == steps:
				continue
			var t := float(step) / float(steps)
			_append_sample(
				_sample_centripetal_catmull_rom(p0, p1, p2, p3, t),
				lerp_angle(curve.get_point_tilt(index), curve.get_point_tilt((index + 1) % point_count), t),
				step == 0 or step == steps,
				_sample_centripetal_catmull_rom_tangent(p0, p1, p2, p3, t)
			)

func _get_catmull_point(index: int) -> Vector3:
	var point_count := curve.get_point_count()
	if is_curve_closed():
		return curve.get_point_position(posmod(index, point_count))
	if index < 0:
		var first := curve.get_point_position(0)
		return first + first - curve.get_point_position(1)
	if index >= point_count:
		var last := curve.get_point_position(point_count - 1)
		return last + last - curve.get_point_position(point_count - 2)
	return curve.get_point_position(index)

func _sample_centripetal_catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t0 := 0.0
	var t1 := _get_catmull_knot(t0, p0, p1)
	var t2 := _get_catmull_knot(t1, p1, p2)
	var t3 := _get_catmull_knot(t2, p2, p3)
	var sample_t := lerp(t1, t2, t)
	var a1 := _interpolate_knot_point(p0, p1, t0, t1, sample_t)
	var a2 := _interpolate_knot_point(p1, p2, t1, t2, sample_t)
	var a3 := _interpolate_knot_point(p2, p3, t2, t3, sample_t)
	var b1 := _interpolate_knot_point(a1, a2, t0, t2, sample_t)
	var b2 := _interpolate_knot_point(a2, a3, t1, t3, sample_t)
	return _interpolate_knot_point(b1, b2, t1, t2, sample_t)

func _get_catmull_knot(previous_t: float, previous: Vector3, point: Vector3) -> float:
	return previous_t + sqrt(max(MIN_DIMENSION, previous.distance_to(point)))

func _interpolate_knot_point(a: Vector3, b: Vector3, ta: float, tb: float, t: float) -> Vector3:
	var denominator := tb - ta
	if abs(denominator) <= 0.000001:
		return b
	return a * ((tb - t) / denominator) + b * ((t - ta) / denominator)

func _estimate_catmull_rom_length(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> float:
	var length := 0.0
	var previous := p1
	for step in range(1, 13):
		var point := _sample_centripetal_catmull_rom(p0, p1, p2, p3, float(step) / 12.0)
		length += previous.distance_to(point)
		previous = point
	return length

func _get_corner_data(index: int) -> Dictionary:
	var point_count := curve.get_point_count()
	var previous_index := (index - 1 + point_count) % point_count
	var next_index := (index + 1) % point_count
	var previous := curve.get_point_position(previous_index)
	var point := curve.get_point_position(index)
	var next := curve.get_point_position(next_index)
	var previous_length := max(MIN_DIMENSION, previous.distance_to(point))
	var next_length := max(MIN_DIMENSION, point.distance_to(next))
	var vertical_spike := _is_vertical_spike_corner(index)
	var desired_cut := 0.0 if vertical_spike else _get_desired_corner_cut(index)
	var entry_limit := _get_limited_corner_cut(index, previous_index, previous_length, desired_cut)
	var exit_limit := _get_limited_corner_cut(index, next_index, next_length, desired_cut)
	var corner_cut := min(entry_limit, exit_limit)
	var entry_cut := corner_cut
	var exit_cut := corner_cut
	var entry_ratio: float = 1.0 - entry_cut / previous_length
	var exit_ratio: float = exit_cut / next_length
	var incoming_forward := _get_safe_forward(point - previous)
	var outgoing_forward := _get_safe_forward(next - point)
	return {
		"point": point,
		"entry_point": point.lerp(previous, entry_cut / previous_length),
		"exit_point": point.lerp(next, exit_ratio),
		"point_tilt": curve.get_point_tilt(index),
		"entry_tilt": lerp_angle(curve.get_point_tilt(previous_index), curve.get_point_tilt(index), entry_ratio),
		"exit_tilt": lerp_angle(curve.get_point_tilt(index), curve.get_point_tilt(next_index), exit_ratio),
		"incoming_forward": incoming_forward,
		"outgoing_forward": outgoing_forward,
		"vertical_spike": vertical_spike,
	}

func _is_vertical_spike_corner(index: int) -> bool:
	if not _uses_vertical_spike_protection() or not preserve_vertical_spikes:
		return false
	var point_count := curve.get_point_count()
	if point_count < 3:
		return false
	if not is_curve_closed() and (index <= 0 or index >= point_count - 1):
		return false

	var previous := curve.get_point_position((index - 1 + point_count) % point_count)
	var point := curve.get_point_position(index)
	var next := curve.get_point_position((index + 1) % point_count)
	var previous_2d := Vector2(previous.x, previous.z)
	var point_2d := Vector2(point.x, point.z)
	var next_2d := Vector2(next.x, next.z)
	var incoming_2d := point_2d - previous_2d
	var outgoing_2d := next_2d - point_2d
	var incoming_length := incoming_2d.length()
	var outgoing_length := outgoing_2d.length()
	if incoming_length <= MIN_DIMENSION or outgoing_length <= MIN_DIMENSION:
		return false

	var planar_turn := incoming_2d.normalized().angle_to(outgoing_2d.normalized())
	if abs(planar_turn) > deg_to_rad(VERTICAL_SPIKE_PLANAR_ANGLE):
		return false

	var baseline_2d := next_2d - previous_2d
	var baseline_length := baseline_2d.length()
	if baseline_length <= MIN_DIMENSION:
		return false
	var projection_ratio: float = clamp((point_2d - previous_2d).dot(baseline_2d) / (baseline_length * baseline_length), 0.0, 1.0)
	var baseline_y := lerp(previous.y, next.y, projection_ratio)
	var y_delta := abs(point.y - baseline_y)
	var local_planar_length: float = min(incoming_length, outgoing_length)
	var base_threshold: float = max(thickness * VERTICAL_SPIKE_THICKNESS_RATIO, local_planar_length * VERTICAL_SPIKE_HEIGHT_RATIO)
	return y_delta > base_threshold / vertical_spike_aggressiveness

func _segment_has_vertical_spike(from_index: int, to_index: int) -> bool:
	return _is_vertical_spike_corner(from_index) or _is_vertical_spike_corner(to_index)

func _has_vertical_spike_corner() -> bool:
	var point_count := curve.get_point_count()
	if point_count < 3:
		return false
	var start_index := 0 if is_curve_closed() else 1
	var end_index := point_count if is_curve_closed() else point_count - 1
	for index in range(start_index, end_index):
		if _is_vertical_spike_corner(index):
			return true
	return false

func _get_desired_corner_cut(index: int) -> float:
	var point_count := curve.get_point_count()
	var previous_index := (index - 1 + point_count) % point_count
	var next_index := (index + 1) % point_count
	var previous_length := curve.get_point_position(previous_index).distance_to(curve.get_point_position(index))
	var next_length := curve.get_point_position(index).distance_to(curve.get_point_position(next_index))
	return max(0.0, min(previous_length, next_length) * corner_rounding)

func _get_limited_corner_cut(index: int, neighbor_index: int, segment_length: float, desired_cut: float) -> float:
	if desired_cut <= MIN_DIMENSION:
		return 0.0
	if not is_curve_closed() and (neighbor_index <= 0 or neighbor_index >= curve.get_point_count() - 1):
		return min(desired_cut, segment_length * 0.9)

	var neighbor_desired_cut := _get_desired_corner_cut(neighbor_index)
	var total_desired_cut := desired_cut + neighbor_desired_cut
	var available_length := segment_length * MAX_CORNER_SEGMENT_SHARE
	if total_desired_cut <= available_length:
		return desired_cut
	return desired_cut / max(MIN_DIMENSION, total_desired_cut) * available_length

func _get_control_point_forward(index: int) -> Vector3:
	var point_count := curve.get_point_count()
	if point_count < 2:
		return Vector3.FORWARD
	if is_curve_closed():
		var previous := curve.get_point_position(posmod(index - 1, point_count))
		var next := curve.get_point_position(posmod(index + 1, point_count))
		return _get_safe_forward(next - previous)
	if index <= 0:
		return _get_control_segment_forward(0, 1)
	if index >= point_count - 1:
		return _get_control_segment_forward(point_count - 2, point_count - 1)
	return _get_safe_forward(curve.get_point_position(index + 1) - curve.get_point_position(index - 1))

func _get_control_segment_forward(from_index: int, to_index: int) -> Vector3:
	return _get_safe_forward(curve.get_point_position(to_index) - curve.get_point_position(from_index))

func _get_linear_control_point_forward(index: int) -> Vector3:
	var point_count := curve.get_point_count()
	if point_count < 2:
		return Vector3.FORWARD
	if not is_curve_closed() and index <= 0:
		return _get_control_segment_forward(0, 1)
	if not is_curve_closed() and index >= point_count - 1:
		return _get_control_segment_forward(point_count - 2, point_count - 1)

	var previous_index := posmod(index - 1, point_count)
	var next_index := posmod(index + 1, point_count)
	var incoming := _get_control_segment_forward(previous_index, index)
	var outgoing := _get_control_segment_forward(index, next_index)
	var bisector := incoming + outgoing
	if bisector.length_squared() <= 0.000001:
		return outgoing if outgoing.length_squared() > 0.000001 else incoming
	return bisector.normalized()

func _append_vertical_spike_corner_sample(index: int) -> void:
	_append_sample(curve.get_point_position(index), curve.get_point_tilt(index), true, _get_control_point_forward(index))

func _get_safe_forward(direction: Vector3) -> Vector3:
	if direction.length_squared() <= 0.000001:
		return Vector3.FORWARD
	return direction.normalized()

func _point_at_planar_corner_distance(corner_point: Vector3, segment_point: Vector3, planar_distance: float) -> Vector3:
	var planar_direction := Vector2(segment_point.x - corner_point.x, segment_point.z - corner_point.z)
	var planar_length := planar_direction.length()
	if planar_length <= MIN_DIMENSION:
		return segment_point
	var ratio: float = clamp(planar_distance / planar_length, 0.0, 1.0)
	return corner_point.lerp(segment_point, ratio)

func _append_line_samples(from_point: Vector3, to_point: Vector3, from_tilt: float, to_tilt: float) -> void:
	var length := from_point.distance_to(to_point)
	if length <= MIN_DIMENSION:
		_append_sample(to_point, to_tilt, false, _get_safe_forward(to_point - from_point))
		return
	var steps := max(1, ceili(length / path_sample_spacing))
	var forward := _get_safe_forward(to_point - from_point)
	for step in range(1, steps + 1):
		var t := float(step) / float(steps)
		_append_sample(from_point.lerp(to_point, t), lerp_angle(from_tilt, to_tilt, t), false, forward)

func _append_corner_rounded_samples(corner: Dictionary) -> void:
	var entry: Vector3 = corner["entry_point"]
	var point: Vector3 = corner["point"]
	var exit: Vector3 = corner["exit_point"]
	var incoming_forward: Vector3 = corner["incoming_forward"]
	var outgoing_forward: Vector3 = corner["outgoing_forward"]
	var entry_cut := entry.distance_to(point)
	var exit_cut := exit.distance_to(point)
	if entry_cut <= MIN_DIMENSION or exit_cut <= MIN_DIMENSION:
		_append_sample(exit, corner["exit_tilt"], true, outgoing_forward)
		return

	var turn_angle := incoming_forward.angle_to(outgoing_forward)
	if _should_bevel_tight_corner(min(entry_cut, exit_cut), turn_angle):
		_append_tight_corner_round_samples(corner)
		return

	var handle_ratio := _get_rounded_corner_handle_ratio(turn_angle)
	var entry_handle := entry + incoming_forward * entry_cut * handle_ratio
	var exit_handle := exit - outgoing_forward * exit_cut * handle_ratio
	var estimated_length := _estimate_bezier_length(entry, entry_handle, exit_handle, exit)
	var angle_steps := ceili(turn_angle / deg_to_rad(corner_angle_step))
	var length_steps := ceili(estimated_length / path_sample_spacing)
	var steps := max(1, max(angle_steps, length_steps))
	for step in range(1, steps + 1):
		var t := float(step) / float(steps)
		var sample := exit if step == steps else _sample_bezier(entry, entry_handle, exit_handle, exit, t)
		var tilt := lerp_angle(lerp_angle(corner["entry_tilt"], corner["point_tilt"], t), lerp_angle(corner["point_tilt"], corner["exit_tilt"], t), t)
		_append_sample(sample, tilt, step == steps, _sample_bezier_tangent(entry, entry_handle, exit_handle, exit, t))

func _get_rounded_corner_handle_ratio(turn_angle: float) -> float:
	if turn_angle <= deg_to_rad(0.1):
		return 0.0
	var ratio: float = 4.0 / 3.0 * tan(turn_angle * 0.25) / max(0.001, tan(turn_angle * 0.5))
	return clamp(ratio, 0.0, 0.66)

func _append_tight_corner_round_samples(corner: Dictionary) -> void:
	var entry: Vector3 = corner["entry_point"]
	var point: Vector3 = corner["point"]
	var exit: Vector3 = corner["exit_point"]
	var incoming_forward: Vector3 = corner["incoming_forward"]
	var outgoing_forward: Vector3 = corner["outgoing_forward"]
	var chord := exit - entry
	if chord.length_squared() <= 0.000001:
		_append_sample(exit, corner["exit_tilt"], true, outgoing_forward)
		return

	var midpoint := entry.lerp(exit, 0.5)
	var corner_direction := point - midpoint
	var corner_depth := corner_direction.length()
	var clearance: float = min(thickness * 0.75, corner_depth * 0.8)
	var bulge: float = max(0.0, corner_depth - clearance) * 0.35
	var bulge_direction := corner_direction.normalized() if corner_depth > 0.000001 else Vector3.ZERO
	var turn_angle := incoming_forward.angle_to(outgoing_forward)
	var steps := max(3, max(ceili(turn_angle / deg_to_rad(corner_angle_step)), ceili(chord.length() / path_sample_spacing)))
	for step in range(1, steps + 1):
		var t := float(step) / float(steps)
		var smooth_t := t * t * (3.0 - 2.0 * t)
		var sample := exit if step == steps else entry.lerp(exit, smooth_t) + bulge_direction * sin(PI * t) * bulge
		var tilt := lerp_angle(lerp_angle(corner["entry_tilt"], corner["point_tilt"], smooth_t), lerp_angle(corner["point_tilt"], corner["exit_tilt"], smooth_t), smooth_t)
		_append_sample(sample, tilt, step == steps, _blend_forwards(incoming_forward, outgoing_forward, smooth_t))

func _blend_forwards(from_forward: Vector3, to_forward: Vector3, weight: float) -> Vector3:
	var blended := from_forward.lerp(to_forward, weight)
	if blended.length_squared() <= 0.000001:
		return _get_safe_forward(to_forward)
	return blended.normalized()

func _should_bevel_tight_corner(cut_distance: float, turn_angle: float) -> bool:
	if cut_distance <= thickness * 1.25:
		return true
	return turn_angle >= deg_to_rad(150.0) and cut_distance <= thickness * 2.0

func _append_quadratic_samples(from_point: Vector3, control_point: Vector3, to_point: Vector3, from_tilt: float, control_tilt: float, to_tilt: float) -> void:
	var estimated_length := from_point.distance_to(control_point) + control_point.distance_to(to_point)
	var corner_angle := (control_point - from_point).angle_to(to_point - control_point)
	var angle_steps := ceili(corner_angle / deg_to_rad(corner_angle_step))
	var length_steps := ceili(estimated_length / path_sample_spacing)
	var steps := max(1, max(angle_steps, length_steps))
	for step in range(1, steps + 1):
		var t := float(step) / float(steps)
		var inverse := 1.0 - t
		var point := to_point if step == steps else inverse * inverse * from_point + 2.0 * inverse * t * control_point + t * t * to_point
		var tilt := lerp_angle(lerp_angle(from_tilt, control_tilt, t), lerp_angle(control_tilt, to_tilt, t), t)
		_append_sample(point, tilt, step == steps, _sample_quadratic_tangent(from_point, control_point, to_point, t))

func _append_fillet_samples(corner: Dictionary) -> void:
	var entry: Vector3 = corner["entry_point"]
	var point: Vector3 = corner["point"]
	var exit: Vector3 = corner["exit_point"]
	var incoming := point - entry
	var outgoing := exit - point
	if incoming.length_squared() <= 0.000001 or outgoing.length_squared() <= 0.000001:
		_append_sample(exit, corner["exit_tilt"], true, corner["outgoing_forward"])
		return

	var in_direction := incoming.normalized()
	var out_direction := outgoing.normalized()
	var normal := in_direction.cross(out_direction)
	if normal.length_squared() <= 0.000001:
		_append_sample(exit, corner["exit_tilt"], true, corner["outgoing_forward"])
		return
	normal = normal.normalized()

	var turn_angle := in_direction.angle_to(out_direction)
	if turn_angle <= deg_to_rad(0.1):
		_append_sample(exit, corner["exit_tilt"], true, corner["outgoing_forward"])
		return
	var radius: float = incoming.length() / max(0.001, tan(turn_angle / 2.0))
	var center: Vector3 = entry + normal.cross(in_direction).normalized() * radius
	_append_arc_samples(center, normal, entry, exit, corner["entry_tilt"], corner["point_tilt"], corner["exit_tilt"])

func _append_arc_line_samples(corner: Dictionary) -> void:
	var entry: Vector3 = corner["entry_point"]
	var point: Vector3 = corner["point"]
	var exit: Vector3 = corner["exit_point"]
	var point_2d := Vector2(point.x, point.z)
	var incoming := point_2d - Vector2(entry.x, entry.z)
	var outgoing := Vector2(exit.x, exit.z) - point_2d
	if incoming.length_squared() <= 0.000001 or outgoing.length_squared() <= 0.000001:
		_append_corner_rounded_samples(corner)
		return

	var in_direction := incoming.normalized()
	var out_direction := outgoing.normalized()
	var turn_cross := in_direction.cross(out_direction)
	if abs(turn_cross) <= 0.000001:
		_append_sample(exit, corner["exit_tilt"], true, corner["outgoing_forward"])
		return

	var turn_angle := abs(in_direction.angle_to(out_direction))
	if turn_angle <= deg_to_rad(0.1):
		_append_sample(exit, corner["exit_tilt"], true, corner["outgoing_forward"])
		return

	var planar_cut: float = min(incoming.length(), outgoing.length())
	if planar_cut <= MIN_DIMENSION:
		_append_sample(exit, corner["exit_tilt"], true, corner["outgoing_forward"])
		return
	if _should_bevel_tight_corner(planar_cut, turn_angle):
		_append_tight_corner_round_samples(corner)
		return

	var arc_entry := _point_at_planar_corner_distance(point, entry, planar_cut)
	var arc_exit := _point_at_planar_corner_distance(point, exit, planar_cut)
	if arc_entry.distance_squared_to(entry) > 0.000001:
		_append_sample(arc_entry, corner["entry_tilt"], true, corner["incoming_forward"])

	var entry_2d := Vector2(arc_entry.x, arc_entry.z)
	var exit_2d := Vector2(arc_exit.x, arc_exit.z)
	var radius: float = planar_cut / max(0.001, tan(turn_angle / 2.0))
	var center_direction: Vector2 = Vector2(-in_direction.y, in_direction.x) * sign(turn_cross)
	var center_2d: Vector2 = entry_2d + center_direction.normalized() * radius
	var start_vector: Vector2 = entry_2d - center_2d
	var end_vector: Vector2 = exit_2d - center_2d
	var signed_angle := atan2(start_vector.cross(end_vector), start_vector.dot(end_vector))
	var arc_length: float = abs(signed_angle) * radius
	var steps := _get_adaptive_arc_steps(abs(signed_angle), arc_length)
	for step in range(1, steps + 1):
		var t := float(step) / float(steps)
		var rotated: Vector2 = start_vector.rotated(signed_angle * t)
		var sample_2d: Vector2 = center_2d + rotated
		var y := lerp(arc_entry.y, arc_exit.y, t)
		var tilt := lerp_angle(lerp_angle(corner["entry_tilt"], corner["point_tilt"], t), lerp_angle(corner["point_tilt"], corner["exit_tilt"], t), t)
		_append_sample(arc_exit if step == steps else Vector3(sample_2d.x, y, sample_2d.y), tilt, step == steps, _sample_arc_line_tangent(start_vector, signed_angle, arc_entry.y, arc_exit.y, t))

	if arc_exit.distance_squared_to(exit) > 0.000001:
		_append_sample(exit, corner["exit_tilt"], true, corner["outgoing_forward"])

func _append_arc_samples(center: Vector3, normal: Vector3, entry: Vector3, exit: Vector3, entry_tilt: float, point_tilt: float, exit_tilt: float) -> void:
	var start_vector := entry - center
	var end_vector := exit - center
	if start_vector.length_squared() <= 0.000001 or end_vector.length_squared() <= 0.000001:
		_append_sample(exit, exit_tilt, true, _get_safe_forward(exit - entry))
		return

	var signed_angle := atan2(normal.dot(start_vector.cross(end_vector)), start_vector.dot(end_vector))
	var arc_length: float = abs(signed_angle) * start_vector.length()
	var steps := _get_adaptive_arc_steps(abs(signed_angle), arc_length)
	for step in range(1, steps + 1):
		var t := float(step) / float(steps)
		var radial := start_vector.rotated(normal, signed_angle * t)
		var point := exit if step == steps else center + radial
		var tilt := lerp_angle(lerp_angle(entry_tilt, point_tilt, t), lerp_angle(point_tilt, exit_tilt, t), t)
		_append_sample(point, tilt, step == steps, _sample_arc_tangent(normal, radial, signed_angle))

func _get_adaptive_arc_steps(angle: float, arc_length: float) -> int:
	var angle_steps := ceili(angle / deg_to_rad(corner_angle_step))
	var length_steps := ceili(arc_length / path_sample_spacing)
	return max(1, max(angle_steps, length_steps))

func _append_sample(point: Vector3, tilt: float, keep: bool = false, forward: Vector3 = Vector3.ZERO) -> void:
	if not sampled_path_points.is_empty() and sampled_path_points[sampled_path_points.size() - 1].distance_squared_to(point) <= 0.000001:
		if keep:
			sampled_path_keep[sampled_path_keep.size() - 1] = true
		if forward.length_squared() > 0.000001:
			sampled_path_forwards[sampled_path_forwards.size() - 1] = forward.normalized()
		return
	sampled_path_points.append(point)
	sampled_path_tilts.append(tilt)
	sampled_path_forwards.append(forward.normalized() if forward.length_squared() > 0.000001 else Vector3.ZERO)
	sampled_path_keep.append(keep)

func _get_last_sample_point() -> Vector3:
	return sampled_path_points[sampled_path_points.size() - 1]

func _get_last_sample_tilt() -> float:
	return sampled_path_tilts[sampled_path_tilts.size() - 1]

func _remove_closed_duplicate_sample() -> void:
	if not is_curve_closed() or sampled_path_points.size() < 2:
		return
	if sampled_path_points[0].distance_squared_to(sampled_path_points[sampled_path_points.size() - 1]) <= 0.000001:
		sampled_path_points.remove_at(sampled_path_points.size() - 1)
		sampled_path_tilts.remove_at(sampled_path_tilts.size() - 1)
		sampled_path_forwards.remove_at(sampled_path_forwards.size() - 1)
		sampled_path_keep.remove_at(sampled_path_keep.size() - 1)

func _simplify_sampled_path() -> void:
	if not _can_simplify_samples() or sample_simplify_angle <= 0.0 or sampled_path_points.size() < 3:
		return

	var angle_threshold := deg_to_rad(sample_simplify_angle)
	var distance_tolerance := _get_simplify_distance_tolerance(angle_threshold)
	var point_count := sampled_path_points.size()
	var keep_flags: Array[bool] = []
	keep_flags.resize(point_count)
	for index in range(point_count):
		keep_flags[index] = sampled_path_keep[index]

	if is_curve_closed():
		_mark_closed_simplified_samples(keep_flags, angle_threshold, distance_tolerance)
	else:
		keep_flags[0] = true
		keep_flags[point_count - 1] = true
		_mark_open_simplified_samples(keep_flags, angle_threshold, distance_tolerance)

	var simplified_points := PackedVector3Array()
	var simplified_tilts := PackedFloat32Array()
	var simplified_forwards := PackedVector3Array()
	var simplified_keeps: Array = []
	for index in range(point_count):
		if keep_flags[index]:
			simplified_points.append(sampled_path_points[index])
			simplified_tilts.append(sampled_path_tilts[index])
			simplified_forwards.append(sampled_path_forwards[index])
			simplified_keeps.append(sampled_path_keep[index])

	if is_curve_closed() and simplified_points.size() < 3:
		return
	if not is_curve_closed() and simplified_points.size() < 2:
		return
	sampled_path_points = simplified_points
	sampled_path_tilts = simplified_tilts
	sampled_path_forwards = simplified_forwards
	sampled_path_keep = simplified_keeps

func _mark_open_simplified_samples(keep_flags: Array[bool], angle_threshold: float, distance_tolerance: float) -> void:
	var anchors := _get_sorted_keep_indices(keep_flags)
	for index in range(anchors.size() - 1):
		_mark_simplified_span(anchors[index], anchors[index + 1], keep_flags, angle_threshold, distance_tolerance)

func _mark_closed_simplified_samples(keep_flags: Array[bool], angle_threshold: float, distance_tolerance: float) -> void:
	var point_count := sampled_path_points.size()
	var anchors := _get_sorted_keep_indices(keep_flags)
	if anchors.is_empty():
		anchors.append(0)
		keep_flags[0] = true
	for index in range(anchors.size()):
		var from_index: int = anchors[index]
		var to_index: int = anchors[(index + 1) % anchors.size()]
		if index == anchors.size() - 1:
			to_index += point_count
		_mark_simplified_span(from_index, to_index, keep_flags, angle_threshold, distance_tolerance)

func _get_sorted_keep_indices(keep_flags: Array[bool]) -> Array[int]:
	var indices: Array[int] = []
	for index in range(keep_flags.size()):
		if keep_flags[index]:
			indices.append(index)
	return indices

func _mark_simplified_span(from_index: int, to_index: int, keep_flags: Array[bool], angle_threshold: float, distance_tolerance: float) -> void:
	if to_index - from_index <= 1:
		return

	var best_index := -1
	var best_score := 0.0
	for virtual_index in range(from_index + 1, to_index):
		var score := _get_simplify_sample_score(from_index, to_index, virtual_index, angle_threshold, distance_tolerance)
		if score > best_score:
			best_score = score
			best_index = virtual_index

	if best_index == -1 or best_score <= 1.0:
		return

	keep_flags[posmod(best_index, keep_flags.size())] = true
	_mark_simplified_span(from_index, best_index, keep_flags, angle_threshold, distance_tolerance)
	_mark_simplified_span(best_index, to_index, keep_flags, angle_threshold, distance_tolerance)

func _get_simplify_sample_score(from_index: int, to_index: int, sample_index: int, angle_threshold: float, distance_tolerance: float) -> float:
	var from_point := _get_virtual_sample_point(from_index)
	var to_point := _get_virtual_sample_point(to_index)
	var point := _get_virtual_sample_point(sample_index)
	var distance_score: float = _point_segment_distance(point, from_point, to_point) / max(MIN_DIMENSION, distance_tolerance)
	var segment_forward := _get_safe_forward(to_point - from_point)
	var tangent_score: float = _get_source_sample_forward(posmod(sample_index, sampled_path_points.size())).angle_to(segment_forward) / max(0.0001, angle_threshold)
	var tilt_score: float = _get_simplify_tilt_error(from_index, to_index, sample_index) / max(0.0001, angle_threshold)
	return max(distance_score, max(tangent_score, tilt_score))

func _get_virtual_sample_point(index: int) -> Vector3:
	return sampled_path_points[posmod(index, sampled_path_points.size())]

func _get_source_sample_forward(index: int) -> Vector3:
	if index < sampled_path_forwards.size() and sampled_path_forwards[index].length_squared() > 0.000001:
		return sampled_path_forwards[index].normalized()
	var point_count := sampled_path_points.size()
	var previous := sampled_path_points[(index - 1 + point_count) % point_count]
	var next := sampled_path_points[(index + 1) % point_count]
	if not is_curve_closed():
		if index == 0:
			previous = sampled_path_points[0]
		elif index == point_count - 1:
			next = sampled_path_points[point_count - 1]
	return _get_safe_forward(next - previous)

func _get_simplify_tilt_error(from_index: int, to_index: int, sample_index: int) -> float:
	var from_tilt := sampled_path_tilts[posmod(from_index, sampled_path_tilts.size())]
	var to_tilt := sampled_path_tilts[posmod(to_index, sampled_path_tilts.size())]
	var sample_tilt := sampled_path_tilts[posmod(sample_index, sampled_path_tilts.size())]
	var ratio := float(sample_index - from_index) / float(max(1, to_index - from_index))
	return _get_angle_delta(sample_tilt, lerp_angle(from_tilt, to_tilt, ratio))

func _point_segment_distance(point: Vector3, from_point: Vector3, to_point: Vector3) -> float:
	var segment := to_point - from_point
	var length_squared := segment.length_squared()
	if length_squared <= 0.000001:
		return point.distance_to(from_point)
	var ratio := clamp((point - from_point).dot(segment) / length_squared, 0.0, 1.0)
	return point.distance_to(from_point + segment * ratio)

func _get_simplify_distance_tolerance(angle_threshold: float) -> float:
	var total_length := 0.0
	var point_count := sampled_path_points.size()
	var segment_count := point_count if is_curve_closed() else point_count - 1
	for index in range(segment_count):
		total_length += sampled_path_points[index].distance_to(sampled_path_points[(index + 1) % point_count])
	var average_length := total_length / float(max(1, segment_count))
	return max(MIN_DIMENSION, average_length * sin(angle_threshold))

func _can_simplify_samples() -> bool:
	return _uses_sample_simplify()

func _rebuild_sampled_forwards_from_segments() -> void:
	sampled_path_forwards.clear()
	for index in range(sampled_path_points.size()):
		sampled_path_forwards.append(_get_segment_forward_for_sample(index))

func _get_segment_forward_for_sample(index: int) -> Vector3:
	var point_count := sampled_path_points.size()
	if point_count < 2:
		return Vector3.FORWARD

	var from_point: Vector3
	var to_point: Vector3
	if index >= point_count - 1:
		if is_curve_closed():
			from_point = sampled_path_points[index]
			to_point = sampled_path_points[0]
		else:
			from_point = sampled_path_points[index - 1]
			to_point = sampled_path_points[index]
	else:
		from_point = sampled_path_points[index]
		to_point = sampled_path_points[index + 1]

	return _get_safe_forward(to_point - from_point)

func _get_angle_delta(from: float, to: float) -> float:
	return abs(wrapf(to - from, -PI, PI))

func _rebuild_sample_offsets() -> void:
	if sampled_path_points.is_empty():
		return

	sampled_path_offsets.append(0.0)
	var offset := 0.0
	for index in range(1, sampled_path_points.size()):
		offset += sampled_path_points[index - 1].distance_to(sampled_path_points[index])
		sampled_path_offsets.append(offset)
	sampled_path_length = offset
	if is_curve_closed() and sampled_path_points.size() > 1:
		sampled_path_length += sampled_path_points[sampled_path_points.size() - 1].distance_to(sampled_path_points[0])

func _rebuild_sampled_bases() -> void:
	sampled_path_bases.clear()
	if _uses_parallel_transport():
		_rebuild_parallel_transport_bases()
		sampled_basis_dirty = false
		return
	for index in range(sampled_path_points.size()):
		sampled_path_bases.append(_get_sample_basis(index))
	sampled_basis_dirty = false

func _rebuild_parallel_transport_bases() -> void:
	var point_count := sampled_path_points.size()
	if point_count == 0:
		return

	var previous_forward := _get_sample_forward(0, true)
	var side_axis := _get_base_wall_side_axis(previous_forward)
	var up_axis := side_axis.cross(previous_forward).normalized()
	sampled_path_bases.append(_create_tilted_basis(side_axis, up_axis, previous_forward, sampled_path_tilts[0] if not sampled_path_tilts.is_empty() else 0.0))

	for index in range(1, point_count):
		var forward := _get_sample_forward(index, true)
		var rotation_axis := previous_forward.cross(forward)
		if rotation_axis.length_squared() > 0.000001:
			var rotation_angle := previous_forward.angle_to(forward)
			rotation_axis = rotation_axis.normalized()
			side_axis = side_axis.rotated(rotation_axis, rotation_angle)
			up_axis = up_axis.rotated(rotation_axis, rotation_angle)

		side_axis = (side_axis - forward * side_axis.dot(forward))
		if side_axis.length_squared() <= 0.000001:
			side_axis = _get_base_wall_side_axis(forward)
		else:
			side_axis = side_axis.normalized()
		up_axis = side_axis.cross(forward).normalized()
		sampled_path_bases.append(_create_tilted_basis(side_axis, up_axis, forward, sampled_path_tilts[index] if index < sampled_path_tilts.size() else 0.0))
		previous_forward = forward

func _create_tilted_basis(side_axis: Vector3, up_axis: Vector3, forward: Vector3, tilt: float) -> Basis:
	if abs(tilt) > 0.000001:
		side_axis = side_axis.rotated(forward, tilt).normalized()
		up_axis = up_axis.rotated(forward, tilt).normalized()
	return Basis(side_axis, up_axis, forward).orthonormalized()

func _get_sample_basis(index: int) -> Basis:
	var forward := _get_sample_forward(index, path_orientation == PathOrientation.PATH_PERPENDICULAR)
	var side_axis := _get_base_wall_side_axis(_get_sample_forward(index, false))
	var up_axis := Vector3.UP

	if path_orientation == PathOrientation.PATH_PERPENDICULAR:
		up_axis = side_axis.cross(forward)
		if up_axis.length_squared() <= 0.000001:
			up_axis = Vector3.UP
		else:
			up_axis = up_axis.normalized()
		var tilt := sampled_path_tilts[index] if index < sampled_path_tilts.size() else 0.0
		return _create_tilted_basis(side_axis, up_axis, forward, tilt)

	return Basis(side_axis, up_axis, forward).orthonormalized()

func _get_sample_forward(index: int, include_vertical: bool) -> Vector3:
	var point_count := sampled_path_points.size()
	if point_count < 2:
		return Vector3(0, 0, 1)

	if index < sampled_path_forwards.size():
		var stored_forward := sampled_path_forwards[index]
		if not include_vertical:
			stored_forward.y = 0.0
		if stored_forward.length_squared() > 0.000001:
			return stored_forward.normalized()

	var previous: Vector3
	var next: Vector3
	if is_curve_closed():
		previous = sampled_path_points[(index - 1 + point_count) % point_count]
		next = sampled_path_points[(index + 1) % point_count]
	elif index <= 0:
		previous = sampled_path_points[0]
		next = sampled_path_points[1]
	elif index >= point_count - 1:
		previous = sampled_path_points[point_count - 2]
		next = sampled_path_points[point_count - 1]
	else:
		previous = sampled_path_points[index - 1]
		next = sampled_path_points[index + 1]

	var forward := next - previous
	if not include_vertical:
		forward.y = 0.0
	if forward.length_squared() <= 0.000001:
		return Vector3(0, 0, 1)
	return forward.normalized()

func _get_base_wall_side_axis(forward: Vector3) -> Vector3:
	var side_axis := Vector3.UP.cross(forward)
	if side_axis.length_squared() <= 0.000001:
		return -Vector3.RIGHT
	return -side_axis.normalized()

func _sample_path_basis(offset: float) -> Basis:
	_ensure_sampled_bases()
	var point_count := sampled_path_bases.size()
	if point_count == 0:
		return Basis()
	if point_count == 1 or sampled_path_length <= MIN_DIMENSION:
		return sampled_path_bases[0]

	var sample_offset := _get_normalized_path_offset(offset)
	if direction_source == FollowDirectionSource.GENERATED_SEGMENT:
		return _sample_segment_aligned_basis(sample_offset)

	var index := _find_sample_segment_index(sample_offset)
	if index >= point_count - 1:
		if not is_curve_closed():
			return sampled_path_bases[point_count - 1]
		var segment_length := max(MIN_DIMENSION, sampled_path_length - sampled_path_offsets[index])
		return _interpolate_basis(sampled_path_bases[index], sampled_path_bases[0], (sample_offset - sampled_path_offsets[index]) / segment_length)

	var segment_length := max(MIN_DIMENSION, sampled_path_offsets[index + 1] - sampled_path_offsets[index])
	return _interpolate_basis(sampled_path_bases[index], sampled_path_bases[index + 1], (sample_offset - sampled_path_offsets[index]) / segment_length)

func _interpolate_basis(from_basis: Basis, to_basis: Basis, weight: float) -> Basis:
	return Basis(
		from_basis.x.lerp(to_basis.x, weight).normalized(),
		from_basis.y.lerp(to_basis.y, weight).normalized(),
		from_basis.z.lerp(to_basis.z, weight).normalized()
	).orthonormalized()

func _sample_segment_aligned_basis(sample_offset: float) -> Basis:
	var point_count := sampled_path_points.size()
	var index := _find_sample_segment_index(sample_offset)
	var next_index: int
	if index >= point_count - 1:
		if not is_curve_closed():
			return sampled_path_bases[point_count - 1]
		next_index = 0
	else:
		next_index = index + 1

	var forward := sampled_path_points[next_index] - sampled_path_points[index]
	if path_orientation == PathOrientation.FIXED_UP:
		forward.y = 0.0
	if forward.length_squared() <= 0.000001:
		return sampled_path_bases[min(index, point_count - 1)]
	forward = forward.normalized()

	var planar_forward := forward
	planar_forward.y = 0.0
	var side_axis := _get_base_wall_side_axis(planar_forward if planar_forward.length_squared() > 0.000001 else forward)
	if path_orientation == PathOrientation.PATH_PERPENDICULAR:
		var up_axis := side_axis.cross(forward)
		if up_axis.length_squared() <= 0.000001:
			up_axis = Vector3.UP
		else:
			up_axis = up_axis.normalized()
		return _create_tilted_basis(side_axis, up_axis, forward, _sample_path_tilt(sample_offset))

	return Basis(side_axis, Vector3.UP, forward).orthonormalized()

func _get_normalized_path_offset(offset: float) -> float:
	return fposmod(offset, sampled_path_length) if is_curve_closed() else clamp(offset, 0.0, sampled_path_length)

func _find_sample_segment_index(sample_offset: float) -> int:
	var point_count := sampled_path_offsets.size()
	if point_count <= 1:
		return 0

	var low := 0
	var high := point_count - 1
	while low < high:
		var middle := (low + high + 1) / 2
		if sampled_path_offsets[middle] <= sample_offset:
			low = middle
		else:
			high = middle - 1
	if not is_curve_closed():
		return min(low, point_count - 2)
	return low

func _sample_path_point(offset: float) -> Vector3:
	var point_count := sampled_path_points.size()
	if point_count == 0:
		return Vector3.ZERO
	if point_count == 1 or sampled_path_length <= MIN_DIMENSION:
		return sampled_path_points[0]

	var sample_offset := _get_normalized_path_offset(offset)
	if not is_curve_closed() and sample_offset >= sampled_path_length - MIN_DIMENSION:
		return sampled_path_points[point_count - 1]

	var index := _find_sample_segment_index(sample_offset)
	if index >= point_count - 1:
		var start_offset := sampled_path_offsets[point_count - 1]
		var segment_length := max(MIN_DIMENSION, sampled_path_length - start_offset)
		return sampled_path_points[point_count - 1].lerp(sampled_path_points[0], (sample_offset - start_offset) / segment_length)

	var start_offset := sampled_path_offsets[index]
	var end_offset := sampled_path_offsets[index + 1]
	var segment_length := max(MIN_DIMENSION, end_offset - start_offset)
	return sampled_path_points[index].lerp(sampled_path_points[index + 1], (sample_offset - start_offset) / segment_length)

func _sample_path_tilt(offset: float) -> float:
	var point_count := sampled_path_tilts.size()
	if point_count == 0:
		return 0.0
	if point_count == 1 or sampled_path_length <= MIN_DIMENSION:
		return sampled_path_tilts[0]

	var sample_offset := _get_normalized_path_offset(offset)
	if not is_curve_closed() and sample_offset >= sampled_path_length - MIN_DIMENSION:
		return sampled_path_tilts[point_count - 1]

	var index := _find_sample_segment_index(sample_offset)
	if index >= point_count - 1:
		var start_offset := sampled_path_offsets[point_count - 1]
		var segment_length := max(MIN_DIMENSION, sampled_path_length - start_offset)
		return lerp_angle(sampled_path_tilts[point_count - 1], sampled_path_tilts[0], (sample_offset - start_offset) / segment_length)

	var start_offset := sampled_path_offsets[index]
	var end_offset := sampled_path_offsets[index + 1]
	var segment_length := max(MIN_DIMENSION, end_offset - start_offset)
	return lerp_angle(sampled_path_tilts[index], sampled_path_tilts[index + 1], (sample_offset - start_offset) / segment_length)

func _sample_control_tilt_by_baked_offset(offset: float, baked_length: float) -> float:
	var point_count := curve.get_point_count()
	if point_count <= 1:
		return 0.0

	var segment_count := point_count if is_curve_closed() else point_count - 1
	var control_lengths := PackedFloat32Array()
	var total_length := 0.0
	for index in range(segment_count):
		var next_index := (index + 1) % point_count
		var segment_length := curve.get_point_position(index).distance_to(curve.get_point_position(next_index))
		control_lengths.append(segment_length)
		total_length += segment_length
	if total_length <= MIN_DIMENSION:
		return curve.get_point_tilt(0)

	var control_offset: float = (fposmod(offset, baked_length) if is_curve_closed() else clamp(offset, 0.0, baked_length)) / max(MIN_DIMENSION, baked_length) * total_length
	var walked := 0.0
	for index in range(segment_count):
		var segment_length := control_lengths[index]
		if control_offset <= walked + segment_length:
			var next_index := (index + 1) % point_count
			return lerp_angle(curve.get_point_tilt(index), curve.get_point_tilt(next_index), (control_offset - walked) / max(MIN_DIMENSION, segment_length))
		walked += segment_length
	return curve.get_point_tilt(point_count - 1)

func _sample_baked_forward(offset: float, baked_length: float, cubic: bool) -> Vector3:
	if baked_length <= MIN_DIMENSION:
		return Vector3.FORWARD
	var step: float = clamp(path_sample_spacing * 0.5, 0.001, max(0.001, baked_length * 0.25))
	return _sample_baked_forward_with_step(offset, baked_length, cubic, step)

func _sample_baked_forward_with_step(offset: float, baked_length: float, cubic: bool, step: float) -> Vector3:
	var before_offset: float
	var after_offset: float
	if is_curve_closed():
		before_offset = fposmod(offset - step, baked_length)
		after_offset = fposmod(offset + step, baked_length)
	else:
		before_offset = clamp(offset - step, 0.0, baked_length)
		after_offset = clamp(offset + step, 0.0, baked_length)
		if is_equal_approx(before_offset, after_offset):
			before_offset = max(0.0, offset - step)
			after_offset = min(baked_length, offset + step)
	return _get_safe_forward(curve.sample_baked(after_offset, cubic) - curve.sample_baked(before_offset, cubic))

func _sample_follow_curve_forward(offset: float, baked_length: float) -> Vector3:
	if baked_length <= MIN_DIMENSION:
		return Vector3.FORWARD
	var step: float = clamp(baked_length * 0.001, 0.001, min(0.05, max(0.001, baked_length * 0.25)))
	return _sample_baked_forward_with_step(offset, baked_length, true, step)

func _sample_bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var inverse := 1.0 - t
	return inverse * inverse * inverse * p0 + 3.0 * inverse * inverse * t * p1 + 3.0 * inverse * t * t * p2 + t * t * t * p3

func _sample_bezier_tangent(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var inverse := 1.0 - t
	var tangent := 3.0 * inverse * inverse * (p1 - p0) + 6.0 * inverse * t * (p2 - p1) + 3.0 * t * t * (p3 - p2)
	return _get_safe_forward(tangent if tangent.length_squared() > 0.000001 else p3 - p0)

func _sample_quadratic_tangent(from_point: Vector3, control_point: Vector3, to_point: Vector3, t: float) -> Vector3:
	var tangent := 2.0 * (1.0 - t) * (control_point - from_point) + 2.0 * t * (to_point - control_point)
	return _get_safe_forward(tangent)

func _sample_centripetal_catmull_rom_tangent(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var delta := 0.001
	var from_t := max(0.0, t - delta)
	var to_t := min(1.0, t + delta)
	if is_equal_approx(from_t, to_t):
		return _get_safe_forward(p2 - p1)
	return _get_safe_forward(_sample_centripetal_catmull_rom(p0, p1, p2, p3, to_t) - _sample_centripetal_catmull_rom(p0, p1, p2, p3, from_t))

func _sample_arc_tangent(normal: Vector3, radial: Vector3, signed_angle: float) -> Vector3:
	return _get_safe_forward(normal.cross(radial) * sign(signed_angle))

func _sample_arc_line_tangent(start_vector: Vector2, signed_angle: float, entry_y: float, exit_y: float, t: float) -> Vector3:
	var radial := start_vector.rotated(signed_angle * t)
	var planar_tangent := Vector2(-radial.y, radial.x) * signed_angle
	var y_tangent := exit_y - entry_y
	return _get_safe_forward(Vector3(planar_tangent.x, y_tangent, planar_tangent.y))

func _estimate_bezier_length(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> float:
	var length := 0.0
	var previous := p0
	for step in range(1, 17):
		var point := _sample_bezier(p0, p1, p2, p3, float(step) / 16.0)
		length += previous.distance_to(point)
		previous = point
	return length

func _connect_curve_changed() -> void:
	if connected_curve == curve:
		return
	if connected_curve != null and connected_curve.changed.is_connected(_on_curve_changed):
		connected_curve.changed.disconnect(_on_curve_changed)
	connected_curve = curve
	_mark_sampled_path_dirty()
	_track_curve_bake_interval()
	if connected_curve != null and not connected_curve.changed.is_connected(_on_curve_changed):
		connected_curve.changed.connect(_on_curve_changed)

func _disconnect_curve_changed() -> void:
	if connected_curve != null and connected_curve.changed.is_connected(_on_curve_changed):
		connected_curve.changed.disconnect(_on_curve_changed)
	connected_curve = null
	_track_curve_bake_interval()

func _on_curve_changed() -> void:
	_mark_sampled_path_dirty()
	refresh_shape()
	update_gizmos()

func _clear_generated_shapes() -> void:
	var nodes: Array = generated_shapes.duplicate()
	for child in get_children():
		if child is Node3D and String(child.name).begins_with(GENERATED_PREFIX) and not nodes.has(child):
			nodes.append(child)

	for node in nodes:
		if node != null and is_instance_valid(node):
			if node.get_parent() == self:
				remove_child(node)
			node.queue_free()
	generated_shapes.clear()

func _create_solid_wall() -> void:
	_create_path_mesh("%sBody" % GENERATED_PREFIX, _create_wall_profile(thickness, 0.0, height))

func _create_rails() -> void:
	var profiles: Array = []
	for index in range(rail_count):
		var rail_center_height := get_rail_center_height(index)
		var bottom := max(0.0, rail_center_height - rail_thickness / 2.0)
		var top := min(height, rail_center_height + rail_thickness / 2.0)
		profiles.append(_create_wall_profile(thickness, bottom, top))
	_create_path_meshes("%sRails" % GENERATED_PREFIX, profiles)

func _create_posts() -> void:
	if not post_enabled or curve == null:
		return

	for post_offset in _get_post_offsets():
		var post := CSGBox3D.new()
		post.name = "%sPost" % GENERATED_PREFIX
		post.size = Vector3(thickness, height, post_width)
		post.use_collision = collisions_enabled
		post.material = material

		var basis := get_wall_basis(post_offset)
		var position := get_path_point(post_offset)
		position += basis.x * get_side_center_offset(thickness)
		position += basis.y * height / 2.0
		post.transform = Transform3D(basis, position)

		add_child(post)
		generated_shapes.append(post)

func _create_wall_profile(width: float, bottom: float, top: float) -> PackedVector2Array:
	var min_x := -width / 2.0
	var max_x := width / 2.0
	match side:
		Side.LEFT:
			min_x = -width
			max_x = 0.0
		Side.RIGHT:
			min_x = 0.0
			max_x = width

	return PackedVector2Array([
		Vector2(min_x, bottom),
		Vector2(max_x, bottom),
		Vector2(max_x, top),
		Vector2(min_x, top),
	])

func _create_path_mesh(node_name: String, profile: PackedVector2Array) -> CSGMesh3D:
	return _create_path_meshes(node_name, [profile])

func _create_path_meshes(node_name: String, profiles: Array) -> CSGMesh3D:
	if sampled_path_points.size() < 2:
		return null

	var mesh := _create_swept_meshes(profiles)
	if mesh == null:
		return null

	var csg_mesh := CSGMesh3D.new()
	csg_mesh.name = node_name
	csg_mesh.mesh = mesh
	csg_mesh.use_collision = collisions_enabled
	add_child(csg_mesh)
	generated_shapes.append(csg_mesh)
	return csg_mesh

func _create_swept_meshes(profiles: Array) -> ArrayMesh:
	if profiles.is_empty():
		return null

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for profile: PackedVector2Array in profiles:
		_append_swept_profile(vertices, normals, indices, profile)

	if vertices.is_empty():
		return null

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if material is Material:
		mesh.surface_set_material(0, material)
	return mesh

func _append_swept_profile(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, profile: PackedVector2Array) -> void:
	if profile.size() < 3:
		return

	var sections := _build_sweep_sections(profile)
	var section_count := sections.size()
	var profile_count := profile.size()
	var segment_count := section_count if is_curve_closed() else section_count - 1
	for section_index in range(segment_count):
		var next_section_index := (section_index + 1) % section_count
		var section: PackedVector3Array = sections[section_index]
		var next_section: PackedVector3Array = sections[next_section_index]
		for profile_index in range(profile_count):
			var next_profile_index := (profile_index + 1) % profile_count
			_add_mesh_quad(
				vertices,
				normals,
				indices,
				section[profile_index],
				section[next_profile_index],
				next_section[next_profile_index],
				next_section[profile_index]
			)

	if not is_curve_closed():
		_add_mesh_cap(vertices, normals, indices, sections[0], true)
		_add_mesh_cap(vertices, normals, indices, sections[section_count - 1], false)

func _build_sweep_sections(profile: PackedVector2Array) -> Array:
	var sections: Array = []
	for index in range(sampled_path_points.size()):
		var basis: Basis = sampled_path_bases[index]
		var side_scale := _get_sweep_section_side_scale(index)
		var section := PackedVector3Array()
		for profile_point in profile:
			section.append(sampled_path_points[index] + basis.x * profile_point.x * side_scale + basis.y * profile_point.y)
		sections.append(section)
	return sections

func _get_sweep_section_side_scale(index: int) -> float:
	if path_interpolation != PathInterpolation.LINEAR or sampled_path_points.size() < 3:
		return 1.0
	if not is_curve_closed() and (index <= 0 or index >= sampled_path_points.size() - 1):
		return 1.0

	var point_count := sampled_path_points.size()
	var previous := sampled_path_points[(index - 1 + point_count) % point_count]
	var current := sampled_path_points[index]
	var next := sampled_path_points[(index + 1) % point_count]
	var incoming := current - previous
	var outgoing := next - current
	incoming.y = 0.0
	outgoing.y = 0.0
	if incoming.length_squared() <= 0.000001 or outgoing.length_squared() <= 0.000001:
		return 1.0

	var miter_side: Vector3 = sampled_path_bases[index].x
	miter_side.y = 0.0
	if miter_side.length_squared() <= 0.000001:
		return 1.0
	miter_side = miter_side.normalized()
	var incoming_side := _get_base_wall_side_axis(incoming.normalized())
	var outgoing_side := _get_base_wall_side_axis(outgoing.normalized())
	var denominator: float = min(abs(miter_side.dot(incoming_side)), abs(miter_side.dot(outgoing_side)))
	if denominator <= 0.0001:
		return MAX_LINEAR_MITER_SCALE
	return clamp(1.0 / denominator, 1.0, MAX_LINEAR_MITER_SCALE)

func _add_mesh_quad(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := _get_triangle_normal(a, b, c)
	var vertex_index := vertices.size()
	vertices.append_array(PackedVector3Array([a, b, c, d]))
	for index in range(4):
		normals.append(normal)
	indices.append_array(PackedInt32Array([vertex_index, vertex_index + 1, vertex_index + 2, vertex_index, vertex_index + 2, vertex_index + 3]))

func _add_mesh_cap(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, section: PackedVector3Array, reverse: bool) -> void:
	for index in range(1, section.size() - 1):
		if reverse:
			_add_mesh_triangle(vertices, normals, indices, section[0], section[index + 1], section[index])
		else:
			_add_mesh_triangle(vertices, normals, indices, section[0], section[index], section[index + 1])

func _add_mesh_triangle(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := _get_triangle_normal(a, b, c)
	var vertex_index := vertices.size()
	vertices.append_array(PackedVector3Array([a, b, c]))
	for index in range(3):
		normals.append(normal)
	indices.append_array(PackedInt32Array([vertex_index, vertex_index + 1, vertex_index + 2]))

func _get_triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() <= 0.000001:
		return Vector3.UP
	return normal.normalized()

func _get_post_offsets() -> PackedFloat32Array:
	var offsets := PackedFloat32Array()
	var length := get_path_length()
	if length <= MIN_DIMENSION:
		return offsets

	if post_placement == PostPlacement.COUNT:
		return _get_counted_post_offsets(length)

	if post_at_start:
		offsets.append(0.0)

	var offset := post_spacing
	while offset < length - MIN_DIMENSION:
		offsets.append(offset)
		offset += post_spacing

	if post_at_end and not is_curve_closed():
		if offsets.is_empty() or abs(offsets[offsets.size() - 1] - length) > MIN_DIMENSION:
			offsets.append(length)

	return offsets

func _get_counted_post_offsets(length: float) -> PackedFloat32Array:
	var offsets := PackedFloat32Array()
	if post_count <= 1:
		offsets.append(0.0 if is_curve_closed() else length / 2.0)
		return offsets

	var denominator := post_count if is_curve_closed() else post_count - 1
	for index in range(post_count):
		offsets.append(length * float(index) / float(denominator))
	return offsets

func _get_clamped_rail_thickness(value: float) -> float:
	return clamp(value, MIN_DIMENSION, _get_max_rail_thickness())

func _get_max_rail_thickness() -> float:
	return min(1.0, 1.0 / float(max(1, rail_count)))

func _get_clamped_lower_rail_height(value: float) -> float:
	return clamp(value, _get_min_lower_rail_height(), _get_max_lower_rail_height())

func _get_min_lower_rail_height() -> float:
	return rail_thickness / 2.0

func _get_max_lower_rail_height() -> float:
	return max(_get_min_lower_rail_height(), height - rail_thickness / 2.0)

func equals(other: Variant) -> bool:
	return other == self
