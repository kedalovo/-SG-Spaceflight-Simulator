extends RigidBody3D

class_name Asteroid


@onready var collision: CollisionShape3D = $Collision
@onready var mesh: CSGBox3D = $Mesh


func set_size(new_size: float) -> void:
	new_size = clampf(new_size, 0.1, 5.0)
	collision.shape = BoxShape3D.new()
	collision.shape.size = Vector3(new_size, new_size, new_size)
	mesh.size = Vector3(new_size, new_size, new_size)
	mass = new_size
