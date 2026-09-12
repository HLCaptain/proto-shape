extends SceneTree

const ProtoWall = preload("res://addons/proto_shape/proto_wall/proto_wall.gd")

const LAUNCHERS := [
	"res://addons/proto_shape/proto_wall/examples/proto_wall_solid_examples.tscn",
	"res://addons/proto_shape/proto_wall/examples/proto_wall_rail_examples.tscn",
	"res://addons/proto_shape/proto_wall/examples/proto_wall_mixed_blockout.tscn",
	"res://addons/proto_shape/proto_wall/examples/proto_wall_interpolation_showcase.tscn",
]

var failures := 0
var world: Node3D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	world = Node3D.new()
	root.add_child(world)
	_test_empty_launchers()
	await _test_exit_and_free_abort()
	await _test_saved_edits_are_persistent()
	await _test_interpolation_showcase_count()
	world.queue_free()
	await process_frame
	await process_frame
	if failures == 0:
		print("PASS: wall example persistence")
	quit(1 if failures else 0)

func _test_empty_launchers() -> void:
	for path in LAUNCHERS:
		var launcher: Node = load(path).instantiate()
		_expect(launcher.get_child_count() == 0, "%s must remain an empty launcher" % path)
		_expect(not launcher.setup_completed, "%s must start incomplete" % path)
		_expect(_property_has_usage(launcher, "setup_completed", PROPERTY_USAGE_STORAGE), "Completion marker must be stored")
		_expect(not _property_has_usage(launcher, "setup_completed", PROPERTY_USAGE_EDITOR), "Completion marker must stay out of the inspector")
		launcher.free()

func _test_exit_and_free_abort() -> void:
	var launcher: Node = load(LAUNCHERS[0]).instantiate()
	world.add_child(launcher)
	world.remove_child(launcher)
	await process_frame
	_expect(not launcher.setup_completed, "Exited setup must not mark itself complete")
	_expect(not launcher.is_setting_up, "Exited setup must clear its running state")
	_expect(launcher.get_child_count() == 0, "Exited deferred setup must not add children")
	world.add_child(launcher)
	_expect(await _wait_for_setup(launcher), "Re-entered setup must restart and complete")
	_expect(_count_direct_walls(launcher) == 8, "A restarted solid example must not duplicate walls")
	launcher.queue_free()
	await process_frame

	var freed_launcher: Node = load(LAUNCHERS[0]).instantiate()
	var instance_id := freed_launcher.get_instance_id()
	world.add_child(freed_launcher)
	freed_launcher.queue_free()
	await process_frame
	await process_frame
	_expect(not is_instance_id_valid(instance_id), "A freed launcher must not survive its deferred setup")

func _test_saved_edits_are_persistent() -> void:
	var launcher: Node = load(LAUNCHERS[0]).instantiate()
	world.add_child(launcher)
	_expect(await _wait_for_setup(launcher), "Solid example setup must complete")
	_expect(launcher.setup_completed, "Completed setup must set its marker")

	var edited_wall = launcher.get_node("CurvedArenaWall")
	edited_wall.height = 1.25
	launcher.get_node("StraightSolidWall").name = "UserRenamedWall"
	launcher.get_node("LowCoverWallLabel").free()
	var added := Node3D.new()
	added.name = "UserAdded"
	launcher.add_child(added)
	added.owner = launcher

	var path := "/tmp/proto_wall_saved_edits_%s.tscn" % OS.get_process_id()
	_expect(_save_scene(launcher, path), "Edited example must save")
	launcher.queue_free()
	await process_frame

	var restored: Node = load(path).instantiate()
	world.add_child(restored)
	await process_frame
	await process_frame
	_expect(restored.setup_completed, "Saved completion marker must restore")
	_expect_float(restored.get_node("CurvedArenaWall").height, 1.25, "Saved wall height must restore")
	_expect(restored.has_node("UserAdded"), "Saved user additions must restore")
	_expect(restored.has_node("UserRenamedWall"), "Saved user renames must restore")
	_expect(not restored.has_node("StraightSolidWall"), "Setup must not recreate a renamed wall")
	_expect(not restored.has_node("LowCoverWallLabel"), "Setup must not recreate a deleted label")

	for child in restored.get_children():
		child.free()
	_expect(restored.get_child_count() == 0, "Delete-all test must start empty")
	var empty_path := "/tmp/proto_wall_delete_all_%s.tscn" % OS.get_process_id()
	_expect(_save_scene(restored, empty_path), "Delete-all example must save")
	restored.queue_free()
	await process_frame

	var empty_restored: Node = load(empty_path).instantiate()
	world.add_child(empty_restored)
	await process_frame
	await process_frame
	_expect(empty_restored.setup_completed, "Delete-all scene must retain its completion marker")
	_expect(empty_restored.get_child_count() == 0, "Delete-all scene must remain empty after reload")
	empty_restored.queue_free()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(empty_path)

func _test_interpolation_showcase_count() -> void:
	var showcase: Node = load(LAUNCHERS[3]).instantiate()
	world.add_child(showcase)
	_expect(await _wait_for_setup(showcase), "Interpolation showcase must complete")
	_expect(_count_direct_walls(showcase) == 80, "Interpolation showcase must retain all 80 ProtoWall nodes")
	var path := "/tmp/proto_wall_interpolation_%s.tscn" % OS.get_process_id()
	_expect(_save_scene(showcase, path), "Interpolation showcase must save")
	showcase.queue_free()
	await process_frame

	var restored: Node = load(path).instantiate()
	world.add_child(restored)
	await process_frame
	await process_frame
	_expect(restored.setup_completed, "Saved interpolation marker must restore")
	_expect(_count_direct_walls(restored) == 80, "Saved interpolation showcase must retain exactly 80 walls")
	restored.queue_free()
	DirAccess.remove_absolute(path)

func _wait_for_setup(launcher: Node, maximum_frames: int = 120) -> bool:
	for frame in range(maximum_frames):
		if launcher.setup_completed and not launcher.is_setting_up:
			return true
		await process_frame
	return launcher.setup_completed and not launcher.is_setting_up

func _save_scene(scene_root: Node, path: String) -> bool:
	var packed := PackedScene.new()
	return packed.pack(scene_root) == OK and ResourceSaver.save(packed, path) == OK

func _count_direct_walls(node: Node) -> int:
	var count := 0
	for child in node.get_children():
		if child is ProtoWall:
			count += 1
	return count

func _property_has_usage(object: Object, property_name: StringName, usage: int) -> bool:
	for property in object.get_property_list():
		if property["name"] == property_name and int(property["usage"]) & usage != 0:
			return true
	return false

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _expect_float(actual: float, expected: float, message: String) -> void:
	_expect(is_equal_approx(actual, expected), "%s: expected %s, got %s" % [message, expected, actual])
