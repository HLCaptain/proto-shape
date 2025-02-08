@tool
extends Node3D
## Dynamic ramp/staircase shape
##
## This node can generate ramps and staircases with a variety of parameters.

## Called when the anchor is changed. Used by the `proto_gizmo.dg` script to update gizmo handler positions.
signal anchor_changed

## Called when the width is changed.
signal width_changed

## Called when the height is changed.
signal height_changed

## Called when the depth is changed.
signal depth_changed

## Called when step count is changed.
signal step_count_changed

## Called when type is changed.
signal type_changed

## Called when fill is changed.
signal fill_changed

## Calculation mode for the staircase.
enum Calculation {
	STAIRCASE_DIMENSIONS, 	## Width, depth and height are the same size as the whole staircase.
	STEP_DIMENSIONS, 		## Width, depth and height are the same size as a single step.
}

## Anchor point for the ramp. Used to position the ramp in the world.
enum Anchor {
	BOTTOM_CENTER,	## Default anchor point. The anchor is at the bottom of the ramp. The ramp is positioned in the middle.
	BOTTOM_LEFT,	## The anchor is at the bottom left of the ramp. The ramp is shifted right.
	BOTTOM_RIGHT,	## The anchor is at the bottom right of the ramp. The ramp is shifted left.
	TOP_CENTER,		## The anchor is at the top of the ramp. The ramp is positioned in the middle.
	TOP_LEFT,		## The anchor is at the top left of the ramp. The ramp is shifted right.
	TOP_RIGHT,		## The anchor is at the top right of the ramp. The ramp is shifted left.
	BASE_CENTER,	## The anchor is at the base of the ramp. The ramp is positioned in the middle.
	BASE_LEFT,		## The anchor is at the base left of the ramp. The ramp is shifted right.
	BASE_RIGHT,		## The anchor is at the base right of the ramp. The ramp is shifted left.
}

# TODO: RAMP VS STAIRCASE WRONG WIDTH
## Act as a ramp without stairs or a staircase with stairs.
enum Type {
	RAMP,		## Simple CSGPolygon3D shape.
	STAIRCASE,  ## Staircase with stairs combined of CSGBox3D shapes.
}

## Used to avoid setting properties traditionally on initialization to avoid bugs.
var is_entered_tree := false

## Storing CSG shapes for easy access without interfering with children.
var shape_polygon: CSGPolygon3D = null

## Used to avoid z-fighting and incorrect snapping between steps.
var epsilon: float = 0.0001

## Default public values
const _default_calculation := Calculation.STAIRCASE_DIMENSIONS
const _default_steps: int = 8
const _default_width: float = 1.0
const _default_height: float = 1.0
const _default_depth: float = 1.0
const _default_fill: float = 1.0
const _default_type := Type.RAMP
const _default_anchor := Anchor.BOTTOM_CENTER
const _default_anchor_fixed := true
const _default_collisions_enabled := true

## Default private values
var _calculation := _default_calculation
var _steps := _default_steps
var _width := _default_width
var _height := _default_height
var _depth := _default_depth
var _fill := _default_fill
var _type := _default_type
var _anchor := _default_anchor
var _anchor_fixed := _default_anchor_fixed
var _collisions_enabled := _default_collisions_enabled

@export_category("Proto Ramp")
## Calculation method of width, depth and height.
var calculation: Calculation: set = set_calculation, get = get_calculation

## Number of steps in the staircase.
var steps: int: set = set_steps, get = get_steps

## Width of the ramp/staircase.
var width: float: set = set_width, get = get_width

## Height of the ramp/staircase.
var height: float: set = set_height, get = get_height

## Depth of the ramp/staircase.
var depth: float: set = set_depth, get = get_depth

## Percentage of non-empty space under the ramp/staircase.
var fill: float: set = set_fill, get = get_fill

## Act as a ramp or staircase with steps.
var type: Type: set = set_type, get = get_type

## Anchor point of the ramp/staircase.
var anchor: Anchor: set = set_anchor, get = get_anchor

## Collisions enabled for the ramp/staircase.
var collisions_enabled: bool: set = set_collisions_enabled, get = get_collisions_enabled

