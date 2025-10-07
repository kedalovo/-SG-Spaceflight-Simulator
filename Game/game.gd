extends Node3D


@onready var world: Node3D = $World
@onready var player: Player = $Player


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		quit_game()


func quit_game() -> void:
	get_tree().quit()
