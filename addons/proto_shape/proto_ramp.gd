@tool
extends CSGCombiner3D

enum Calculation {
	STAIRCASE_DIMENSIONS,
	STEP_DIMENSIONS,
}

enum Type {
	RAMP,
	STAIRCASE,
}

var epsilon = 0.0001
var _calculation: Calculation = Calculation.STAIRCASE_DIMENSIONS
var _steps : int = 8
var _width = 1.0
var _height = 1.0
var _depth = 1.0
var _fill = true
var _type = Type.RAMP

@export_category("Proto Stairs")
var calculation : Calculation : set = set_calculation, get = get_calculation
var steps : int : set = set_steps, get = get_steps
var width : float : set = set_width, get = get_width
var height : float : set = set_height, get = get_height
var depth : float : set = set_depth, get = get_depth
var fill : bool : set = set_fill, get = get_fill
var type : Type : set = set_type, get = get_type

# @export var calculation : Calculation : set = set_calculation, get = get_calculation
# @export_range(1, 100, 1, "or_greater") var steps : int : set = set_steps, get = get_steps
# @export_range(0.001, 100, 0.01, "or_greater") var width : float : set = set_width, get = get_width
# @export_range(0.001, 100, 0.01, "or_greater") var height : float : set = set_height, get = get_height
# @export_range(0.001, 100, 0.01, "or_greater") var depth : float : set = set_depth, get = get_depth
# @export var fill : bool : set = set_fill, get = get_fill

func _get_property_list():
	var list = []
	list.append({"name": "type", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Ramp,Staircase"})
	list.append({"name": "width", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"})
	list.append({"name": "height", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"})
	list.append({"name": "depth", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"})

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
		"calculation":
			set_calculation(value)
		"steps":
			set_steps(value)
		"width":
			set_width(value)
		"height":
			set_height(value)
		"depth":
			set_depth(value)
		"fill":
			set_fill(value)

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

func set_type(value):
	_type = value
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

func set_calculation(value):
	_calculation = value
	# Calculate current step or staircase dimensions
	# Only affecting dimensions when in STAIRCASE mode
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

func set_steps(value):
	_steps = value
	refresh_steps(value)

func refresh_steps(new_steps):
	var current_steps = get_child_count()
	if current_steps > new_steps:
		# Remove children
		for i in range(current_steps - new_steps):
			get_child(get_child_count() - 1).free()
	else:
		# Create new stairs
		for i in range(current_steps, new_steps):
			var box = CSGBox3D.new()
			box.size = Vector3()
			box.position = Vector3()
			add_child(box)

	if calculation == Calculation.STAIRCASE_DIMENSIONS:
		for child in get_children():
			refresh_step(child.get_index())
	else:
		if current_steps < new_steps:
			for i in range(current_steps, new_steps):
				refresh_step(i)

func refresh_step(i: int):
	var node: Node3D = get_child(i)
	var step_height: float
	var step_width = width
	var step_depth: float
	var step_calculation = calculation

	if type == Type.RAMP:
		step_calculation = Calculation.STEP_DIMENSIONS

	match step_calculation:
		Calculation.STAIRCASE_DIMENSIONS:
			step_height = height / steps
			step_depth = depth / steps
		Calculation.STEP_DIMENSIONS:
			step_height = height
			step_depth = depth

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

func _ready():
	set_steps(steps)

func _enter_tree():
	set_steps(steps)

func _init():
	set_steps(steps)

func _exit_tree():
	# Remove all children
	for child in get_children():
		child.queue_free()
