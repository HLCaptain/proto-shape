extends SceneTree

const ProtoRamp = preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd")

var failures := 0
var world: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	_test_invalid_inputs()
	_test_mode_aware_bounds()
	_test_pre_tree_property_orders()
	_test_conversion_round_trips()
	_test_property_undo_redo()
	_test_anchors()
	_test_reentry_and_duplication()
	_test_step_dimensions_reload()
	_test_hidden_staircase_state_reload()
	world.queue_free()
	await process_frame
	if failures == 0:
		print("PASS: ramp state")
	quit(1 if failures else 0)

func _test_invalid_inputs() -> void:
	var ramp = _add_ramp()
	ramp.width = NAN
	ramp.height = INF
	ramp.depth = -INF
	ramp.fill = NAN
	ramp.steps = 0
	ramp.type = 99
	ramp.calculation = -1
	ramp.anchor = 99
	_expect_float(ramp.width, ProtoRamp.MIN_DIMENSION, "NaN width must use the safe minimum")
	_expect_float(ramp.height, ProtoRamp.MIN_DIMENSION, "Infinite height must use the safe minimum")
	_expect_float(ramp.depth, ProtoRamp.MIN_DIMENSION, "Infinite depth must use the safe minimum")
	_expect_float(ramp.fill, 1.0, "NaN fill must use the default")
	_expect(ramp.steps == 1, "Steps must stay positive")
	_expect(ramp.type == ProtoRamp.Type.STAIRCASE, "Type must clamp to its enum range")
	_expect(ramp.calculation == ProtoRamp.Calculation.STAIRCASE_DIMENSIONS, "Calculation must clamp to its enum range")
	_expect(ramp.anchor == ProtoRamp.Anchor.BASE_RIGHT, "Anchor must clamp to its enum range")
	ramp.queue_free()

func _test_mode_aware_bounds() -> void:
	var ramp = _add_ramp()
	ramp.type = ProtoRamp.Type.STAIRCASE
	ramp.steps = 8
	ramp.height = ProtoRamp.MIN_DIMENSION
	ramp.depth = ProtoRamp.MIN_DIMENSION
	ramp.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
	var per_step_minimum := ProtoRamp.MIN_DIMENSION / 8.0
	_expect_float(ramp.height, per_step_minimum, "Step height must preserve the total minimum")
	_expect_float(ramp.depth, per_step_minimum, "Step depth must preserve the total minimum")
	ramp.height = per_step_minimum / 2.0
	ramp.depth = per_step_minimum / 2.0
	ramp.width = ProtoRamp.MIN_DIMENSION / 2.0
	_expect_float(ramp.height, per_step_minimum, "Step height must clamp relative to step count")
	_expect_float(ramp.depth, per_step_minimum, "Step depth must clamp relative to step count")
	_expect_float(ramp.width, ProtoRamp.MIN_DIMENSION, "Width must use the whole-shape minimum")
	ramp.steps = 4
	_expect_float(ramp.height, ProtoRamp.MIN_DIMENSION / 4.0, "Reducing steps must retain a legal total height")
	_expect_float(ramp.depth, ProtoRamp.MIN_DIMENSION / 4.0, "Reducing steps must retain a legal total depth")
	_expect_float(ramp.get_true_height(), ProtoRamp.MIN_DIMENSION, "True height must remain legal")
	_expect_float(ramp.get_true_depth(), ProtoRamp.MIN_DIMENSION, "True depth must remain legal")
	ramp.queue_free()

