@tool
extends Node3D

const _default_length := 3.0
const _default_height := 0.5
const _default_thickness := 0.5
const _default_direction_degrees := 35.0

var _length := _default_length
var _height := _default_height
var _thickness := _default_thickness
var _direction_degrees := _default_direction_degrees

@export var length: float: set = set_length, get = get_length
@export var height: float: set = set_height, get = get_height
@export var thickness: float: set = set_thickness, get = get_thickness
@export var direction_degrees: float: set = set_direction_degrees, get = get_direction_degrees

var shape_box: CSGBox3D = null
var gizmos = null

func get_proto_gizmo_provider() -> Variant:
	return gizmos

func get_proto_gizmo_selection_nodes() -> Array:
	return [shape_box]

func _property_can_revert(property: StringName) -> bool:
	return property in [&"length", &"height", &"thickness", &"direction_degrees"]

func _property_get_revert(property: StringName) -> Variant:
	match property:
		&"length":
			return _default_length
		&"height":
			return _default_height
		&"thickness":
			return _default_thickness
		&"direction_degrees":
			return _default_direction_degrees
	return null

func get_length() -> float:
	return _length

func get_height() -> float:
	return _height

func get_thickness() -> float:
	return _thickness

func get_direction_degrees() -> float:
	return _direction_degrees

func set_length(value: float) -> void:
	_length = max(0.001, value)
	refresh_shape()
	update_gizmos()

func set_height(value: float) -> void:
	_height = max(0.001, value)
	refresh_shape()
	update_gizmos()

func set_thickness(value: float) -> void:
	_thickness = max(0.001, value)
	refresh_shape()
	update_gizmos()

func set_direction_degrees(value: float) -> void:
	_direction_degrees = value
	refresh_shape()
	update_gizmos()

func get_direction_axis() -> Vector3:
	var angle := deg_to_rad(direction_degrees)
	return Vector3(sin(angle), 0, cos(angle)).normalized()

func get_right_axis() -> Vector3:
	var direction := get_direction_axis()
	return Vector3(direction.z, 0, -direction.x).normalized()

func refresh_shape() -> void:
	if not is_inside_tree():
		return

	if shape_box == null:
		shape_box = CSGBox3D.new()
		shape_box.name = "GeneratedBeam"
		shape_box.use_collision = true
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.55, 0.15, 0.7)
		shape_box.material = material
		add_child(shape_box)

	shape_box.size = Vector3(thickness, height, length)
	shape_box.rotation = Vector3(0, deg_to_rad(direction_degrees), 0)
	shape_box.position = get_direction_axis() * length / 2.0 + Vector3(0, height / 2.0, 0)

func _enter_tree() -> void:
	refresh_shape()
	if Engine.is_editor_hint():
		var ExampleDirectionalBeamGizmos = load("res://addons/proto_shape/proto_gizmo/examples/directional_beam/example_directional_beam_gizmos.gd")
		gizmos = ExampleDirectionalBeamGizmos.new()
		gizmos.attach_shape(self)

func _exit_tree() -> void:
	if Engine.is_editor_hint() and gizmos != null:
		gizmos.remove_shape()
	if shape_box != null:
		if shape_box.get_parent() == self:
			remove_child(shape_box)
		shape_box.queue_free()
		shape_box = null
