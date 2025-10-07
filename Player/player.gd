extends CharacterBody3D


class_name Player


signal shooting(pos: Vector3, direction: Vector3)


@export var speed: float = 5.0
@export var jump_velocity: float = 5.0
@export var acceleration: float = 15.0
@export var max_speed: float = 8.0
@export var sprint_speed: float = 4.0
@export var air_control: float = 0.5
@export var air_friction: float = 0.1
@export var gravity_control: float = 0.15
@export var floor_friction: float = 2.0

@export var zoom_limit: float = 5.0
@export var zoom_force: float = 0.2

@export_range(0.1, 2.0, 0.01) var mouse_sensitivity: float = 1.0
@export var in_gravity_mouse_sensitivity: float = 0.07
@export var max_head_angle: float = 75.0
@export var min_head_angle: float = -75.0

@export var bounce_factor: float = 1.0

@onready var camera_gymbal: Marker3D = $"Camera Gymbal"
@onready var right_marker: Marker3D = $"Right Marker"
@onready var up_marker: Marker3D = $"Up Marker"
@onready var shoot_reference: Marker3D = $"Camera Gymbal/Shoot Reference"
@onready var position_offset: SpringArm3D = $"Camera Gymbal/Position Offset"

@onready var coyote_timer: Timer = $"Coyote Timer"
@onready var shoot_timer: Timer = $"Shoot Timer"

@onready var model: Node3D = $Model

@onready var anim_tree: AnimationTree = $Model/AnimationTree
@onready var anim_playback: AnimationNodeStateMachinePlayback = $Model/AnimationTree.get(&"parameters/state_machine/playback")
@onready var anim_locomotion_playback: AnimationNodeStateMachinePlayback = $Model/AnimationTree.get(&"parameters/state_machine/locomotion/playback")
@onready var anim_jumping_playback: AnimationNodeStateMachinePlayback = $Model/AnimationTree.get(&"parameters/state_machine/jumping/playback")
@onready var anim_path_running: StringName = &"parameters/state_machine/locomotion/running/blend_position"
@onready var anim_path_walking: StringName = &"parameters/state_machine/locomotion/walking/blend_position"
@onready var anim_path_backwards: StringName = &"parameters/state_machine/locomotion/backwards/blend_position"
@onready var step_sound: AudioStreamPlayer3D = $"Step Sound"

var direction: Vector3 = Vector3.ZERO

var anim_movement: Vector2 = Vector2.ZERO

var target_rot: Vector2 = Vector2.ZERO

var checkpoint: Vector3 = Vector3(0.0, 3.0, 0.0)

var additional_speed: float = 0.0

var _is_in_gravity: bool = false

var is_in_gravity: bool = false:
	get:
		return _is_in_gravity
	set(v):
		_is_in_gravity = v
		is_in_gravity = v
		if v:
			motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
		toggle_gravity(v)

var is_moving: bool = false
var is_running: bool = false
var is_coyote_time: bool = false
var has_started_jumping: bool = false
var has_jumped: bool = false
var has_landed: bool = false
var can_shoot: bool = true
var has_stepped: bool = false


func _ready() -> void:
	model.hide()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if is_in_gravity:
			target_rot.x += deg_to_rad(-event.screen_relative.y) * in_gravity_mouse_sensitivity
			target_rot.y += deg_to_rad(-event.screen_relative.x) * in_gravity_mouse_sensitivity
			target_rot = clamp(target_rot, Vector2(-90.0, -90.0), Vector2(90.0, 90.0))
		else:
			rotation.y += deg_to_rad(-event.screen_relative.x) * mouse_sensitivity
			
			var final_x_rotation = camera_gymbal.rotation.x + deg_to_rad(-event.screen_relative.y) * mouse_sensitivity
			if final_x_rotation > deg_to_rad(min_head_angle) and final_x_rotation < deg_to_rad(max_head_angle):
				camera_gymbal.rotation.x = final_x_rotation
	if event is InputEventMouseButton and Input.mouse_mode == Input.MouseMode.MOUSE_MODE_CAPTURED:
		var e := event as InputEventMouseButton
		if e.is_pressed() and e.button_index == MOUSE_BUTTON_LEFT and can_shoot:
			can_shoot = false
			shoot_timer.start()
			var shooting_direction: = shoot_reference.global_position - camera_gymbal.global_position
			shooting.emit(shoot_reference.global_position, shooting_direction)
		elif e.is_pressed() and e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			position_offset.spring_length = clampf(position_offset.spring_length + zoom_force, 0.0, zoom_limit)
			if position_offset.spring_length > 0.0:
				model.show()
		elif e.is_pressed() and e.button_index == MOUSE_BUTTON_WHEEL_UP:
			position_offset.spring_length = clampf(position_offset.spring_length - zoom_force, 0.0, zoom_limit)
			if position_offset.spring_length < 0.2:
				position_offset.spring_length = 0.0
				model.hide()