func _test_pre_tree_property_orders() -> void:
	var ramps: Array = []

	var first = ProtoRamp.new()
	first.type = ProtoRamp.Type.STAIRCASE
	first.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
	first.steps = 8
	first.height = 0.000125
	first.depth = 0.000125
	ramps.append(first)

	var second = ProtoRamp.new()
	second.height = 0.000125
	second.depth = 0.000125
	second.steps = 8
	second.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
	second.type = ProtoRamp.Type.STAIRCASE
	ramps.append(second)

	var third = ProtoRamp.new()
	third.steps = 8
	third.type = ProtoRamp.Type.STAIRCASE
	third.height = 0.000125
	third.depth = 0.000125
	third.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
	ramps.append(third)

	for ramp in ramps:
		world.add_child(ramp)
		_expect_float(ramp.height, 0.000125, "Positive pre-tree step height must survive property order")
		_expect_float(ramp.depth, 0.000125, "Positive pre-tree step depth must survive property order")
		_expect_float(ramp.get_true_height(), ProtoRamp.MIN_DIMENSION, "Pre-tree order must preserve true height")
		_expect_float(ramp.get_true_depth(), ProtoRamp.MIN_DIMENSION, "Pre-tree order must preserve true depth")
		ramp.queue_free()

func _test_conversion_round_trips() -> void:
	var ramp = _add_ramp()
	ramp.type = ProtoRamp.Type.STAIRCASE
	ramp.steps = 8
	ramp.height = 1.25
	ramp.depth = 2.5
	var expected_height: float = ramp.get_true_height()
	var expected_depth: float = ramp.get_true_depth()
	var expected_polygon: PackedVector2Array = ramp.shape_polygon.polygon
	var expected_polygon_node: CSGPolygon3D = ramp.shape_polygon
	ramp.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
	_expect(ramp.shape_polygon == expected_polygon_node, "Calculation changes must not recreate unchanged geometry")
	_expect(ramp.shape_polygon.polygon == expected_polygon, "Calculation changes must preserve polygon points")
	ramp.calculation = ProtoRamp.Calculation.STAIRCASE_DIMENSIONS
	for index in range(100):
		ramp.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
		ramp.calculation = ProtoRamp.Calculation.STAIRCASE_DIMENSIONS
	_expect_float(ramp.get_true_height(), expected_height, "Calculation round trips must not drift height")
	_expect_float(ramp.get_true_depth(), expected_depth, "Calculation round trips must not drift depth")

	ramp.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
	for index in range(100):
		ramp.type = ProtoRamp.Type.RAMP
		ramp.type = ProtoRamp.Type.STAIRCASE
	_expect_float(ramp.get_true_height(), expected_height, "Type round trips must not drift height")
	_expect_float(ramp.get_true_depth(), expected_depth, "Type round trips must not drift depth")
	ramp.queue_free()

func _test_property_undo_redo() -> void:
	var ramp = _add_ramp()
	ramp.type = ProtoRamp.Type.STAIRCASE
	ramp.steps = 8
	ramp.height = 1.25
	ramp.depth = 2.5
	var expected_height: float = ramp.get_true_height()
	var expected_depth: float = ramp.get_true_depth()
	var undo_redo := UndoRedo.new()
	undo_redo.create_action("Change calculation")
	undo_redo.add_do_property(ramp, "calculation", ProtoRamp.Calculation.STEP_DIMENSIONS)
	undo_redo.add_undo_property(ramp, "calculation", ProtoRamp.Calculation.STAIRCASE_DIMENSIONS)
	undo_redo.commit_action()
	_expect_float(ramp.get_true_height(), expected_height, "Calculation do must preserve height")
	_expect_float(ramp.get_true_depth(), expected_depth, "Calculation do must preserve depth")
	undo_redo.undo()
	_expect_float(ramp.get_true_height(), expected_height, "Calculation undo must preserve height")
	_expect_float(ramp.get_true_depth(), expected_depth, "Calculation undo must preserve depth")
	undo_redo.redo()
	_expect_float(ramp.get_true_height(), expected_height, "Calculation redo must preserve height")
	_expect_float(ramp.get_true_depth(), expected_depth, "Calculation redo must preserve depth")

	undo_redo.create_action("Change type")
	undo_redo.add_do_property(ramp, "type", ProtoRamp.Type.RAMP)
	undo_redo.add_undo_property(ramp, "type", ProtoRamp.Type.STAIRCASE)
	undo_redo.commit_action()
	_expect_float(ramp.get_true_height(), expected_height, "Type do must preserve height")
	_expect_float(ramp.get_true_depth(), expected_depth, "Type do must preserve depth")
	undo_redo.undo()
	_expect_float(ramp.get_true_height(), expected_height, "Type undo must preserve height")
	_expect_float(ramp.get_true_depth(), expected_depth, "Type undo must preserve depth")
	undo_redo.redo()
	_expect_float(ramp.get_true_height(), expected_height, "Type redo must preserve height")
	_expect_float(ramp.get_true_depth(), expected_depth, "Type redo must preserve depth")
	undo_redo.clear_history()
	undo_redo.free()
	ramp.queue_free()

