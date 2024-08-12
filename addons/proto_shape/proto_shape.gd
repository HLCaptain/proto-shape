@tool
extends EditorPlugin

const ProtoGizmo = preload("proto_gizmo/proto_gizmo.gd")

var gizmo_plugin = ProtoGizmo.new()

func _enter_tree():
	add_custom_type("ProtoRamp", "CSGCombiner3D", preload("proto_ramp/proto_ramp.gd"), preload("res://addons/proto_shape/icon/proto-ramp-icon.png"))
	add_custom_type("ProtoGizmoWrapper", "Node", preload("proto_gizmo_wrapper/proto_gizmo_wrapper.gd"), preload("res://addons/proto_shape/icon/proto-gizmo-handler.svg"))
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_custom_type("ProtoRamp")
	remove_custom_type("ProtoGizmoWrapper")
	remove_node_3d_gizmo_plugin(gizmo_plugin)
