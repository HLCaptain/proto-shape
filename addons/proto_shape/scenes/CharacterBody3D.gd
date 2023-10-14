extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Camera rotation parameters
var sensitivity: float = 0.2
var min_pitch: float = -60
var max_pitch: float = 60

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var mouse_sens = 0.3
var camera_anglev=0

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

func _input(event):
	if event is InputEventMouseMotion:
		handle_camera_rotation(event.relative)

func handle_camera_rotation(mouse_delta: Vector2):
	# Rotate the camera
	rotate_y(deg_to_rad(-mouse_delta.x * sensitivity))
	var new_pitch = rotation_degrees.x - mouse_delta.y * sensitivity
	#rotation_degrees.x = clamp(new_pitch, min_pitch, max_pitch)
