extends RigidBody3D


class_name Spaceship


@onready var front_marker: Marker3D = $"Markers/Front Marker"
@onready var back_marker: Marker3D = $"Markers/Back Marker"
@onready var left_marker: Marker3D = $"Markers/Left Marker"
@onready var right_marker: Marker3D = $"Markers/Right Marker"
@onready var top_marker: Marker3D = $"Markers/Top Marker"
@onready var bottom_marker: Marker3D = $"Markers/Bottom Marker"
@onready var sphere: CSGSphere3D = $Sphere
@onready var camera: Camera3D = $"Model/Camera Gymbal/Camera Offset/Camera"
@onready var camera_gymbal: Node3D = $"Model/Camera Gymbal"
@onready var camera_offset: SpringArm3D = $"Model/Camera Gymbal/Camera Offset"


@export var max_head_angle: float = 75.0
@export var min_head_angle: float = -75.0
@export var mouse_sensitivity: float = 0.07
@export var rotation_speed: float = 0.2
@export var zoom_force: float = 0.2
@export var zoom_max: float = 7.0
@export var zoom_min: float = 2.0

const SPEED = 2.0
const ASCEND_VELOCITY = 5.0


var target_rot: Vector2 = Vector2.ZERO

var calculated_velocity: Vector3 = Vector3.ZERO
var last_position: Vector3 = Vector3.ZERO

var is_controlled: bool = false
var is_free_looking: bool = false
var is_in_gravity: bool = false


func _ready() -> void:
	last_position = global_position


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and is_controlled:
		if is_in_gravity:
			if is_free_looking:
				camera_gymbal.rotation.y += deg_to_rad(-event.screen_relative.x) * mouse_sensitivity
				var final_x_rotation = camera_gymbal.rotation.x + deg_to_rad(event.screen_relative.y) * mouse_sensitivity
				if final_x_rotation > deg_to_rad(min_head_angle) and final_x_rotation < deg_to_rad(max_head_angle):
					camera_gymbal.rotation.x = final_x_rotation
			else:
				target_rot.x += deg_to_rad(-event.screen_relative.y) * mouse_sensitivity
				target_rot.y += deg_to_rad(-event.screen_relative.x) * mouse_sensitivity
				target_rot = clamp(target_rot, Vector2(-90.0, -90.0), Vector2(90.0, 90.0))
		else:
			if is_free_looking:
				camera_gymbal.rotate_object_local(Vector3.RIGHT, event.screen_relative.y * 0.001)
				camera_gymbal.rotate_object_local(Vector3.UP, -event.screen_relative.x * 0.001)
			else:
				target_rot.x += deg_to_rad(-event.screen_relative.y) * mouse_sensitivity
				target_rot.y += deg_to_rad(-event.screen_relative.x) * mouse_sensitivity
				target_rot = clamp(target_rot, Vector2(-90.0, -90.0), Vector2(90.0, 90.0))
	if event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and is_controlled:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_offset.spring_length = clampf(camera_offset.spring_length + zoom_force, zoom_min, zoom_max)
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_offset.spring_length = clampf(camera_offset.spring_length - zoom_force, zoom_min, zoom_max)
			if camera_offset.spring_length < 1.2:
				camera_offset.spring_length = 1.0
	if Input.is_action_pressed("free_look"):
		is_free_looking = true
	else:
		is_free_looking = false
	if Input.is_action_just_released("free_look"):
		var tween: Tween = get_tree().create_tween()
		tween.tween_property(camera_gymbal, "rotation", Vector3.ZERO, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if is_controlled:
		if Input.is_action_pressed("move_sprint"):
			apply_central_impulse((top_marker.global_position - global_position) * delta * ASCEND_VELOCITY * mass)
		if Input.is_action_pressed("move_forward"):
			apply_central_impulse((front_marker.global_position - global_position) * delta * SPEED * mass)
		if Input.is_action_pressed("move_back"):
			apply_central_impulse((back_marker.global_position - global_position) * delta * SPEED * mass)
		if Input.is_action_pressed("move_left"):
			apply_central_impulse((left_marker.global_position - global_position) * delta * SPEED * mass)
		if Input.is_action_pressed("move_right"):
			apply_central_impulse((right_marker.global_position - global_position) * delta * SPEED * mass)
		if Input.is_action_pressed("move_down"):
			apply_central_impulse((bottom_marker.global_position - global_position) * delta * SPEED * mass)
		if Input.is_action_pressed("rotate_clockwise"):
			apply_torque_impulse((global_position - back_marker.global_position) * rotation_speed * delta * mass)
		if Input.is_action_pressed("rotate_counter_clockwise"):
			apply_torque_impulse((global_position - front_marker.global_position) * rotation_speed * delta * mass)
		
		apply_torque_impulse((global_position - left_marker.global_position) * target_rot.x * delta * mass)
		apply_torque_impulse((global_position - bottom_marker.global_position) * target_rot.y * delta * mass)
		target_rot.x -= target_rot.x * delta * 2.0
		target_rot.y -= target_rot.y * delta * 2.0
	calculated_velocity = global_position - last_position
	if calculated_velocity > Vector3.ONE:
		print(global_position)
		print(last_position)
		print(calculated_velocity)
		breakpoint
	last_position = global_position


func toggle_camera(on: bool) -> void:
	camera.current = on
