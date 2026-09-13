@tool
extends Node3D

const ProtoGizmo = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo.gd")
const ProtoGizmoWrapper = preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd")
const ExampleProtoBox = preload("res://addons/proto_shape/proto_gizmo/examples/provider_box/example_proto_box.gd")
const ExampleProtoBoxGizmos = preload("res://addons/proto_shape/proto_gizmo/examples/provider_box/example_proto_box_gizmos.gd")
const ExampleDirectionalBeam = preload("res://addons/proto_shape/proto_gizmo/examples/directional_beam/example_directional_beam.gd")
const ExampleDirectionalBeamGizmos = preload("res://addons/proto_shape/proto_gizmo/examples/directional_beam/example_directional_beam_gizmos.gd")
const ExampleWrappedVolume = preload("res://addons/proto_shape/proto_gizmo/examples/wrapper_volume/example_wrapped_volume.gd")

var failures := 0

func _ready() -> void:
	if "--proto-shape-tests" not in OS.get_cmdline_user_args():
		return
	for argument in OS.get_cmdline_args():
		if argument.ends_with("test_proto_gizmo_examples.tscn"):
			_run.call_deferred()
			return

func _run() -> void:
	for frame in range(5):
		await get_tree().process_frame
	var plugin := ProtoGizmo.new()
	plugin.undo_redo = EditorInterface.get_editor_undo_redo()
	var world := Node3D.new()
	add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.global_position = Vector3(-6.0, 4.0, 7.0)

	var box = ExampleProtoBox.new()
	world.add_child(box)
	var box_gizmos = ExampleProtoBoxGizmos.new()
	box_gizmos.attach_shape(box)
	_check_provider(plugin, camera, box, box_gizmos, box_gizmos.HANDLE_WIDTH, &"width", "provider box")

	var beam = ExampleDirectionalBeam.new()
	beam.position = Vector3(4.0, 0.0, 0.0)
	world.add_child(beam)
	var beam_gizmos = ExampleDirectionalBeamGizmos.new()
	beam_gizmos.attach_shape(beam)
	_check_provider(plugin, camera, beam, beam_gizmos, beam_gizmos.HANDLE_LENGTH, &"length", "directional beam")

	var wrapper := ProtoGizmoWrapper.new()
	world.add_child(wrapper)
	var volume = ExampleWrappedVolume.new()
	wrapper.add_child(volume)
	volume.position = Vector3(-4.0, 0.0, 0.0)
	_check_provider(plugin, camera, volume, volume, volume.HANDLE_RADIUS, &"radius", "wrapped volume")

	box_gizmos.remove_shape()
	beam_gizmos.remove_shape()
	world.queue_free()
	for frame in range(3):
		await get_tree().process_frame
	if failures == 0:
		print("PASS: gizmo example undo")
	get_tree().quit(1 if failures else 0)

func _check_provider(plugin, camera: Camera3D, target, provider, handle_id: int, property_name: StringName, context: String) -> void:
	var history_id: int = plugin.undo_redo.get_object_history_id(target)
	var history: UndoRedo = plugin.undo_redo.get_history_undo_redo(history_id)
	var version_before: int = history.get_version()
	var original_value: float = target.get(property_name)
	var handle: Vector3 = provider._get_handle_position(handle_id)
	var drag_axis: Vector3 = provider._get_drag_axis(handle_id).normalized()
	camera.look_at(target.global_transform * handle)

	_expect(not provider.begin_arrow_drag(plugin, handle_id, camera, Vector2(INF, 0)), "%s rejects an invalid begin" % context)
	provider.commit_arrow_drag(plugin, handle_id, false)
	_expect(provider.editing_handle == 0 and history.get_version() == version_before, "%s invalid begin creates no state or action" % context)

	_expect(provider.begin_arrow_drag(plugin, handle_id, camera, camera.unproject_position(target.global_transform * handle)), "%s no-op drag begins" % context)
	provider.commit_arrow_drag(plugin, handle_id, false)
	_expect(provider.editing_handle == 0, "%s no-op clears editing state" % context)
	_expect(history.get_version() == version_before, "%s no-op creates no undo action" % context)

	handle = provider._get_handle_position(handle_id)
	camera.look_at(target.global_transform * handle)
	_expect(provider.begin_arrow_drag(plugin, handle_id, camera, camera.unproject_position(target.global_transform * handle)), "%s cancel drag begins" % context)
	provider.set_arrow_drag(plugin, handle_id, camera, camera.unproject_position(target.global_transform * (handle + drag_axis * 0.25)))
	_expect(not is_equal_approx(float(target.get(property_name)), original_value), "%s live drag changes its property" % context)
	provider.commit_arrow_drag(plugin, handle_id, true)
	_expect(provider.editing_handle == 0, "%s cancel clears editing state" % context)
	_expect_float(target.get(property_name), original_value, "%s cancel restores its property" % context)
	_expect(history.get_version() == version_before, "%s cancel creates no undo action" % context)

	handle = provider._get_handle_position(handle_id)
	camera.look_at(target.global_transform * handle)
	_expect(provider.begin_arrow_drag(plugin, handle_id, camera, camera.unproject_position(target.global_transform * handle)), "%s clamped drag begins" % context)
	provider.set_arrow_drag(plugin, handle_id, camera, camera.unproject_position(target.global_transform * (handle - drag_axis * (original_value + 1.0))))
	_expect_float(target.get(property_name), 0.001, "%s applies its property minimum" % context)
	_expect_float(provider.end_value, 0.001, "%s records the applied setter value" % context)
	provider.commit_arrow_drag(plugin, handle_id, false)
	_expect(provider.editing_handle == 0, "%s commit clears editing state" % context)
	_expect(history.get_version() == version_before + 1, "%s changed drag creates one undo action" % context)
	history.undo()
	_expect_float(target.get(property_name), original_value, "%s undo restores its original value" % context)
	history.redo()
	_expect_float(target.get(property_name), 0.001, "%s redo applies its clamped value" % context)

	version_before = history.get_version()
	handle = provider._get_handle_position(handle_id)
	camera.look_at(target.global_transform * handle)
	_expect(provider.begin_arrow_drag(plugin, handle_id, camera, camera.unproject_position(target.global_transform * handle)), "%s already-clamped drag begins" % context)
	provider.set_arrow_drag(plugin, handle_id, camera, camera.unproject_position(target.global_transform * (handle - drag_axis * 2.0)))
	provider.commit_arrow_drag(plugin, handle_id, false)
	_expect(provider.editing_handle == 0 and history.get_version() == version_before, "%s already-clamped drag creates no action" % context)

func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _expect_float(actual: float, expected: float, message: String) -> void:
	_expect(is_equal_approx(actual, expected), "%s: expected %s, got %s" % [message, expected, actual])
