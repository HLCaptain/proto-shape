extends SceneTree

const ProtoWall = preload("res://addons/proto_shape/proto_wall/proto_wall.gd")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_curve_lifecycle()

	if failures == 0:
		print("ProtoWall tests passed")
	quit(failures)

func _test_curve_lifecycle() -> void:
	var default_wall := ProtoWall.new()
	root.add_child(default_wall)
	_check(default_wall.curve != null and default_wall.curve.get_point_count() == 2, "A new ProtoWall gets the default two-point curve")
	default_wall.queue_free()
	await process_frame

	var short_curve := Curve3D.new()
	short_curve.add_point(Vector3(1.0, 2.0, 3.0))
	var wall := ProtoWall.new()
	wall.curve = short_curve
	root.add_child(wall)
	_check(wall.curve == short_curve, "ProtoWall preserves an assigned short curve")
	_check(wall.curve.get_point_count() == 1, "ProtoWall does not replace a short curve with defaults")
	_check(wall.generated_shapes.is_empty(), "A short curve produces no generated geometry")

	var curve := Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0.0, 0.0, 4.0))
	wall.curve = curve
	_check(is_equal_approx(wall.get_path_length(), 4.0), "Replacing the Path3D curve refreshes the sampled path")

	curve.set_point_position(1, Vector3(0.0, 0.0, 7.0))
	_check(is_equal_approx(wall.get_path_length(), 7.0), "Path3D curve_changed refreshes edits without polling")

	curve.clear_points()
	curve.add_point(Vector3.ZERO)
	_check(curve.get_point_count() == 1, "Editing an active curve down to one point remains authored")
	_check(wall.generated_shapes.is_empty(), "Editing an active curve down to one point clears geometry")

	wall.queue_free()
	await process_frame

func _check(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
