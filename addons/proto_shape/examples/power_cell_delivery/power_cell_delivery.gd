extends Node3D

const ProtoExampleControls = preload("res://addons/proto_shape/examples/proto_example_controls.gd")

enum DeliveryState {
	AT_SOURCE,
	CARRIED,
	DELIVERED,
}

@onready var player: CharacterBody3D = %Player
@onready var power_cell: Node3D = %PowerCell
@onready var pickup_area: Area3D = %PowerCellPickupArea
@onready var terminal_area: Area3D = %TerminalArea
@onready var carry_socket: Node3D = %CarrySocket
@onready var terminal_socket: Node3D = %TerminalSocket
@onready var inactive_terminal: GeometryInstance3D = %InactiveTerminal
@onready var active_terminal: GeometryInstance3D = %ActiveTerminal
@onready var hud_label: Label = %HudLabel

var delivery_state := DeliveryState.AT_SOURCE
var cell_nearby := false
var terminal_nearby := false
var reset_pending := false

func _enter_tree() -> void:
	ProtoExampleControls.ensure_actions()

func _ready() -> void:
	pickup_area.body_entered.connect(_on_pickup_area_body_entered)
	pickup_area.body_exited.connect(_on_pickup_area_body_exited)
	terminal_area.body_entered.connect(_on_terminal_area_body_entered)
	terminal_area.body_exited.connect(_on_terminal_area_body_exited)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ProtoExampleControls.RESTART):
		reset_demo()
	elif event.is_action_pressed(ProtoExampleControls.INTERACT):
		interact()

func _physics_process(_delta: float) -> void:
	if not reset_pending and player.global_position.y < -5.0:
		reset_demo()

func interact() -> void:
	if delivery_state == DeliveryState.AT_SOURCE and cell_nearby:
		pick_up_cell()
	elif delivery_state == DeliveryState.CARRIED and terminal_nearby:
		deliver_cell()

func pick_up_cell() -> void:
	if delivery_state != DeliveryState.AT_SOURCE:
		return
	delivery_state = DeliveryState.CARRIED
	cell_nearby = false
	pickup_area.set_deferred("monitoring", false)
	power_cell.reparent(carry_socket)
	power_cell.transform = Transform3D.IDENTITY
	_update_hud()

func deliver_cell() -> void:
	if delivery_state != DeliveryState.CARRIED:
		return
	delivery_state = DeliveryState.DELIVERED
	terminal_nearby = false
	power_cell.reparent(terminal_socket)
	power_cell.transform = Transform3D.IDENTITY
	inactive_terminal.visible = false
	active_terminal.visible = true
	_update_hud()

func reset_demo() -> void:
	if reset_pending:
		return
	reset_pending = true
	get_tree().reload_current_scene()

func _on_pickup_area_body_entered(body: Node3D) -> void:
	if body == player and delivery_state == DeliveryState.AT_SOURCE:
		cell_nearby = true
		_update_hud()

func _on_pickup_area_body_exited(body: Node3D) -> void:
	if body == player:
		cell_nearby = false
		_update_hud()

func _on_terminal_area_body_entered(body: Node3D) -> void:
	if body == player:
		terminal_nearby = true
		_update_hud()

func _on_terminal_area_body_exited(body: Node3D) -> void:
	if body == player:
		terminal_nearby = false
		_update_hud()

func _update_hud() -> void:
	var objective := "Reach the cyan overlook and retrieve the power cell."
	var prompt := ""
	var interact_label := ProtoExampleControls.get_action_label(ProtoExampleControls.INTERACT)
	match delivery_state:
		DeliveryState.AT_SOURCE:
			if cell_nearby:
				prompt = "%s: Pick up power cell" % interact_label
		DeliveryState.CARRIED:
			objective = "Return the power cell to the relay terminal."
			if terminal_nearby:
				prompt = "%s: Insert power cell" % interact_label
		DeliveryState.DELIVERED:
			objective = "Relay restored!"
			prompt = "%s: Play again" % ProtoExampleControls.get_action_label(ProtoExampleControls.RESTART)
	var controls := "Move: WASD / Arrows / Stick  •  Jump: %s  •  Restart: %s  •  Release mouse: %s" % [
		ProtoExampleControls.get_action_label(ProtoExampleControls.JUMP),
		ProtoExampleControls.get_action_label(ProtoExampleControls.RESTART),
		ProtoExampleControls.get_action_label(ProtoExampleControls.RELEASE_CURSOR),
	]
	var lines := PackedStringArray(["POWER CELL RELAY", objective])
	if not prompt.is_empty():
		lines.append(prompt)
	lines.append(controls)
	hud_label.text = "\n".join(lines)
