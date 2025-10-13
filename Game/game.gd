extends Node3D


@onready var player: Player = $Player
@onready var spaceship: RigidBody3D = $Spaceship
@onready var label: Label = $Control/Label


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		quit_game()


func _process(_delta: float) -> void:
	pass
	#label.text = str(spaceship.is_controlled)
	#label.text += "\n" + str(spaceship.input_ dir)


func quit_game() -> void:
	get_tree().quit()


func _on_player_enter_ship() -> void:
	player.is_in_ship = true
	spaceship.toggle_camera(true)
	spaceship.is_controlled = true
	player.velocity = Vector3.ZERO
	player.anim_tree.get_node(player.anim_tree.anim_player).stop()
	player.set_physics_process(false)
	player.disable_collision(true)
	player.reparent(spaceship)
	player = spaceship.get_node("Player")
	player.position = Vector3.ZERO
	player.hide()


func _on_player_exit_ship() -> void:
	player.is_in_ship = false
	spaceship.is_controlled = false
	spaceship.toggle_camera(false)
	player.set_physics_process(true)
	player.disable_collision(false)
	player.position = Vector3(0.0, -0.5, -3.0)
	player.reparent(self)
	player = $Player
	player.show()
