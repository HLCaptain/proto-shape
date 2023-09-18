@tool
extends EditorPlugin

const ProtoStairsGizmo = preload("proto_stairs_gizmo.gd")

var gizmo_plugin = ProtoStairsGizmo.new()

func _enter_tree():
	add_custom_type("ProtoStairs", "CSGCombiner3D", preload("proto_stairs.gd"), preload("res://icon.svg"))
	add_node_3d_gizmo_plugin(gizmo_plugin)

func _exit_tree():
	remove_custom_type("ProtoStairs")
	remove_node_3d_gizmo_plugin(gizmo_plugin)
