@tool
extends EditorPlugin

const ProtoGizmo = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo.gd")

var gizmo_plugin = ProtoGizmo.new()
var undo_redo: EditorUndoRedoManager

func _enter_tree():
	undo_redo = get_undo_redo()
	gizmo_plugin.undo_redo = undo_redo
	add_custom_type("ProtoRamp", "Node3D", preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd"), preload("res://addons/proto_shape/proto_ramp/icons/proto-ramp-icon.png"))
	add_custom_type("ProtoWall", "Path3D", preload("res://addons/proto_shape/proto_wall/proto_wall.gd"), preload("res://addons/proto_shape/proto_wall/icons/proto-wall-icon.png"))
	add_custom_type("ProtoGizmoWrapper", "Node", preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd"), preload("res://addons/proto_shape/icons/proto-gizmo-wrapper-icon.png"))
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	_reset_snapping()
	remove_custom_type("ProtoRamp")
	remove_custom_type("ProtoWall")
	remove_custom_type("ProtoGizmoWrapper")
	remove_node_3d_gizmo_plugin(gizmo_plugin)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_reset_snapping()

func _reset_snapping() -> void:
	if is_instance_valid(gizmo_plugin):
		gizmo_plugin.fine_snapping = false
		gizmo_plugin.snapping = false

func _handles(object: Object) -> bool:
	if object is Node3D:
		return gizmo_plugin.handles_node(object)
	return false

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if gizmo_plugin.handle_3d_gui_input(camera, event):
		return EditorPlugin.AFTER_GUI_INPUT_STOP
	return EditorPlugin.AFTER_GUI_INPUT_PASS

func _shortcut_input(event: InputEvent) -> void:
	if not event is InputEventKey or event.echo:
		return
	if event.keycode not in [KEY_CTRL, KEY_SHIFT]:
		return
	var ctrl: bool = event.pressed if event.keycode == KEY_CTRL else event.ctrl_pressed
	var shift: bool = event.pressed if event.keycode == KEY_SHIFT else event.shift_pressed
	gizmo_plugin.snapping = ctrl
	gizmo_plugin.fine_snapping = ctrl and shift
