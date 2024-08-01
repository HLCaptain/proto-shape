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

## Default public values
const _default_calculation := Calculation.STAIRCASE_DIMENSIONS
const _default_steps: int = 8
const _default_width: float = 1.0
const _default_height: float = 1.0
const _default_depth: float = 1.0
const _default_fill := true
const _default_type := Type.RAMP
const _default_anchor := Anchor.BOTTOM_CENTER
const _default_anchor_fixed := true

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

var material: Variant: set = set_material, get = get_material

const ProtoGizmoPlugin := preload("res://addons/proto_shape/proto_gizmo.gd")
const ProtoGizmoWrapper = preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")
const ProtoGizmoUtils = preload("res://addons/proto_shape/proto_gizmo_utils.gd")
# Implementing Gizmo
var width_gizmo_id: int
var depth_gizmo_id: int
var height_gizmo_id: int
var gizmo_utils: ProtoGizmoUtils

func _get_property_list() -> Array[Dictionary]:
	var list: Array[Dictionary] = [
		{"name": "type", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Ramp,Staircase"},
		{"name": "width", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"},
		{"name": "height", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"},
		{"name": "depth", "type": TYPE_FLOAT, "hint": PROPERTY_HINT_RANGE, "hint_string": "0.001,100,0.01,or_greater"},
		{"name": "anchor", "type": TYPE_INT, "hint": PROPERTY_HINT_ENUM, "hint_string": "Bottom Center,Bottom Left,Bottom Right,Top Center,Top Left,Top Right,Base Center,Base Left,Base Right"},
		{"name": "anchor_fixed", "type": TYPE_BOOL},
		{"name": "material","class_name": &"BaseMaterial3D,ShaderMaterial", "type": 24, "hint": 17, "hint_string": "BaseMaterial3D,ShaderMaterial", "usage": 6 }
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
		"material":
			set_material(value)
			return true

	return false

func _property_can_revert(property: StringName) -> bool:
	if property in ["type", "calculation", "steps", "width", "height", "depth", "fill", "anchor", "anchor_fixed", "material"]:
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

func get_fill() -> bool:
	return _fill

func get_steps() -> int:
	return _steps

func get_anchor() -> Anchor:
	return _anchor

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
	refresh_type()
	type_changed.emit()
	update_gizmos()

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
	update_gizmos()

func set_height(value: float) -> void:
	_height = value
	refresh_children()
	height_changed.emit()
	update_gizmos()

func set_depth(value: float) -> void:
	_depth = value
	refresh_children()
	depth_changed.emit()
	update_gizmos()

func set_fill(value: bool) -> void:
	_fill = value
	refresh_children()
	fill_changed.emit()
	update_gizmos()

## Translates the ramp/staircase to a new anchor point in local space.
## Then recalculates the stairs/ramp with the new offset.
func set_anchor(value: Anchor) -> void:
	# Transform node to new anchor
	translate_anchor(anchor, value)
	_anchor = value
	refresh_children()
	anchor_changed.emit()
	update_gizmos()

## Translates the ramp/staircase to a new anchor point in local space if anchor is not fixed.
func translate_anchor(from_anchor: Anchor, to_anchor: Anchor) -> void:
	if not anchor_fixed:
		translate_object_local(get_anchor_offset(from_anchor) - get_anchor_offset(to_anchor))

func set_anchor_fixed(value: bool) -> void:
	_anchor_fixed = value

func set_material(value: Variant) -> void:
	material = value
	for shape in csg_shapes:
		shape.material = value

func set_steps(value: int) -> void:
	_steps = value
	refresh_steps(value)
	step_count_changed.emit()
	update_gizmos()

## Deletes all children and generates new steps/ramp.
func refresh_steps(new_steps: int) -> void:
	for shape in csg_shapes:
		shape.free()
	csg_shapes.clear()

	# Gracefully delete all steps related to the ramp/staircase
	for child in get_children():
		if child is CSGBox3D or child is CSGPolygon3D:
			child.queue_free()

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

func init_gizmo() -> void:
	# Generate a random id for each gizmo
	width_gizmo_id = randi_range(0, 1_000_000)
	depth_gizmo_id = randi_range(0, 1_000_000)
	height_gizmo_id = randi_range(0, 1_000_000)

func redraw_gizmos(gizmo: EditorNode3DGizmo, plugin: ProtoGizmoPlugin, node: Node) -> void:
	if node != self:
		return

	if width_gizmo_id == 0 or depth_gizmo_id == 0 or height_gizmo_id == 0:
		plugin.create_material("main", Color(1, 0, 0))
		plugin.create_material("selected", Color(0, 0, 1, 0.1))
		plugin.create_handle_material("handles")
		init_gizmo()

	gizmo.clear()
	var true_depth: float = get_true_depth()
	var true_height: float = get_true_height()
	var anchor_offset: Vector3 = get_anchor_offset(anchor)
	var depth_gizmo_position := Vector3(0, true_height / 2, true_depth) + anchor_offset
	var width_gizmo_position := Vector3(width / 2, true_height / 2, true_depth / 2) + anchor_offset
	var height_gizmo_position := Vector3(0, true_height, true_depth / 2) + anchor_offset

	# When on the left, width gizmo is on the right
	# When in the back (top, base), depth gizmo is on the front
	# When on the top, height gizmo is on the bottom
	match anchor:
		Anchor.BOTTOM_LEFT:
			width_gizmo_position.x = -width
		Anchor.TOP_LEFT:
			width_gizmo_position.x = -width
			depth_gizmo_position.z = -true_depth
			height_gizmo_position.y = -true_height
		Anchor.BASE_LEFT:
			width_gizmo_position.x = -width
			depth_gizmo_position.z = -true_depth
		Anchor.BASE_CENTER:
			depth_gizmo_position.z = -true_depth
		Anchor.BASE_RIGHT:
			depth_gizmo_position.z = -true_depth
		Anchor.TOP_RIGHT:
			depth_gizmo_position.z = -true_depth
			height_gizmo_position.y = -true_height
		Anchor.TOP_CENTER:
			depth_gizmo_position.z = -true_depth
			height_gizmo_position.y = -true_height

	var handles = PackedVector3Array()
	handles.push_back(depth_gizmo_position)
	handles.push_back(width_gizmo_position)
	handles.push_back(height_gizmo_position)

	gizmo.add_handles(handles, plugin.get_material("handles", gizmo), [depth_gizmo_id, width_gizmo_id, height_gizmo_id])

	# Add collision triangles by generating TriangleMesh from node mesh
	# Meshes can be empty when reparenting the node with an existing selection
	# FIXME: Behavior is inconsistent, as other gizmos can override the collision triangles._a
	#  Node can be selected without a problem when reparenting with a single Node3D.
	#  Node cannot be selected normally, when the new parent is a CSGShape3D.
	#  CSGShape3D is updating its own collision triangles, which are overriding the ProtoRamp's.
	#  Although in theory, ProtoRamp's Gizmo has more priority, it doesn't seem to work.

	if get_meshes().size() > 1:
		gizmo.add_collision_triangles(get_meshes()[1].generate_triangle_mesh())
		gizmo.add_mesh(get_meshes()[1], plugin.get_material("selected", gizmo))

func set_handle(
	gizmo: EditorNode3DGizmo,
	handle_id: int,
	secondary: bool,
	camera: Camera3D,
	screen_pos: Vector2,
	child: Node) -> void:
	if child != self:
		return
	match handle_id:
		depth_gizmo_id:
			_set_depth_handle(gizmo, camera, screen_pos)
		width_gizmo_id:
			_set_width_handle(gizmo, camera, screen_pos)
		height_gizmo_id:
			_set_height_handle(gizmo, camera, screen_pos)
	update_gizmos()

func _set_width_handle(
	gizmo: EditorNode3DGizmo,
	camera: Camera3D,
	screen_pos: Vector2):
	var gizmo_position := Vector3(width / 2, get_true_height() / 2, get_true_depth() / 2) + get_anchor_offset(anchor)
	var offset: float = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, Vector3(1, 0, 0), self).x
	# If anchor is on the left, offset is negative
	# If anchor is not centered, offset is divided by 2
	match anchor:
		Anchor.BOTTOM_LEFT:
			offset = -offset / 2
		Anchor.TOP_LEFT:
			offset = -offset / 2
		Anchor.BASE_LEFT:
			offset = -offset / 2
		Anchor.BOTTOM_RIGHT:
			offset = offset / 2
		Anchor.TOP_RIGHT:
			offset = offset / 2
		Anchor.BASE_RIGHT:
			offset = offset / 2
	width = offset * 2

func _set_depth_handle(
	gizmo: EditorNode3DGizmo,
	camera: Camera3D,
	screen_pos: Vector2):
	var gizmo_position := Vector3(0, get_true_height() / 2, get_true_depth()) + get_anchor_offset(anchor)
	var offset: float = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, Vector3(0, 0, 1), self).z
	if calculation == Calculation.STEP_DIMENSIONS and type == Type.STAIRCASE:
		offset = offset / steps
	# If anchor is on the back, offset is negative
	match anchor:
		Anchor.BASE_CENTER:
			offset = -offset
		Anchor.BASE_RIGHT:
			offset = -offset
		Anchor.BASE_LEFT:
			offset = -offset
		Anchor.TOP_CENTER:
			offset = -offset
		Anchor.TOP_RIGHT:
			offset = -offset
		Anchor.TOP_LEFT:
			offset = -offset
	depth = offset

func _set_height_handle(
	gizmo: EditorNode3DGizmo,
	camera: Camera3D,
	screen_pos: Vector2):
	var gizmo_position := Vector3(0, get_true_height(), get_true_depth() / 2) + get_anchor_offset(anchor)
	var offset: float = gizmo_utils.get_handle_offset(camera, screen_pos, gizmo_position, Vector3(0, 1, 0), self).y
	# If anchor is TOP, offset is negative
	if calculation == Calculation.STEP_DIMENSIONS and type == Type.STAIRCASE:
		offset = offset / steps
	match anchor:
		Anchor.TOP_LEFT:
			offset = -offset
		Anchor.TOP_CENTER:
			offset = -offset
		Anchor.TOP_RIGHT:
			offset = -offset
	height = offset

func refresh_all() -> void:
	set_steps(steps)

func _enter_tree() -> void:
	# is_entered_tree is used to avoid setting properties traditionally on initialization
	set_steps(steps)
	if material:
		set_material(material)
	if get_parent() is ProtoGizmoWrapper:
		var parent: ProtoGizmoWrapper = get_parent()
		gizmo_utils = ProtoGizmoUtils.new()
		parent.redraw_gizmos_for_child_signal.connect(redraw_gizmos)
		parent.set_handle_for_child_signal.connect(set_handle)
	is_entered_tree = true

func _exit_tree() -> void:
	# Remove all children
	for child in csg_shapes:
		child.queue_free()
	csg_shapes.clear()
	if get_parent() is ProtoGizmoWrapper:
		var parent: ProtoGizmoWrapper = get_parent()
		parent.redraw_gizmos_for_child_signal.disconnect(redraw_gizmos)
		parent.set_handle_for_child_signal.disconnect(set_handle)
