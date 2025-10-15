extends RigidBody3D


@onready var camera: Camera3D = $Model/Camera
@onready var front_marker: Marker3D = $"Markers/Front Marker"
@onready var back_marker: Marker3D = $"Markers/Back Marker"
@onready var left_marker: Marker3D = $"Markers/Left Marker"
@onready var right_marker: Marker3D = $"Markers/Right Marker"
@onready var top_marker: Marker3D = $"Markers/Top Marker"
@onready var bottom_marker: Marker3D = $"Markers/Bottom Marker"


@export var mouse_sensitivity: float = 0.07
@export var rotation_speed: float = 0.2

const SPEED = 2.0
const ASCEND_VELOCITY = 5.0


var target_rot: Vector2 = Vector2.ZERO

var is_controlled: bool = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and is_controlled:
		target_rot.x += deg_to_rad(-event.screen_relative.y) * mouse_sensitivity
		target_rot.y += deg_to_rad(-event.screen_relative.x) * mouse_sensitivity
		target_rot = clamp(target_rot, Vector2(-90.0, -90.0), Vector2(90.0, 90.0))


func _physics_process(delta: float) -> void:
	if is_controlled:
		if Input.is_action_pressed("move_sprint"):
			apply_central_impulse((top_marker.global_position - global_position) * delta * ASCEND_VELOCITY)
		if Input.is_action_pressed("move_forward"):
			apply_central_impulse((front_marker.global_position - global_position) * delta * SPEED)
		if Input.is_action_pressed("move_back"):
			apply_central_impulse((back_marker.global_position - global_position) * delta * SPEED)
		if Input.is_action_pressed("move_left"):
			apply_central_impulse((left_marker.global_position - global_position) * delta * SPEED)
		if Input.is_action_pressed("move_right"):
			apply_central_impulse((right_marker.global_position - global_position) * delta * SPEED)
		if Input.is_action_pressed("move_down"):
			apply_central_impulse((bottom_marker.global_position - global_position) * delta * SPEED)
		if Input.is_action_pressed("rotate_clockwise"):
			apply_torque_impulse((global_position - back_marker.global_position) * rotation_speed * delta)
		if Input.is_action_pressed("rotate_counter_clockwise"):
			apply_torque_impulse((global_position - front_marker.global_position) * rotation_speed * delta)
		
		apply_torque_impulse((global_position - left_marker.global_position) * target_rot.x * delta)
		apply_torque_impulse((global_position - bottom_marker.global_position) * target_rot.y * delta)
		#rotate_object_local(Vector3.LEFT, target_rot.x * delta)
		#rotate_object_local(Vector3.UP, target_rot.y * delta)
		target_rot.x -= target_rot.x * delta * 2.0
		target_rot.y -= target_rot.y * delta * 2.0


func toggle_camera(on: bool) -> void:
	camera.current = on
