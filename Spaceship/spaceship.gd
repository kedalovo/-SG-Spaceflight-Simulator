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

@onready var sprint_timer: Timer = $"Timers/Sprint Timer"
@onready var forward_timer: Timer = $"Timers/Forward Timer"
@onready var back_timer: Timer = $"Timers/Back Timer"
@onready var left_timer: Timer = $"Timers/Left Timer"
@onready var right_timer: Timer = $"Timers/Right Timer"
@onready var down_timer: Timer = $"Timers/Down Timer"
@onready var clockwise_timer: Timer = $"Timers/Clockwise Timer"
@onready var counter_clockwise_timer: Timer = $"Timers/Counter Clockwise Timer"
@onready var jump_timer: Timer = $"Timers/Jump Timer"

@onready var exit_point: Marker3D = $"Exit Point"

@export var max_head_angle: float = 75.0
@export var min_head_angle: float = -75.0
@export var mouse_sensitivity: float = 0.07
@export var rotation_speed: float = 0.2
@export var zoom_force: float = 0.2
@export var zoom_max: float = 7.0
@export var zoom_min: float = 2.0
@export var acceleration_time: float = 2.0

const SPEED = 2.0
const ASCEND_VELOCITY = 5.0


var gravity_areas: Array = []

var target_rot: Vector2 = Vector2.ZERO

var calculated_velocity: Vector3 = Vector3.ZERO
var last_position: Vector3 = Vector3.ZERO

var is_controlled: bool = false
var is_free_looking: bool = false
var is_in_gravity: bool = true

var has_started_sprint: bool = false
var has_started_forward: bool = false
var has_started_back: bool = false
var has_started_left: bool = false
var has_started_right: bool = false
var has_started_down: bool = false
var has_started_clockwise: bool = false
var has_started_counter_clockwise: bool = false
var has_started_jump: bool = false


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
		#region Inputs
		if Input.is_action_pressed("move_sprint"):
			if !has_started_sprint:
				has_started_sprint = true
				sprint_timer.start(acceleration_time)
			else:
				apply_central_impulse((top_marker.global_position - global_position) * delta * ASCEND_VELOCITY * mass * (acceleration_time - sprint_timer.time_left) / acceleration_time)
		else:
			has_started_sprint = false
		if Input.is_action_pressed("move_forward"):
			if !has_started_forward:
				has_started_forward = true
				forward_timer.start(acceleration_time)
			else:
				apply_central_impulse((front_marker.global_position - global_position) * delta * SPEED * mass * (acceleration_time - forward_timer.time_left) / acceleration_time)
		else:
			has_started_forward = false
		if Input.is_action_pressed("move_back"):
			if !has_started_back:
				has_started_back = true
				back_timer.start(acceleration_time)
			else:
				apply_central_impulse((back_marker.global_position - global_position) * delta * SPEED * mass * (acceleration_time - back_timer.time_left) / acceleration_time)
		else:
			has_started_back = false
		if Input.is_action_pressed("move_left"):
			if !has_started_left:
				has_started_left = true
				left_timer.start(acceleration_time)
			else:
				apply_central_impulse((left_marker.global_position - global_position) * delta * SPEED * mass * (acceleration_time - left_timer.time_left) / acceleration_time)
		else:
			has_started_left = false
		if Input.is_action_pressed("move_right"):
			if !has_started_right:
				has_started_right = true
				right_timer.start(acceleration_time)
			else:
				apply_central_impulse((right_marker.global_position - global_position) * delta * SPEED * mass * (acceleration_time - right_timer.time_left) / acceleration_time)
		else:
			has_started_right = false
		if Input.is_action_pressed("move_down"):
			if !has_started_down:
				has_started_down = true
				down_timer.start(acceleration_time)
			else:
				apply_central_impulse((bottom_marker.global_position - global_position) * delta * SPEED * mass * (acceleration_time - down_timer.time_left) / acceleration_time)
		else:
			has_started_down = false
		if Input.is_action_pressed("rotate_clockwise"):
			if !has_started_clockwise:
				has_started_clockwise = true
				clockwise_timer.start(acceleration_time)
			else:
				apply_torque_impulse((global_position - back_marker.global_position) * rotation_speed * delta * mass * (acceleration_time - clockwise_timer.time_left) / acceleration_time)
		else:
			has_started_clockwise = false
		if Input.is_action_pressed("rotate_counter_clockwise"):
			if !has_started_counter_clockwise:
				has_started_counter_clockwise = true
				counter_clockwise_timer.start(acceleration_time)
			else:
				apply_torque_impulse((global_position - front_marker.global_position) * rotation_speed * delta * mass * (acceleration_time - counter_clockwise_timer.time_left) / acceleration_time)
		else:
			has_started_counter_clockwise = false
		if Input.is_action_pressed("move_jump"):
			if !has_started_jump:
				has_started_jump = true
				jump_timer.start(acceleration_time)
			else:
				apply_central_impulse(-linear_velocity.normalized() * delta * ASCEND_VELOCITY * mass * (acceleration_time - jump_timer.time_left) / acceleration_time)
		else:
			has_started_jump = false
		
		#endregion
		
		apply_torque_impulse((global_position - left_marker.global_position) * target_rot.x * delta * mass)
		apply_torque_impulse((global_position - bottom_marker.global_position) * target_rot.y * delta * mass)
		target_rot.x -= target_rot.x * delta * 2.0
		target_rot.y -= target_rot.y * delta * 2.0
		
	calculated_velocity = global_position - last_position
	last_position = global_position


func toggle_camera(on: bool) -> void:
	camera.current = on


func toggle_player_mask(on: bool) -> void:
	if on:
		get_tree().create_timer(0.1).timeout.connect(func(): call_deferred("set_collision_mask_value", 2, on))
	else:
		call_deferred("set_collision_mask_value", 2, on)


func toggle_collision(on: bool) -> void:
	call_deferred("set_collision_layer_value", 3, on)
	call_deferred("set_collision_mask_value", 1, on)
	call_deferred("set_collision_mask_value", 2, on)
	call_deferred("set_collision_mask_value", 4, on)
	call_deferred("set_collision_mask_value", 5, on)


func push_ship_forward() -> void:
	apply_central_impulse((front_marker.global_position - global_position) * SPEED * mass)
