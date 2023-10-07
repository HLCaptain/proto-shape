@tool
extends CSGCombiner3D

signal anchor_changed

enum Calculation {
	STAIRCASE_DIMENSIONS,
	STEP_DIMENSIONS,
}

enum Anchor {
	BOTTOM_CENTER,
	BOTTOM_LEFT,
	BOTTOM_RIGHT,
	TOP_CENTER,
	TOP_LEFT,
	TOP_RIGHT,
	BASE_CENTER,
	BASE_LEFT,
	BASE_RIGHT,
}

enum Type {
	RAMP,
	STAIRCASE,
}

var is_entered_tree = false

var epsilon = 0.0001
var _calculation: Calculation = Calculation.STAIRCASE_DIMENSIONS
var _steps : int = 8
var _width = 1.0
var _height = 1.0
var _depth = 1.0
var _fill = true
var _type = Type.RAMP
var _anchor = Anchor.BOTTOM_CENTER
var _anchor_fixed = true

@export_category("Proto Ramp")
var calculation: Calculation: set = set_calculation, get = get_calculation
var steps: int: set = set_steps, get = get_steps
var width: float: set = set_width, get = get_width
var height: float: set = set_height, get = get_height
var depth: float: set = set_depth, get = get_depth
var fill: bool: set = set_fill, get = get_fill
var type: Type: set = set_type, get = get_type
var anchor: Anchor: set = set_anchor, get = get_anchor
var anchor_fixed: bool: set = set_anchor_fixed, get = get_anchor_fixed

func _get_property_list():
	var list = []
	list.append({"name": "type", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Ramp,Staircase"})
	list.append({"name": "width", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"})
	list.append({"name": "height", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"})
	list.append({"name": "depth", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"})
	list.append({"name": "anchor", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Bottom Center,Bottom Left,Bottom Right,Top Center,Top Left,Top Right,Base Center,Base Left,Base Right"})
	list.append({"name": "anchor_fixed", "type": TYPE_BOOL})

	# Staircase exclusive properties
	if type == Type.STAIRCASE:
		list.append({"name": "calculation", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Staircase Dimensions,Step Dimensions"})
		list.append({"name": "steps", "type": TYPE_INT, "hint": PROPERTY_HINT_RANGE, "hint_string": "1,100,1,or_greater"})
		list.append({"name": "fill", "type": TYPE_BOOL})

	return list

func _set(property, value):
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

func get_type():
	return _type

func get_calculation():
	return _calculation

func get_width():
	return _width

func get_height():
	return _height

func get_depth():
	return _depth

func get_fill():
	return _fill

func get_steps():
	return _steps

func get_anchor():
	return _anchor

func get_anchor_fixed():
	return _anchor_fixed

func get_true_step_depth():
	var step_calculation = calculation
	var step_depth: float
	if type == Type.RAMP:
		step_calculation = Calculation.STEP_DIMENSIONS
	match step_calculation:
		Calculation.STAIRCASE_DIMENSIONS:
			step_depth = depth / steps
		Calculation.STEP_DIMENSIONS:
			step_depth = depth
	return step_depth

func get_true_depth():
	return get_true_step_depth() * steps

func get_true_step_height():
	var step_calculation = calculation
	var step_height: float
	if type == Type.RAMP:
		step_calculation = Calculation.STEP_DIMENSIONS
	match step_calculation:
		Calculation.STAIRCASE_DIMENSIONS:
			step_height = height / steps
		Calculation.STEP_DIMENSIONS:
			step_height = height
	return step_height

func get_true_height():
	return get_true_step_height() * steps

func get_anchor_offset(anchor):
	var offset = Vector3()
	var depth = get_true_depth()
	var height = get_true_height()
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

func set_type(value):
	_type = value
	if is_entered_tree:
		notify_property_list_changed()
		# Staircase: dimensions are reset from forced STAIRCASE_DIMENSIONS calculation
		# Ramp: dimensions are forced to STAIRCASE_DIMENSIONS calculation
		match type:
			Type.STAIRCASE:
				if calculation == Calculation.STEP_DIMENSIONS:
					_height /= steps
					_depth = (_depth + epsilon) / steps
			Type.RAMP:
				if calculation == Calculation.STEP_DIMENSIONS:
					_height *= steps
					_depth = (_depth + epsilon) * steps

		refresh_type()

func refresh_type():
	refresh_steps(0)
	match type:
		Type.STAIRCASE:
			refresh_steps(steps)
		Type.RAMP:
			add_ramp()

func set_calculation(value):
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

func set_width(value):
	_width = value
	for child in get_children():
		refresh_step(child.get_index())

func set_height(value):
	_height = value
	for child in get_children():
		refresh_step(child.get_index())

func set_depth(value):
	_depth = value
	for child in get_children():
		refresh_step(child.get_index())

func set_fill(value):
	_fill = value
	for child in get_children():
		refresh_step(child.get_index())

func set_anchor(value):
	# Transform node to new anchor
	translate_anchor(anchor, value)
	_anchor = value
	for child in get_children():
		refresh_step(child.get_index())
	anchor_changed.emit()

func translate_anchor(from_anchor, to_anchor):
	if !anchor_fixed:
		translate_object_local(get_anchor_offset(from_anchor) - get_anchor_offset(to_anchor))

func set_anchor_fixed(value):
	_anchor_fixed = value

func set_steps(value):
	_steps = value
	refresh_steps(value)

func refresh_steps(new_steps):
	var current_steps = get_child_count()
	for child in get_children():
		child.free()

	match type:
		Type.STAIRCASE:
			for i in range(new_steps):
				var box = CSGBox3D.new()
				box.size = Vector3()
				box.position = Vector3()
				add_child(box)
		Type.RAMP:
			add_ramp()

	for child in get_children():
		refresh_step(child.get_index())

func add_ramp():
	# Create a single CSGPolygon3D
	var polygon = CSGPolygon3D.new()
	var array = PackedVector2Array()
	array.append(Vector2(0, 0))
	array.append(Vector2(depth, 0))
	array.append(Vector2(depth, height))
	polygon.polygon = array
	polygon.rotate(Vector3.UP, -PI / 2.0)
	polygon.translate(Vector3(0, 0, width / 2.0))
	polygon.depth = width
	add_child(polygon)

func refresh_step(i: int):
	var node: Node3D = get_child(i)
	node.position = Vector3()
	var step_height = get_true_step_height()
	var step_width = width
	var step_depth = get_true_step_depth()
	var offset = get_anchor_offset(anchor)

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
	translate_anchor(Anchor.BOTTOM_CENTER, anchor)

func _enter_tree():
	# is_entered_tree is used to avoid setting properties traditionally on initialization
	is_entered_tree = true

func _init():
	set_steps(steps)

func _exit_tree():
	# Remove all children
	for child in get_children():
		child.queue_free()
