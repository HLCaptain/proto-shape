@tool
extends EditorPlugin

const ProtoRampGizmo = preload("gizmos/proto_ramp_gizmo.gd")
const ProtoArchGizmo = preload("gizmos/proto_arch_gizmo.gd")

var proto_ramp_gizmo_plugin = ProtoRampGizmo.new()
var proto_arch_gizmo_plugin = ProtoArchGizmo.new()

func _enter_tree():
	add_custom_type("ProtoRamp", "CSGCombiner3D", preload("proto_ramp/proto_ramp.gd"), preload("res://addons/proto_shape/icon/proto-ramp-icon.png"))
	add_custom_type("ProtoArch", "CSGCombiner3D", preload("proto_arch/proto_arch.gd"), preload("res://addons/proto_shape/icon/proto-ramp-icon.png"))
	add_node_3d_gizmo_plugin(proto_ramp_gizmo_plugin)
	add_node_3d_gizmo_plugin(proto_arch_gizmo_plugin)

func _exit_tree():
	remove_custom_type("ProtoRamp")
	remove_custom_type("ProtoArch")
	remove_node_3d_gizmo_plugin(proto_ramp_gizmo_plugin)
	remove_node_3d_gizmo_plugin(proto_arch_gizmo_plugin)
