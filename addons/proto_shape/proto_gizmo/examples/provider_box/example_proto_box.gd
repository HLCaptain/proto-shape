@tool
extends Node3D

var _width := 2.0
var _height := 1.0
var _depth := 2.0

@export var width: float: set = set_width, get = get_width
@export var height: float: set = set_height, get = get_height
@export var depth: float: set = set_depth, get = get_depth

var shape_box: CSGBox3D = null
var gizmos = null

func get_proto_gizmo_provider() -> Variant:
	return gizmos

func get_width() -> float:
	return _width

func get_height() -> float:
	return _height

func get_depth() -> float:
	return _depth

func set_width(value: float) -> void:
	_width = max(0.001, value)
	refresh_shape()
	update_gizmos()

func set_height(value: float) -> void:
	_height = max(0.001, value)
	refresh_shape()
	update_gizmos()

func set_depth(value: float) -> void:
	_depth = max(0.001, value)
	refresh_shape()
	update_gizmos()

func refresh_shape() -> void:
	if not is_inside_tree():
		return

	if shape_box == null:
		shape_box = CSGBox3D.new()
		shape_box.name = "GeneratedBox"
		shape_box.use_collision = true
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.2, 0.7, 1.0, 0.7)
		shape_box.material = material
		add_child(shape_box)

	shape_box.size = Vector3(width, height, depth)
	shape_box.position = Vector3(0, height / 2.0, 0)

func _enter_tree() -> void:
	refresh_shape()
	if Engine.is_editor_hint():
		var ExampleProtoBoxGizmos = load("res://addons/proto_shape/proto_gizmo/examples/provider_box/example_proto_box_gizmos.gd")
		gizmos = ExampleProtoBoxGizmos.new()
		gizmos.attach_shape(self)

func _exit_tree() -> void:
	if Engine.is_editor_hint() and gizmos != null:
		gizmos.remove_shape()
	if shape_box != null:
		remove_child(shape_box)
		shape_box.queue_free()
		shape_box = null
