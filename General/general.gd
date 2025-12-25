extends Node3D


@onready var player: Player = $Player
@onready var spaceship: Spaceship = $Spaceship
@onready var spaceship_interior: SpaceshipInterior = $"Spaceship Interior"
@onready var label: Label = $Control/VBoxContainer/Label
@onready var label_2: Label = $Control/VBoxContainer/Label2

@onready var noise_size: int = 64
@onready var noise_modifier: int = 10
@onready var asteroid_field_offset: Vector3 = Vector3(-noise_size, -noise_size, -noise_size) * noise_modifier / 2


const WARP_OUT_EFFECT = preload("uid://6cfsvsikdy02")
const ASTEROID = preload("uid://fpevas20cdlo")


var current_station: Station
var current_ship: RigidBody3D

var current_gate: WarpGate
var picked_gate: WarpGate

var warping_to: String


var is_loading: bool = false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	current_station = $"Red Station"
	
	generate_asteroids()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("esc"):
		quit_game()
	if Input.is_action_just_pressed("special"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	label.text = player.anim_playback.get_current_node()
	label_2.text = str(player.up_marker.global_position - player.global_position)
	
	if is_loading:
		var res: Array = []
		ResourceLoader.load_threaded_get_status(warping_to, res)
		if res[0] == 1.0:
			begin_warp()


func generate_asteroids() -> void:
	var texture := NoiseTexture3D.new()
	texture.depth = noise_size
	texture.height = noise_size
	texture.width = noise_size
	var noise := FastNoiseLite.new()
	noise.frequency = 0.1
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.seed = 18
	texture.noise = noise
	
	await texture.changed
	var z := 0
	for i in texture.get_data():
		for x in texture.width:
			for y in texture.height:
				if i.get_pixel(x, y).get_luminance() > 0.8:
					var random_offset := Vector3(randf(), randf(), randf()) * 5
					spawn_asteroid(2.0 * i.get_pixel(x, y).get_luminance(), Vector3(x, y, z) * noise_modifier + asteroid_field_offset + random_offset, Vector3(randf(), randf(), randf()).normalized() * randf(), Vector3(randf(), randf(), randf()).normalized() * randf())
		z += 1


func spawn_asteroid(size: float, asteroid_position: Vector3, impulse: Vector3, torque: Vector3) -> void:
	var new_asteroid: Asteroid = ASTEROID.instantiate()
	current_station.add_child(new_asteroid)
	new_asteroid.position = asteroid_position
	new_asteroid.set_size(size)
	new_asteroid.apply_impulse(impulse)
	new_asteroid.apply_torque_impulse(torque)


func begin_warp() -> void:
	print_debug("Finished loading new station")
	is_loading = false
	var station_scene: PackedScene = ResourceLoader.load_threaded_get(warping_to)
	var new_station: Station = station_scene.instantiate()
	add_child(new_station)
	for i in get_tree().get_nodes_in_group(&"warp_gates"):
		if ResourceLoader.get_resource_uid(i.station) == ResourceLoader.get_resource_uid(current_station.get_station_path(current_station)):
			picked_gate = i
			break
	if picked_gate == null:
		push_error("Could not find warp gate with path ", warping_to)
		breakpoint
	current_station.warp_to.disconnect(_on_station_warp_to)
	
	await get_tree().create_timer(1.5).timeout
	var new_warp_tube: Node3D = WARP_OUT_EFFECT.instantiate()
	add_child(new_warp_tube)
	new_warp_tube.mesh.material.albedo_color = new_station.station_color
	new_warp_tube.global_rotation = current_gate.global_rotation
	new_warp_tube.global_position = current_gate.warp_in_cylinder.global_position
	current_ship.reparent(new_warp_tube)
	current_gate.disappear()
	new_warp_tube.appear()
	await get_tree().create_timer(3.0).timeout
	current_station.queue_free()
	new_warp_tube.global_position = picked_gate.warp_out_marker.global_position
	new_warp_tube.look_at(picked_gate.warp_out_look_at_marker.global_position)
	current_ship.reparent(self)
	new_warp_tube.disappear()
	new_station.warp_to.connect(_on_station_warp_to)
	current_station = new_station
	generate_asteroids()
	current_ship.set_physics_process(true)
	current_ship.toggle_collision(true)
	current_ship.push_ship_forward()
	print_debug("Finished warping")


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
			if spaceship_interior != null:
				spaceship_interior.queue_free()
		spaceship_interior:
			player.reparent(ship.cockpit_chair)
			player = ship.get_node("Cockpit Chair/Player")
			if spaceship != null:
				spaceship.queue_free()
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
	var spaceship_rid: RID
	if spaceship != null:
		spaceship_rid = spaceship.get_rid()
	var spaceship_interior_chair_rid: RID
	if spaceship_interior != null:
		spaceship_interior_chair_rid = spaceship_interior.cockpit_chair.get_rid()
	match collider:
		spaceship_rid:
			player_enter_ship(spaceship)
		spaceship_interior_chair_rid:
			player_enter_ship(spaceship_interior)
		null:
			pass
		_:
			pass


func _on_station_warp_to(to_station: NodePath, from_gate: WarpGate) -> void:
	ResourceLoader.load_threaded_request(to_station)
	warping_to = to_station
	current_gate = from_gate
	is_loading = true
	print_debug("Started loading new station, ", ResourceUID.uid_to_path(to_station))
