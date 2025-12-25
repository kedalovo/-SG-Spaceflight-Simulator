extends Station


@onready var label: Label = $Control/Label
@onready var asteroids: Node3D = $Asteroids
@onready var camera: Camera3D = $Camera


const ASTEROID = preload("uid://fpevas20cdlo")


@export var asteroid_field_size: Vector3 = Vector3.ZERO
@export var asteroid_negative_field_size: Vector3 = Vector3.ZERO
@export var asteroid_number: int = 0

var current_ship: RigidBody3D


func _ready() -> void:
	pass
	#for i in asteroid_number:
		#var new_asteroid: Asteroid = ASTEROID.instantiate()
		#var x = randf_range(-asteroid_field_size.x, asteroid_field_size.x)
		#var y = randf_range(-asteroid_field_size.y, asteroid_field_size.y)
		#var z = randf_range(-asteroid_field_size.z, asteroid_field_size.z)
		#var an = asteroid_negative_field_size
		#while (x > -an.x and x < an.x) and (y > -an.y and y < an.y) and (z > -an.z and z < an.z):
			#x = randf_range(-asteroid_field_size.x, asteroid_field_size.x)
			#y = randf_range(-asteroid_field_size.y, asteroid_field_size.y)
			#z = randf_range(-asteroid_field_size.z, asteroid_field_size.z)
		#asteroids.add_child(new_asteroid)
		#new_asteroid.position = Vector3(x, y, z)
		#new_asteroid.set_size(randf_range(0.1, 5.0))
		#var impulse: Vector3 = Vector3(randf(), randf(), randf()).normalized() * randf()
		#var torque: Vector3 = Vector3(randf(), randf(), randf()).normalized() * randf()
		#new_asteroid.apply_impulse(impulse)
		#new_asteroid.apply_torque_impulse(torque)