func _test_anchors() -> void:
	var ramp = _add_ramp()
	ramp.type = ProtoRamp.Type.STAIRCASE
	ramp.steps = 8
	ramp.width = 2.0
	ramp.height = 3.0
	ramp.depth = 4.0
	for anchor_value in range(ProtoRamp.Anchor.size()):
		ramp.anchor = anchor_value
		var offset_before: Vector3 = ramp.get_anchor_offset(anchor_value)
		ramp.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
		ramp.calculation = ProtoRamp.Calculation.STAIRCASE_DIMENSIONS
		_expect_vector(ramp.get_anchor_offset(anchor_value), offset_before, "Mode conversion must preserve anchor %s" % anchor_value)
	_expect_float(ramp.get_true_height(), 3.0, "Anchor checks must preserve height")
	_expect_float(ramp.get_true_depth(), 4.0, "Anchor checks must preserve depth")
	ramp.queue_free()

func _test_reentry_and_duplication() -> void:
	var ramp = _add_ramp()
	world.remove_child(ramp)
	world.add_child(ramp)
	_expect(_count_csg_polygons(ramp) == 1, "Re-entering the tree must create one generated polygon")
	var duplicate = ramp.duplicate()
	world.add_child(duplicate)
	_expect(_count_csg_polygons(duplicate) == 1, "Duplicating a ramp must retain one generated polygon")
	duplicate.queue_free()
	ramp.queue_free()

func _test_step_dimensions_reload() -> void:
	var scene_root := Node3D.new()
	scene_root.name = "Root"
	world.add_child(scene_root)
	var ramp = ProtoRamp.new()
	ramp.name = "Ramp"
	scene_root.add_child(ramp)
	ramp.owner = scene_root
	ramp.type = ProtoRamp.Type.STAIRCASE
	ramp.steps = 8
	ramp.height = ProtoRamp.MIN_DIMENSION
	ramp.depth = ProtoRamp.MIN_DIMENSION
	ramp.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
	var path := "/tmp/proto_shape_ramp_%s.tscn" % OS.get_process_id()
	var packed := PackedScene.new()
	_expect(packed.pack(scene_root) == OK, "Step-dimension scene must pack")
	_expect(ResourceSaver.save(packed, path) == OK, "Step-dimension scene must save")
	var loaded_scene: Node = load(path).instantiate()
	world.add_child(loaded_scene)
	var loaded_ramp = loaded_scene.get_node("Ramp")
	_expect(loaded_ramp.calculation == ProtoRamp.Calculation.STEP_DIMENSIONS, "Calculation must survive reload")
	_expect(loaded_ramp.steps == 8, "Steps must survive reload")
	_expect_float(loaded_ramp.height, 0.000125, "Small positive step height must survive reload")
	_expect_float(loaded_ramp.depth, 0.000125, "Small positive step depth must survive reload")
	_expect_float(loaded_ramp.get_true_height(), ProtoRamp.MIN_DIMENSION, "Reload must preserve true height")
	_expect_float(loaded_ramp.get_true_depth(), ProtoRamp.MIN_DIMENSION, "Reload must preserve true depth")
	loaded_scene.queue_free()
	scene_root.queue_free()
	DirAccess.remove_absolute(path)

