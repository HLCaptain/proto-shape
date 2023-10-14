extends Camera3D

# Camera rotation parameters
@export var node_to_look_at: Node3D

func _process(delta):
	look_at(node_to_look_at.position)