## If true, the anchor point will not move in global space changed when the anchor is changed.
## Instead, the ramp/staircase will move in local space.
var anchor_fixed: bool: set = set_anchor_fixed, get = get_anchor_fixed

var material: Variant: set = set_material, get = get_material

func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"name": "type", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Ramp,Staircase"},
		{"name": "collisions_enabled", "type": TYPE_BOOL},
		{"name": "width", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"},
		{"name": "height", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"},
		{"name": "depth", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"},
		{"name": "anchor", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Bottom Center,Bottom Left,Bottom Right,Top Center,Top Left,Top Right,Base Center,Base Left,Base Right"},
		{"name": "anchor_fixed", "type": TYPE_BOOL},
		{"name": "fill", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.000,1.000,0.001"},
		{"name": "material","class_name": &"BaseMaterial3D,ShaderMaterial", "type": 24, "hint": 17, "hint_string": "BaseMaterial3D,ShaderMaterial", "usage": 6 }
		]

	# Staircase exclusive properties
	if type == Type.STAIRCASE:
		list += [
			{"name": "calculation", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Staircase Dimensions,Step Dimensions"},
			{"name": "steps", "type": TYPE_INT, "hint": PROPERTY_HINT_RANGE, "hint_string": "1,100,1,or_greater"},
			]

	return list

func _set(property: StringName, value: Variant) -> bool:
	match property:
		"type":
			set_type(value)
			return true
		"calculation":
			set_calculation(value)
			return true
		"steps":
			set_steps(value)
			return true
		"width":
			set_width(value)
			return true
		"height":
			set_height(value)
			return true
		"depth":
			set_depth(value)
			return true
		"fill":
			set_fill(value)
			return true
		"anchor":
			set_anchor(value)
			return true
		"anchor_fixed":
			set_anchor_fixed(value)
			return true
		"material":
			set_material(value)
			return true
		"collisions_enabled":
			set_collisions_enabled(value)
			return true

	return false

func _property_can_revert(property: StringName) -> bool:
	if property in ["type", "calculation", "steps", "width", "height", "depth", "fill", "anchor", "anchor_fixed", "material", "collisions_enabled"]:
		return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	match property:
		"type":
			return _default_type
		"calculation":
			return _default_calculation
		"steps":
			return _default_steps
		"width":
			return _default_width
		"height":
			return _default_height
		"depth":
			return _default_depth
		"fill":
			return _default_fill
		"anchor":
			return _default_anchor
		"anchor_fixed":
			return _default_anchor_fixed
		"material":
			return null
		"collisions_enabled":
			return _default_collisions_enabled
	return null

func get_type() -> Type:
	return _type

func get_calculation() -> Calculation:
	return _calculation

func get_width() -> float:
	return _width

func get_height() -> float:
	return _height

func get_depth() -> float:
	return _depth

func get_fill() -> float:
	return _fill

func get_steps() -> int:
	return _steps

func get_anchor() -> Anchor:
	return _anchor

func get_collisions_enabled() -> bool:
	return _collisions_enabled

func get_anchor_fixed() -> bool:
	return _anchor_fixed

func get_material() -> Variant:
	return material

## Get the step depth of the staircase.
func get_true_step_depth() -> float:
	if type == Type.RAMP or calculation == Calculation.STEP_DIMENSIONS:
		return depth
	else:
		return depth / steps

## Get the whole depth of the ramp/staircase.
func get_true_depth() -> float:
	if type == Type.STAIRCASE:
		return get_true_step_depth() * steps
	else:
		return get_true_step_depth()

## Get the step height of the staircase.
func get_true_step_height() -> float:
	if type == Type.RAMP or calculation == Calculation.STEP_DIMENSIONS:
		return height
	else:
		return height / steps

## Get the whole height of the ramp/staircase.
func get_true_height() -> float:
	if type == Type.STAIRCASE:
		return get_true_step_height() * steps
	else:
		return get_true_step_height()

## Get the anchor offset for a specific anchor according to the dimensions of the ramp/staircase.
func get_anchor_offset(anchor: Anchor) -> Vector3:
	var offset := Vector3()
	var depth: float = get_true_depth()
	var height: float = get_true_height()
	match anchor:
		Anchor.BOTTOM_CENTER:
			offset = Vector3(0, 0, 0)
		Anchor.BOTTOM_LEFT:
			offset = Vector3(-width / 2.0, 0, 0)
		Anchor.BOTTOM_RIGHT:
			offset = Vector3(width / 2.0, 0, 0)
		Anchor.TOP_CENTER:
			offset = Vector3(0, -height, -depth)
		Anchor.TOP_LEFT:
			offset = Vector3(-width / 2.0, -height, -depth)
		Anchor.TOP_RIGHT:
			offset = Vector3(width / 2.0, -height, -depth)
		Anchor.BASE_CENTER:
			offset = Vector3(0, 0, -depth)
		Anchor.BASE_LEFT:
			offset = Vector3(-width / 2.0, 0, -depth)
		Anchor.BASE_RIGHT:
			offset = Vector3(width / 2.0, 0, -depth)
	return offset

func set_type(value: Type) -> void:
	_type = value
	notify_property_list_changed()
	if is_entered_tree:
		# Staircase: dimensions are reset from forced STAIRCASE_DIMENSIONS calculation
		# Ramp: dimensions are forced to STAIRCASE_DIMENSIONS calculation
		if calculation == Calculation.STEP_DIMENSIONS:
			match type:
				Type.STAIRCASE:
					_height /= steps
					_depth = (_depth + epsilon) / steps
				Type.RAMP:
					_height *= steps
					_depth = (_depth + epsilon) * steps
	refresh_shape()
	type_changed.emit()
	update_gizmos()

## Sets the calculation method and recalculates the dimensions of the ramp/staircase.
func set_calculation(value: Calculation) -> void:
	_calculation = value
	# Calculate current step or staircase dimensions
	# Only affecting dimensions when in STAIRCASE mode
	if is_entered_tree:
		match calculation:
			Calculation.STAIRCASE_DIMENSIONS:
				if type == Type.STAIRCASE:
					_height *= steps
					_depth = (_depth + epsilon) * steps
			Calculation.STEP_DIMENSIONS:
				if type == Type.STAIRCASE:
					_height /= steps
					_depth = (_depth + epsilon) / steps

func set_width(value: float) -> void:
	_width = value
	refresh_shape()
	width_changed.emit()
	update_gizmos()

func set_height(value: float) -> void:
	_height = value
	refresh_shape()
	height_changed.emit()
	update_gizmos()

func set_depth(value: float) -> void:
	_depth = value
	refresh_shape()
	depth_changed.emit()
	update_gizmos()

func set_fill(value: float) -> void:
	_fill = max(0.0, min(1.0, value))
	refresh_shape()
	fill_changed.emit()
	update_gizmos()

## Translates the ramp/staircase to a new anchor point in local space.
## Then recalculates the stairs/ramp with the new offset.
func set_anchor(value: Anchor) -> void:
	# Transform node to new anchor
	translate_anchor(anchor, value)
	_anchor = value
	refresh_shape()
	anchor_changed.emit()
	update_gizmos()

func set_collisions_enabled(value: bool) -> void:
	_collisions_enabled = value
	notify_property_list_changed()
	refresh_shape()

## Translates the ramp/staircase to a new anchor point in local space if anchor is not fixed.
func translate_anchor(from_anchor: Anchor, to_anchor: Anchor) -> void:
	if not anchor_fixed:
		translate_object_local(get_anchor_offset(from_anchor) - get_anchor_offset(to_anchor))

func set_anchor_fixed(value: bool) -> void:
	_anchor_fixed = value

func set_material(value: Variant) -> void:
	material = value
	refresh_shape()

func set_steps(value: int) -> void:
	_steps = value
	refresh_shape()
	step_count_changed.emit()
	update_gizmos()

## Deletes all children and generates new steps/ramp.
func refresh_shape() -> void:
	var offset := get_anchor_offset(anchor)
	var polygon_offset := Vector3(offset.z, offset.y, -offset.x) + Vector3(0, 0, width / 2.0)

	# Resetting anchor offset to 0,0,0 to avoid problems during step calculations
	translate_anchor(anchor, Anchor.BOTTOM_CENTER)

	if shape_polygon != null:
		remove_child(shape_polygon)
		shape_polygon.queue_free()

	shape_polygon = CSGPolygon3D.new()
	shape_polygon.use_collision = false

	match type:
		Type.STAIRCASE:
			shape_polygon.polygon = create_staircase_array()
		Type.RAMP:
			shape_polygon.polygon = create_ramp_array()

	shape_polygon.rotate(Vector3.UP, -PI / 2.0)
	shape_polygon.translate(polygon_offset)
	shape_polygon.depth = width

	shape_polygon.use_collision = collisions_enabled
	if collisions_enabled and material == null:
		var shape_material := StandardMaterial3D.new()
		shape_material.albedo_color = Color.AQUA
		shape_polygon.material = shape_material
	else:
		shape_polygon.material = material

	add_child(shape_polygon)

	# Restore anchor offset
	translate_anchor(Anchor.BOTTOM_CENTER, anchor)

## Adds a new ramp based on current dimensions (without any anchor offset).
func create_ramp_array() -> PackedVector2Array:
	# Create a single CSGPolygon3D
	var array := PackedVector2Array()
	if fill == 1:
		array.append(Vector2(0, 0))
		array.append(Vector2(get_true_depth(), 0))
		array.append(Vector2(get_true_depth(), get_true_height()))

	if fill == 0:
		array.append(Vector2(0, 0))
		array.append(Vector2(get_true_depth() * 0.001, 0))
		array.append(Vector2(get_true_depth(), get_true_height() * 0.999))
		array.append(Vector2(get_true_depth(), get_true_height()))

	if fill < 1.0 and fill > 0.0:
		array.append(Vector2(0, 0))
		array.append(Vector2(get_true_depth() * fill, 0))
		array.append(Vector2(get_true_depth(), get_true_height() * (1 - fill)))
		array.append(Vector2(get_true_depth(), get_true_height()))

	return array

func create_staircase_array() -> PackedVector2Array:
	# Create a staircase with CSGBox3Ds
	var array := PackedVector2Array()

	if fill == 1:
		# Base:
		# 4
		# |
		# |		   1
		# |        |
		# 3--------2
		array.append(Vector2(0, get_true_step_height())) # 1
		array.append(Vector2(0, 0)) # 2
		array.append(Vector2(get_true_depth(), 0)) # 3
		array.append(Vector2(get_true_depth(), get_true_height())) # 4

	if fill == 0:
		# Base:
		# 4
		#   \
		#  	  \	   1
		#       \  |
		#          2
		array.append(Vector2(0, get_true_step_height())) # 1
		array.append(Vector2(0, 0)) # 2
		# No #3 present
		array.append(Vector2(get_true_depth(), get_true_height())) # 4

	if fill < 1.0 and fill > 0.0:
		# Base:
		# 4
		# |
		# 3b	   1
		#   \      |
		#     3a---2
		array.append(Vector2(0, get_true_step_height())) # 1
		array.append(Vector2(0, 0)) # 2
		array.append(Vector2(get_true_depth() * fill, 0)) # 3a
		array.append(Vector2(get_true_depth(), get_true_height() * (1 - fill))) # 3b
		array.append(Vector2(get_true_depth(), get_true_height())) # 4

	# Steps:
	# 4---5
	# |   |
	# |	  6---7
	# |       |
	# |       8---1
	# |           |
	# 3-----------2
	for i in range(steps - 1):
		array.append(Vector2(get_true_depth() - get_true_step_depth() * (i + 1), get_true_height() - get_true_step_height() * i))
		array.append(Vector2(get_true_depth() - get_true_step_depth() * (i + 1), get_true_height() - get_true_step_height() * (i + 1)))

	return array

## Using dynamic type for gizmos to avoid packaging errors.
## See proto_ramp_gizmos.gd for more information.
var gizmos = null

func _enter_tree() -> void:
	# is_entered_tree is used to avoid setting properties traditionally on initialization
	refresh_shape()
	if material:
		set_material(material)
	if Engine.is_editor_hint():
		var ProtoRampGizmos = load("res://addons/proto_shape/proto_ramp/proto_ramp_gizmos.gd")
		gizmos = ProtoRampGizmos.new()
		gizmos.attach_ramp(self)

	is_entered_tree = true

func _exit_tree() -> void:
	# Remove all children
	remove_child(shape_polygon)
	shape_polygon.queue_free()
	if Engine.is_editor_hint():
		gizmos.remove_ramp()
