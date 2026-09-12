@tool
extends Node

const SHOWCASE := "res://addons/proto_shape/proto_wall/examples/proto_wall_interpolation_showcase.tscn"
const ProtoWall = preload("res://addons/proto_shape/proto_wall/proto_wall.gd")

var failures := 0

func _ready() -> void:
	if "--proto-shape-tests" in OS.get_cmdline_user_args() and scene_file_path in OS.get_cmdline_args():
		_run.call_deferred()

func _run() -> void:
	for frame in range(5):
		await get_tree().process_frame

	var completed: Node = load(SHOWCASE).instantiate()
	add_child(completed)
	for frame in range(180):
		if completed.setup_completed and not completed.is_setting_up:
			break
		await get_tree().process_frame
	_expect(completed.setup_completed and not completed.is_setting_up, "Full editor showcase must finish generating")
	var wall_count := 0
	for child in completed.get_children():
		if child is ProtoWall:
			wall_count += 1
	_expect(wall_count == 80, "Full editor showcase must contain exactly 80 walls")
	completed.queue_free()
	await get_tree().process_frame

	var exited: Node = load(SHOWCASE).instantiate()
	add_child(exited)
	await _wait_until_setup_yields(exited)
	_expect(exited.is_setting_up, "Editor setup must reach an awaited frame")
	remove_child(exited)
	var child_count_after_exit := exited.get_child_count()
	for frame in range(3):
		await get_tree().process_frame
	_expect(not exited.setup_completed, "Exited awaited setup must not mark itself complete")
	_expect(not exited.is_setting_up, "Exited awaited setup must clear its running state")
	_expect(exited.get_child_count() == child_count_after_exit, "Exited awaited setup must stop adding children")
	exited.free()

	var freed: Node = load(SHOWCASE).instantiate()
	add_child(freed)
	await _wait_until_setup_yields(freed)
	_expect(freed.is_setting_up, "Freed setup must reach an awaited frame")
	var instance_id := freed.get_instance_id()
	freed.queue_free()
	for frame in range(3):
		await get_tree().process_frame
	_expect(not is_instance_id_valid(instance_id), "Freed awaited setup must not resume")

	for frame in range(3):
		await get_tree().process_frame
	if failures == 0:
		print("PASS: wall example full 80-shape generation and async cancellation")
	get_tree().quit(1 if failures else 0)

func _wait_until_setup_yields(launcher: Node) -> void:
	for frame in range(10):
		if launcher.is_setting_up:
			return
		await get_tree().process_frame

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
