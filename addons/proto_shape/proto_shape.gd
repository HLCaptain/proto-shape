@tool
extends EditorPlugin

const ProtoGizmo = preload("res://addons/proto_shape/proto_gizmo/proto_gizmo.gd")

var gizmo_plugin = ProtoGizmo.new()
var undo_redo: EditorUndoRedoManager

func _enter_tree():
	undo_redo = get_undo_redo()
	gizmo_plugin.undo_redo = undo_redo
	add_custom_type("ProtoRamp", "Node3D", preload("res://addons/proto_shape/proto_ramp/proto_ramp.gd"), preload("res://addons/proto_shape/icon/proto-ramp-icon.png"))
	add_custom_type("ProtoGizmoWrapper", "Node", preload("res://addons/proto_shape/proto_gizmo_wrapper/proto_gizmo_wrapper.gd"), preload("res://addons/proto_shape/icon/proto-gizmo-wrapper-icon.png"))
	add_node_3d_gizmo_plugin(gizmo_plugin)

	var snap_to_grid_action = InputEventKey.new()
	snap_to_grid_action.keycode = KEY_CTRL
	var fine_snap_to_grid_action = InputEventKey.new()
	fine_snap_to_grid_action.keycode = KEY_SHIFT
	InputMap.add_action("snap_to_grid")
	InputMap.add_action("fine_snap_to_grid")
	InputMap.action_add_event("snap_to_grid", snap_to_grid_action)
	InputMap.action_add_event("fine_snap_to_grid", fine_snap_to_grid_action)

func _exit_tree():
	remove_custom_type("ProtoRamp")
	remove_custom_type("ProtoGizmoWrapper")
	remove_node_3d_gizmo_plugin(gizmo_plugin)
	InputMap.erase_action("snap_to_grid")
	InputMap.erase_action("fine_snap_to_grid")

func _shortcut_input(event: InputEvent) -> void:
	if event.is_action_pressed("snap_to_grid"):
		if event is InputEventKey:
			if event.keycode == KEY_CTRL:
				gizmo_plugin.snapping = true
				if event.shift_pressed:
					gizmo_plugin.fine_snapping = true
				else:
					gizmo_plugin.fine_snapping = false
	if event.is_action_pressed("fine_snap_to_grid"):
		if event is InputEventKey:
			if event.keycode == KEY_SHIFT and event.ctrl_pressed:
				gizmo_plugin.fine_snapping = true
			else:
				gizmo_plugin.snapping = false
				gizmo_plugin.fine_snapping = false
	if event.is_action_released("snap_to_grid"):
		gizmo_plugin.snapping = false
		gizmo_plugin.fine_snapping = false
	if event.is_action_released("fine_snap_to_grid"):
		gizmo_plugin.fine_snapping = false
