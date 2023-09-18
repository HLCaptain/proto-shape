@tool
extends CSGCombiner3D

enum Calculation {
	STAIRCASE_DIMENSIONS,
	STEP_DIMENSIONS,
}

var epsilon = 0.0001
var _calculation: Calculation = Calculation.STEP_DIMENSIONS
var _steps : int = 8
var _width = 8.0
var _height = 1.0
var _depth = 1.0
var _fill = true

@export_category("Proto Stairs")
@export var calculation : Calculation : set = set_calculation, get = get_calculation
@export_range(1, 100, 1, "or_greater") var steps : int : set = set_steps, get = get_steps
@export_range(0.0, 100.0) var width : float : set = set_width, get = get_width
@export_range(0.0, 100.0) var height : float : set = set_height, get = get_height
@export_range(0.1, 100.0) var depth : float : set = set_depth, get = get_depth
@export var fill : bool : set = set_fill, get = get_fill

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

func set_calculation(value):
	_calculation = value
	# Calculate current step or staircase dimensions
	match calculation:
		Calculation.STAIRCASE_DIMENSIONS:
			_height *= steps
			_depth = (_depth + epsilon) * steps
		Calculation.STEP_DIMENSIONS:
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

	var current_steps = get_child_count()
	if current_steps > steps:
		# Remove children
		for i in range(current_steps - steps):
			get_child(get_child_count() - 1).free()
	else:
		# Create new stairs
		for i in range(current_steps, steps):
			var box = CSGBox3D.new()
			box.size = Vector3()
			box.position = Vector3()
			add_child(box)

	if calculation == Calculation.STAIRCASE_DIMENSIONS:
		for child in get_children():
			refresh_step(child.get_index())
	else:
		if current_steps < steps:
			for i in range(current_steps, steps):
				refresh_step(i)

func refresh_step(i: int):
	var box: CSGBox3D = get_child(i)
	var step_height: float
	var step_width = width
	var step_depth: float

	match calculation:
		Calculation.STAIRCASE_DIMENSIONS:
			step_height = height / steps
			step_depth = depth / steps
		Calculation.STEP_DIMENSIONS:
			step_height = height
			step_depth = depth

	if fill:
		box.size.y = (i + 1) * step_height
		box.position.y = (i + 1) * step_height / 2.0
	else:
		box.size.y = step_height
		box.position.y = i * step_height + step_height / 2.0

	box.position.z = step_depth * i + step_depth / 2.0
	box.size.x = step_width
	box.size.z = step_depth - epsilon # Avoid z-fighting and snapping

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
