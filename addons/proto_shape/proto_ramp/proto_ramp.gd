@tool
extends CSGCombiner3D
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

## Called when ramp/staircase is changed in any noticable way.
signal something_changed

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
var csg_shapes: Array[CSGShape3D] = []

## Used to avoid z-fighting and incorrect snapping between steps.
var epsilon: float = 0.0001

## Default private values
var _calculation := Calculation.STAIRCASE_DIMENSIONS
var _steps: int = 8
var _width: float = 1.0
var _height: float = 1.0
var _depth: float = 1.0
var _fill := true
var _type := Type.RAMP
var _anchor := Anchor.BOTTOM_CENTER
var _anchor_fixed := true

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

## Fill the staircase or leave the space under the staircase empty.
var fill: bool: set = set_fill, get = get_fill

## Act as a ramp or staircase with steps.
var type: Type: set = set_type, get = get_type

## Anchor point of the ramp/staircase.
var anchor: Anchor: set = set_anchor, get = get_anchor

## If true, the anchor point will not move in global space changed when the anchor is changed.
## Instead, the ramp/staircase will move in local space.
var anchor_fixed: bool: set = set_anchor_fixed, get = get_anchor_fixed

func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"name": "type", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Ramp,Staircase"},
		{"name": "width", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"},
		{"name": "height", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"},
		{"name": "depth", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"},
		{"name": "anchor", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Bottom Center,Bottom Left,Bottom Right,Top Center,Top Left,Top Right,Base Center,Base Left,Base Right"},
		{"name": "anchor_fixed", "type": TYPE_BOOL}
	]

	# Staircase exclusive properties
	if type == Type.STAIRCASE:
		list += [
			{"name": "calculation", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Staircase Dimensions,Step Dimensions"},
			{"name": "steps", "type": TYPE_INT, "hint": PROPERTY_HINT_RANGE, "hint_string": "1,100,1,or_greater"},
			{"name": "fill", "type": TYPE_BOOL}
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

	return false

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

func get_fill() -> bool:
	return _fill

func get_steps() -> int:
	return _steps

func get_anchor() -> Anchor:
	return _anchor

func get_anchor_fixed() -> bool:
	return _anchor_fixed

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
	refresh_type()
	type_changed.emit()
	something_changed.emit()

## Resets the steps and regenerates ramp/stairs.
func refresh_type() -> void:
	refresh_steps(0)
	match type:
		Type.STAIRCASE:
			refresh_steps(steps)
		Type.RAMP:
			add_ramp()
			refresh_step(0)

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

func refresh_children() -> void:
	for shape_index in range(csg_shapes.size()):
		refresh_step(shape_index)

func set_width(value: float) -> void:
	_width = value
	refresh_children()
	width_changed.emit()
	something_changed.emit()

func set_height(value: float) -> void:
	_height = value
	refresh_children()
	height_changed.emit()
	something_changed.emit()

func set_depth(value: float) -> void:
	_depth = value
	refresh_children()
	depth_changed.emit()
	something_changed.emit()

func set_fill(value: bool) -> void:
	_fill = value
	refresh_children()
	fill_changed.emit()
	something_changed.emit()

## Translates the ramp/staircase to a new anchor point in local space.
## Then recalculates the stairs/ramp with the new offset.
func set_anchor(value: Anchor) -> void:
	# Transform node to new anchor
	translate_anchor(anchor, value)
	_anchor = value
	refresh_children()
	anchor_changed.emit()
	something_changed.emit()

## Translates the ramp/staircase to a new anchor point in local space if anchor is not fixed.
func translate_anchor(from_anchor: Anchor, to_anchor: Anchor) -> void:
	if not anchor_fixed:
		translate_object_local(get_anchor_offset(from_anchor) - get_anchor_offset(to_anchor))

func set_anchor_fixed(value: bool) -> void:
	_anchor_fixed = value

func set_steps(value: int) -> void:
	_steps = value
	refresh_steps(value)
	step_count_changed.emit()
	something_changed.emit()

## Deletes all children and generates new steps/ramp.
func refresh_steps(new_steps: int) -> void:
	for shape in csg_shapes:
		shape.free()
	csg_shapes.clear()

	match type:
		Type.STAIRCASE:
			for i in range(new_steps):
				var box := CSGBox3D.new()
				box.size = Vector3()
				box.position = Vector3()
				add_child(box)
				csg_shapes.append(box)
		Type.RAMP:
			if new_steps > 0:
				add_ramp()

	refresh_children()

## Adds a new ramp based on current dimensions (without any anchor offset).
func add_ramp() -> void:
	# Create a single CSGPolygon3D
	var polygon := CSGPolygon3D.new()
	var array := PackedVector2Array()
	array.append(Vector2(0, 0))
	array.append(Vector2(depth, 0))
	array.append(Vector2(depth, height))
	polygon.polygon = array
	polygon.rotate(Vector3.UP, -PI / 2.0)
	polygon.translate(Vector3(0, 0, width / 2.0))
	polygon.depth = width
	add_child(polygon)
	csg_shapes.append(polygon)

## Refreshes a single step based on dimensions and anchor offset.
func refresh_step(i: int) -> void:
	var node: Node3D = csg_shapes[i]
	node.position = Vector3()
	var step_height: float = get_true_step_height()
	var step_width: float = width
	var step_depth: float = get_true_step_depth()
	var offset: Vector3 = get_anchor_offset(anchor)

	# Resetting anchor offset to 0,0,0 to avoid problems during step calculations
	translate_anchor(anchor, Anchor.BOTTOM_CENTER)

	match type:
		# Filled with CSGBox3Ds
		Type.STAIRCASE:
			if fill:
				node.size.y = (i + 1) * step_height
				node.position.y = (i + 1) * step_height / 2.0
			else:
				node.size.y = step_height
				node.position.y = i * step_height + step_height / 2.0

			node.position.z = step_depth * i + step_depth / 2.0
			node.size.x = step_width
			node.size.z = step_depth - epsilon # Avoid z-fighting and snapping
		# With only one CSGPolygon3D
		Type.RAMP:
			if node is CSGPolygon3D:
				node.polygon[0] = Vector2(0, 0)
				node.polygon[1] = Vector2(step_depth, 0)
				node.polygon[2] = Vector2(step_depth, step_height)
				node.depth = step_width
				node.position.x = -step_width / 2.0

	# Apply anchor offset
	node.position += offset

	# Restore anchor offset
	translate_anchor(Anchor.BOTTOM_CENTER, anchor)

func _enter_tree() -> void:
	# is_entered_tree is used to avoid setting properties traditionally on initialization
	set_steps(steps)
	is_entered_tree = true

func _exit_tree() -> void:
	# Remove all children
	for child in csg_shapes:
		child.queue_free()
	csg_shapes.clear()
