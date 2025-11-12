extends Node3D


@onready var player: Player = $Player
@onready var spaceship: Spaceship = $Spaceship
@onready var spaceship_interior: SpaceshipInterior = $"Spaceship Interior"
@onready var label: Label = $Control/Label
@onready var asteroids: Node3D = $Asteroids
@onready var camera: Camera3D = $Camera


const ASTEROID = preload("uid://fpevas20cdlo")


@export var asteroid_field_size: Vector3 = Vector3.ZERO
@export var asteroid_negative_field_size: Vector3 = Vector3.ZERO
@export var asteroid_number: int = 0

var current_ship: RigidBody3D


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
	label.text = str(player.is_in_gravity)
	pass


func quit_game() -> void:
	get_tree().quit()


func player_enter_ship(ship: RigidBody3D) -> void:
	current_ship = ship
	ship.toggle_player_mask(false)
	player.is_in_ship = true
	ship.toggle_camera(true)
	ship.is_controlled = true
	player.velocity = Vector3.ZERO
	player.anim_tree.get_node(player.anim_tree.anim_player).stop()
	player.set_physics_process(false)
	player.disable_collision(true)
	match ship:
		spaceship:
			player.reparent(ship)
			player = ship.get_node("Player")
		spaceship_interior:
			player.reparent(ship.cockpit_chair)
			player = ship.get_node("Cockpit Chair/Player")
	player.position = Vector3.ZERO
	player.hide()


func player_exit_ship(ship: RigidBody3D) -> void:
	current_ship = null
	player.is_in_ship = false
	ship.is_controlled = false
	ship.toggle_camera(false)
	player.reparent(self)
	player.position = ship.exit_point.global_position
	player.velocity = ship.calculated_velocity * 61.5
	match ship:
		spaceship:
			player.look_at(ship.global_position)
		spaceship_interior:
			player.look_at(ship.cockpit_chair.global_position)
	player.disable_collision(false)
	player.set_physics_process(true)
	player = $Player
	player.camera.make_current()
	player.show()
	ship.toggle_player_mask(true)


func _on_player_interaction(collider: RID) -> void:
	if player.is_in_ship:
		player_exit_ship(current_ship)
		return
	var spaceship_rid: RID = spaceship.get_rid()
	var spaceship_interior_chair_rid: RID = spaceship_interior.cockpit_chair.get_rid()
	match collider:
		spaceship_rid:
			player_enter_ship(spaceship)
		spaceship_interior_chair_rid:
			player_enter_ship(spaceship_interior)
		null:
			pass
		_:
			pass
