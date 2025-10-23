extends Node3D


@onready var player: Player = $Player
@onready var spaceship: RigidBody3D = $Spaceship
@onready var label: Label = $Control/Label
@onready var asteroids: Node3D = $Asteroids


const ASTEROID = preload("uid://fpevas20cdlo")


@export var asteroid_field_size: Vector3 = Vector3.ZERO
@export var asteroid_negative_field_size: Vector3 = Vector3.ZERO
@export var asteroid_number: int = 0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for i in asteroid_number:
		var new_asteroid: Asteroid = ASTEROID.instantiate()
		var x = randf_range(-asteroid_field_size.x, asteroid_field_size.x)
		var y = randf_range(-asteroid_field_size.y, asteroid_field_size.y)
		var z = randf_range(-asteroid_field_size.z, asteroid_field_size.z)
		var an = asteroid_negative_field_size
		while (x > -an.x and x < an.x) and (y > -an.y and y < an.y) and (z > -an.z and z < an.z):
			x = randf_range(-asteroid_field_size.x, asteroid_field_size.x)
			y = randf_range(-asteroid_field_size.y, asteroid_field_size.y)
			z = randf_range(-asteroid_field_size.z, asteroid_field_size.z)
		asteroids.add_child(new_asteroid)
		new_asteroid.position = Vector3(x, y, z)
		new_asteroid.set_size(randf_range(0.1, 5.0))
		var impulse: Vector3 = Vector3(randf(), randf(), randf()).normalized() * randf()
		var torque: Vector3 = Vector3(randf(), randf(), randf()).normalized() * randf()
		new_asteroid.apply_impulse(impulse)
		new_asteroid.apply_torque_impulse(torque)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		quit_game()


func _process(_delta: float) -> void:
	label.text = str(spaceship.linear_velocity)
	pass
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
	player.velocity = spaceship.linear_velocity
	player.rotation = spaceship.rotation
	player.set_physics_process(true)
	player.disable_collision(false)
	player.position = Vector3(0.0, -0.5, -3.0)
	player.reparent(self)
	player = $Player
	player.show()