func _physics_process(delta: float) -> void:
	#region Floor/landing detection and gravity.
	
	if is_on_floor():
		if anim_playback.get_current_node() == &"falling":
			anim_playback.travel(&"locomotion")
		if !has_landed:
			has_landed = true
			if has_jumped:
				has_jumped = false
				anim_jumping_playback.travel(&"jumping_down")
		else:
			if is_running:
				anim_locomotion_playback.travel(&"running")
	else:
		if !is_coyote_time and has_landed:
			is_coyote_time = true
			has_landed = false
			coyote_timer.start()
		velocity += get_gravity() * delta
		if is_in_gravity:
			has_jumped = false
			has_landed = false
			anim_playback.travel(&"floating")
		else:
			if anim_playback.get_current_node() in [&"locomotion", &"floating"]:
				anim_playback.travel(&"falling")
	
	#endregion

	#region Handle jump.
	
	if Input.is_action_just_pressed(&"move_jump") and (is_on_floor() or is_coyote_time) and !is_in_gravity:
		anim_playback.travel(&"jumping")
	if Input.is_action_pressed(&"move_jump"):
		if has_started_jumping and velocity.y < jump_velocity:
			velocity.y += jump_velocity / 10.0
		else:
			has_started_jumping = false
	else:
		has_started_jumping = false
	
	#endregion
	
	#region Rotation (Z) in zero gravity
	
	if Input.is_action_pressed(&"rotate_clockwise") and is_in_gravity:
		rotation.z -= delta / 2
	if Input.is_action_pressed(&"rotate_counter_clockwise") and is_in_gravity:
		rotation.z += delta / 2
	
	#endregion

	#region Locomotion and animation handling
	
	var input_dir := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if input_dir == Vector2.ZERO:
		is_moving = false
	else:
		is_moving = true
	
	anim_movement = anim_movement.move_toward(input_dir, delta * 5)
	
	if anim_movement.y > 0 and anim_locomotion_playback.get_current_node() != &"backwards":
		anim_locomotion_playback.travel(&"backwards")
	elif anim_movement.y <= 0 and anim_locomotion_playback.get_current_node() == &"backwards":
		if is_running:
			anim_locomotion_playback.travel(&"running")
		else:
			anim_locomotion_playback.travel(&"walking")
	
	anim_tree.set(anim_path_backwards, anim_movement.x)
	anim_tree.set(anim_path_walking, anim_movement)
	anim_tree.set(anim_path_running, anim_movement)
	
	if Input.is_action_pressed(&"move_sprint") and !is_in_gravity and anim_movement.y <= 0:
		if !is_running:
			is_running = true
			anim_locomotion_playback.travel(&"running")
		additional_speed = move_toward(additional_speed, sprint_speed, delta * acceleration / 2)
	elif is_on_floor():
		additional_speed = move_toward(additional_speed, 0.0, delta * acceleration / 2)
	
	if !Input.is_action_pressed(&"move_sprint") and is_running:
		is_running = false
		anim_locomotion_playback.travel(&"walking")
	
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		if is_in_gravity:
			velocity = velocity.move_toward(direction * max_speed, delta * acceleration * gravity_control)
		else:
			var new_velocity: Vector2 = Vector2(velocity.x, velocity.z)
			var new_direction: Vector2 = Vector2(direction.x, direction.z)
			if is_on_floor():
				new_velocity = new_velocity.move_toward(new_direction * (max_speed + additional_speed), delta * acceleration)
			else:
				new_velocity = new_velocity.move_toward(new_direction * (max_speed + additional_speed), delta * acceleration * air_control)
			velocity.x = new_velocity.x
			velocity.z = new_velocity.y
	else:
		if is_in_gravity:
			velocity = velocity.move_toward(Vector3.ZERO, delta * acceleration * gravity_control)
		else:
			var new_velocity: Vector2 = Vector2(velocity.x, velocity.z)
			if is_on_floor():
				new_velocity = new_velocity.move_toward(Vector2.ZERO, delta * acceleration * floor_friction)
			else:
				new_velocity = new_velocity.move_toward(Vector2.ZERO, delta * acceleration * air_friction)
			velocity.x = new_velocity.x
			velocity.z = new_velocity.y
	
	#endregion

	#region Handling rotation interpolation while in zero gravity
	
	if is_in_gravity:
		rotate_object_local(Vector3.RIGHT, target_rot.x * delta)
		rotate_object_local(Vector3.UP, target_rot.y * delta)
		target_rot.x -= target_rot.x * delta * 2.0
		target_rot.y -= target_rot.y * delta * 2.0
		pass
	
	#endregion

	#region Bounce off collisions while in zero gravity
	
	var col := move_and_slide()
	if col and is_in_gravity:
		velocity = velocity.bounce(get_last_slide_collision().get_normal()) * bounce_factor
	
	#endregion


func jump() -> void:
	has_started_jumping = true
	velocity.y = jump_velocity * 0.5


func toggle_gravity(on: bool) -> void:
	if on:
		get_tree().create_tween().tween_property(self, "rotation:x", camera_gymbal.rotation.x, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		get_tree().create_tween().tween_property(camera_gymbal, "rotation:x", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	else:
		get_tree().create_tween().tween_property(camera_gymbal, "rotation:x", rotation.x, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		get_tree().create_tween().tween_property(self, "rotation:x", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		get_tree().create_tween().tween_property(self, "rotation:z", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func reset() -> void:
	velocity = Vector3.ZERO
	global_position = checkpoint


func stop_jumping() -> void:
	has_jumped = true
	if is_on_floor():
		has_jumped = false
		anim_jumping_playback.travel(&"jumping_down")


func play_step() -> void:
	if has_stepped:
		has_stepped = false
		step_sound.pitch_scale = 1.0
	else:
		has_stepped = true
		step_sound.pitch_scale = 0.8
	step_sound.play()


func _on_coyote_timer_timeout() -> void:
	is_coyote_time = false


func _on_shoot_timer_timeout() -> void:
	can_shoot = true


func _on_junk_detector_body_entered(body: Node3D) -> void:
	pass
	#if body is Junk:
		#velocity -= velocity * 0.5
		#body.play_sound()
