extends Node3D


@onready var mesh: CSGCylinder3D = $Mesh


func _process(delta: float) -> void:
	mesh.material.uv1_offset.y += delta * 0.5
	mesh.material.uv1_offset.x -= delta * 0.1


func appear() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(mesh, "material:albedo_color", Color(mesh.material.albedo_color, 1.0), 3.0)


func disappear() -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(mesh, "material:albedo_color", Color(mesh.material.albedo_color, 0.0), 3.0)
