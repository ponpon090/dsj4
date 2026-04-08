# Skier.gd - Controls the ski jumper
class_name Skier
extends CharacterBody3D

signal jump_started
signal landed(distance: float, quality: float)

enum State { IDLE, INRUN, FLYING, LANDING, FALLEN }

var state: State = State.IDLE
var jump_distance: float = 0.0
var jump_quality: float = 0.0
var speed: float = 0.0
var crouch_factor: float = 0.0  # 0=upright, 1=fully crouched
var body_pitch: float = 15.0    # flight body pitch angle in degrees (positive = nose up)

# Physics vars
var inrun_start_pos: Vector3 = Vector3.ZERO
var takeoff_pos: Vector3 = Vector3.ZERO
var _wind_velocity: Vector3 = Vector3.ZERO
var _air_time: float = 0.0
var _horizontal_dist: float = 0.0

@onready var mesh: MeshInstance3D = $SkierMesh
@onready var collision: CollisionShape3D = $Collision

func _ready():
	state = State.IDLE

func _physics_process(delta: float):
	match state:
		State.INRUN:
			_process_inrun(delta)
		State.FLYING:
			_process_flying(delta)
		State.LANDING:
			_process_landing(delta)

func _process_inrun(delta: float):
	# Handle crouch input
	if Input.is_action_pressed("crouch"):
		crouch_factor = min(crouch_factor + delta * 2.0, 1.0)
	else:
		crouch_factor = max(crouch_factor - delta * 2.0, 0.0)
	
	# Speed builds up based on slope
	var slope_accel = PhysicsEngine.calculate_slope_acceleration(33.0) * (0.8 + crouch_factor * 0.4)
	speed += slope_accel * delta
	speed = min(speed, 30.0)  # max speed ~108 km/h
	
	# Move along slope direction
	var slope_dir = -transform.basis.z
	velocity = slope_dir * speed
	move_and_slide()

func _process_flying(delta: float):
	_air_time += delta
	
	# Apply gravity
	velocity.y -= PhysicsEngine.GRAVITY * delta
	
	# Apply aerodynamic drag
	var drag = PhysicsEngine.calculate_drag(velocity)
	velocity += drag * delta
	
	# Apply aerodynamic lift
	var lift = PhysicsEngine.calculate_lift(velocity, body_pitch)
	velocity += lift * delta
	
	# Apply wind
	velocity = PhysicsEngine.apply_wind(velocity, _wind_velocity, delta)
	
	# Handle balance input (lean_left increases pitch / nose-up, lean_right decreases pitch)
	if Input.is_action_pressed("lean_left"):
		body_pitch = min(body_pitch + delta * 5.0, 30.0)
	elif Input.is_action_pressed("lean_right"):
		body_pitch = max(body_pitch - delta * 5.0, 5.0)
	
	# Calculate horizontal distance from takeoff
	var diff = global_position - takeoff_pos
	_horizontal_dist = Vector2(diff.x, diff.z).length()
	
	move_and_slide()
	
	# Check if landed
	if is_on_floor():
		_on_land()

func _process_landing(delta: float):
	# Decelerate after landing
	velocity = velocity.move_toward(Vector3.ZERO, 20.0 * delta)
	velocity.y -= PhysicsEngine.GRAVITY * delta
	move_and_slide()

func start_inrun(start_position: Vector3, takeoff_position: Vector3):
	state = State.INRUN
	global_position = start_position
	inrun_start_pos = start_position
	takeoff_pos = takeoff_position
	speed = 5.0
	velocity = Vector3.ZERO

func do_jump(takeoff_velocity: float, takeoff_angle_deg: float):
	state = State.FLYING
	_air_time = 0.0
	_horizontal_dist = 0.0
	
	var angle_rad = deg_to_rad(takeoff_angle_deg)
	velocity.y = takeoff_velocity * sin(angle_rad)
	velocity.z = -takeoff_velocity * cos(angle_rad)
	
	jump_started.emit()

func set_wind(wind_vec: Vector3):
	_wind_velocity = wind_vec

func _on_land():
	state = State.LANDING
	# Calculate jump quality based on body pitch at landing
	jump_quality = clamp(0.5 + (body_pitch - 10.0) / 40.0, 0.0, 1.0)
	
	# Distance is horizontal distance from takeoff
	var diff = global_position - takeoff_pos
	jump_distance = Vector2(diff.x, diff.z).length()
	
	landed.emit(jump_distance, jump_quality)

func reset():
	state = State.IDLE
	velocity = Vector3.ZERO
	speed = 0.0
	body_pitch = 15.0
	crouch_factor = 0.0
	jump_distance = 0.0
	jump_quality = 0.0
	_air_time = 0.0
	_horizontal_dist = 0.0

func get_speed_kmh() -> float:
	return velocity.length() * 3.6

func get_height_above_takeoff() -> float:
	return global_position.y - takeoff_pos.y

func get_current_distance() -> float:
	return _horizontal_dist
