extends Node3D


class_name WarpGate


signal initiate_warp(station: NodePath, gate: WarpGate)


@onready var warp_sprite: Sprite3D = $"Warp Sprite"
@onready var warp_in_cylinder: CSGCylinder3D = $"Warp In Cylinder"
@onready var destination_marker: Marker3D = $"Destination Marker"
@onready var look_at_marker: Marker3D = $"LookAt Marker"
@onready var mesh: CSGTorus3D = $Mesh
@onready var warp_out_marker: Marker3D = $"Warp Out Marker"
@onready var warp_out_look_at_marker: Marker3D = $"Warp Out LookAt Marker"


@export_color_no_alpha var warp_color: Color = Color.WHITE
@export_file() var station: String


var was_rotated: bool = false


func _ready() -> void:
	var new_material := StandardMaterial3D.new()
	new_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	new_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var new_noise := FastNoiseLite.new()
	new_noise.frequency = 0.003
	new_noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	new_noise.fractal_octaves = 10
	new_noise.fractal_gain = 0.7
	new_noise.fractal_weighted_strength = 0.2
	var new_noise_texture := NoiseTexture2D.new()
	new_noise_texture.noise = new_noise
	new_noise_texture.generate_mipmaps = false
	new_noise_texture.seamless = true
	new_noise_texture.in_3d_space = true
	new_material.albedo_texture = new_noise_texture
	new_material.albedo_color = warp_color
	warp_in_cylinder.material = new_material
	
	warp_sprite.modulate = warp_color


func _process(delta: float) -> void:
	warp_in_cylinder.material.uv1_offset.y -= delta * 0.5
	warp_in_cylinder.material.uv1_offset.x += delta * 0.1
	mesh.rotate_z(delta / 4.0)


func start_warp() -> void:
	initiate_warp.emit(station, self)


func appear() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(warp_in_cylinder, "material:albedo_color", Color(mesh.material.albedo_color, 1.0), 3.0)


func disappear() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(warp_in_cylinder, "material:albedo_color", Color(mesh.material.albedo_color, 0.0), 3.0)


func _on_area_body_entered(body: Node3D) -> void:
	if body is SpaceshipInterior:
		warp_in_cylinder.show()
		body.linear_velocity = Vector3.ZERO
		body.set_physics_process(false)
		body.toggle_collision(false)
		if was_rotated:
			destination_marker.rotate_object_local(Vector3.UP, deg_to_rad(180))
			was_rotated = false
		#get_tree().create_tween().tween_property(body, "global_position", destination_marker.global_position, 0.5).finished.connect(func(): body.look_at(look_at_marker.global_position); start_warp())
		var tween := get_tree().create_tween()
		tween.set_parallel()
		tween.tween_property(body, "global_position", destination_marker.global_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(body, "global_rotation", destination_marker.global_rotation, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		start_warp()
	if body is Spaceship:
		warp_in_cylinder.show()
		body.linear_velocity = Vector3.ZERO
		body.set_physics_process(false)
		body.toggle_collision(false)
		#get_tree().create_tween().tween_property(body, "global_position", destination_marker.global_position, 0.5).finished.connect(func(): body.look_at(warp_sprite.global_position); start_warp())
		if !was_rotated:
			destination_marker.rotate_object_local(Vector3.UP, deg_to_rad(180))
			was_rotated = true
		var tween := get_tree().create_tween()
		tween.set_parallel()
		tween.tween_property(body, "global_position", destination_marker.global_position, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(body, "global_rotation", destination_marker.global_rotation, 1.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		start_warp()


func _on_area_body_exited(body: Node3D) -> void:
	if body is Spaceship or body is SpaceshipInterior:
		pass