func _test_hidden_staircase_state_reload() -> void:
	var scene_root := Node3D.new()
	scene_root.name = "HiddenStateRoot"
	world.add_child(scene_root)
	var ramp = ProtoRamp.new()
	ramp.name = "Ramp"
	scene_root.add_child(ramp)
	ramp.owner = scene_root
	ramp.type = ProtoRamp.Type.STAIRCASE
	ramp.steps = 12
	ramp.height = ProtoRamp.MIN_DIMENSION
	ramp.depth = 0.002
	ramp.calculation = ProtoRamp.Calculation.STEP_DIMENSIONS
	ramp.anchor = ProtoRamp.Anchor.TOP_RIGHT
	ramp.anchor_fixed = false
	ramp.type = ProtoRamp.Type.RAMP
	_expect(_property_has_usage(ramp, "calculation", PROPERTY_USAGE_STORAGE), "Hidden calculation must remain stored")
	_expect(not _property_has_usage(ramp, "calculation", PROPERTY_USAGE_EDITOR), "Ramp calculation must stay hidden")
	_expect(_property_has_usage(ramp, "steps", PROPERTY_USAGE_STORAGE), "Hidden steps must remain stored")
	_expect(not _property_has_usage(ramp, "steps", PROPERTY_USAGE_EDITOR), "Ramp steps must stay hidden")

	var expected_height: float = ramp.get_true_height()
	var expected_depth: float = ramp.get_true_depth()
	var path := "/tmp/proto_shape_ramp_hidden_%s.tscn" % OS.get_process_id()
	var packed := PackedScene.new()
	_expect(packed.pack(scene_root) == OK, "Hidden-state scene must pack")
	_expect(ResourceSaver.save(packed, path) == OK, "Hidden-state scene must save")
	var loaded_scene: Node = load(path).instantiate()
	world.add_child(loaded_scene)
	var loaded_ramp = loaded_scene.get_node("Ramp")
	_expect(loaded_ramp.type == ProtoRamp.Type.RAMP, "Ramp type must survive reload")
	_expect(loaded_ramp.calculation == ProtoRamp.Calculation.STEP_DIMENSIONS, "Hidden calculation must survive reload")
	_expect(loaded_ramp.steps == 12, "Hidden steps must survive reload")
	_expect(loaded_ramp.anchor == ProtoRamp.Anchor.TOP_RIGHT, "Anchor must survive hidden-state reload")
	_expect(not loaded_ramp.anchor_fixed, "Anchor-fixed state must survive hidden-state reload")
	_expect_float(loaded_ramp.get_true_height(), expected_height, "Hidden-state reload must preserve true height")
	_expect_float(loaded_ramp.get_true_depth(), expected_depth, "Hidden-state reload must preserve true depth")
	loaded_ramp.type = ProtoRamp.Type.STAIRCASE
	_expect(_property_has_usage(loaded_ramp, "calculation", PROPERTY_USAGE_EDITOR), "Staircase calculation must become visible")
	_expect(_property_has_usage(loaded_ramp, "steps", PROPERTY_USAGE_EDITOR), "Staircase steps must become visible")
	_expect_float(loaded_ramp.get_true_height(), expected_height, "Restored calculation must preserve true height")
	_expect_float(loaded_ramp.get_true_depth(), expected_depth, "Restored steps must preserve true depth")
	_expect_float(loaded_ramp.height, expected_height / 12.0, "Restored Step Dimensions must expose per-step height")
	_expect_float(loaded_ramp.depth, expected_depth / 12.0, "Restored Step Dimensions must expose per-step depth")
	loaded_scene.queue_free()
	scene_root.queue_free()
	DirAccess.remove_absolute(path)

func _add_ramp():
	var ramp = ProtoRamp.new()
	world.add_child(ramp)
	return ramp

func _count_csg_polygons(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is CSGPolygon3D:
			count += 1
	return count

func _property_has_usage(object: Object, property_name: StringName, usage: int) -> bool:
	for property in object.get_property_list():
		if property["name"] == property_name:
			if int(property["usage"]) & usage != 0:
				return true
	return false

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _expect_float(actual: float, expected: float, message: String) -> void:
	_expect(is_equal_approx(actual, expected), "%s: expected %s, got %s" % [message, expected, actual])

func _expect_vector(actual: Vector3, expected: Vector3, message: String) -> void:
	_expect(actual.is_equal_approx(expected), "%s: expected %s, got %s" % [message, expected, actual])
