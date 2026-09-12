extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MIN_PITCH := -60.0
const MAX_PITCH := 45.0

@export_range(0.01, 1.0, 0.01) var mouse_sensitivity := 0.2

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/SpringArm3D

var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity"))

func _ready() -> void:
	camera_arm.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		camera_pivot.rotation.x = clamp(
			camera_pivot.rotation.x - deg_to_rad(event.relative.y * mouse_sensitivity),
			deg_to_rad(MIN_PITCH),
			deg_to_rad(MAX_PITCH)
		)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_direction.x, 0.0, input_direction.y)).normalized()
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	move_and_slide()
