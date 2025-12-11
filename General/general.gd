extends Node3D


@onready var player: Player = $Player
@onready var spaceship: Spaceship = $Spaceship
@onready var spaceship_interior: SpaceshipInterior = $"Spaceship Interior"


var current_station: Station
var current_ship: RigidBody3D

var warping_to: String

var is_loading: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_station = $"Red Station"


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		quit_game()
	if Input.is_action_just_pressed("special"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if is_loading:
		var res: Array = []
		ResourceLoader.load_threaded_get_status(warping_to, res)
		if res[0] == 1.0:
			complete_warp()


func complete_warp() -> void:
	is_loading = false
	var station_scene: PackedScene = ResourceLoader.load_threaded_get(warping_to)
	var new_station: Station = station_scene.instantiate()
	current_station.warp_to.disconnect(_on_station_warp_to)
	add_child(new_station)
	current_station.queue_free()
	new_station.warp_to.connect(_on_station_warp_to)
	current_station = new_station


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


func _on_station_warp_to(to_station: NodePath) -> void:
	ResourceLoader.load_threaded_request(to_station)
	warping_to = to_station
	is_loading = true
