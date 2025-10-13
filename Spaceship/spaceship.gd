extends RigidBody3D


@onready var camera: Camera3D = $Model/Camera


const SPEED = 20.0
const ASCEND_VELOCITY = 15.0

var is_controlled: bool = false


func _physics_process(delta: float) -> void:
	if is_controlled:
		if Input.is_action_pressed("move_jump"):
			apply_central_impulse(Vector3.UP * delta * ASCEND_VELOCITY)
		if Input.is_action_pressed("move_forward"):
			apply_central_impulse(Vector3.FORWARD * delta * SPEED)
		if Input.is_action_pressed("move_back"):
			apply_central_impulse(Vector3.BACK * delta * SPEED)
		if Input.is_action_pressed("move_left"):
			apply_central_impulse(Vector3.LEFT * delta * SPEED)
		if Input.is_action_pressed("move_right"):
			apply_central_impulse(Vector3.RIGHT * delta * SPEED)


func toggle_camera(on: bool) -> void:
	camera.current = on
