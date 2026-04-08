extends CharacterBody3D

# Main skier physics controller
# Handles all phases: inrun, takeoff, flight, landing

signal phase_changed(new_phase: String)
signal jump_started
signal landed(distance: float, quality: float)
signal crashed

enum Phase {
	INRUN,      # Going down the ramp
	TAKEOFF,    # At the table, charging jump
	FLIGHT,     # In the air
	LANDING,    # Touching down
	FINISHED    # Jump complete
}

var current_phase: Phase = Phase.INRUN

# Physics parameters
var velocity: Vector3 = Vector3.ZERO
var speed: float = 0.0
var height: float = 0.0
var distance: float = 0.0

# Jump mechanics
var jump_charge: float = 0.0      # 0-1, how much power in jump
var jump_charged: bool = false
var jump_released: bool = false
var air_time: float = 0.0

# Flight control
var lean_angle: float = 0.0       # -1 to 1 (back/forward)
var balance: float = 0.0          # -1 to 1 (left/right)
var aerodynamic_position: float = 0.0  # 0-1 (tuck/V-style)
var v_style_angle: float = 0.0    # angle of V-style

# Scoring
var style_points: float = 20.0    # max 20, deducted for errors
var balance_penalty: float = 0.0
var has_telemark: bool = false
var landing_quality: float = 0.0

# Hill config (set by game manager)
var hill_config: Dictionary = {}
var k_point: float = 90.0

# Inrun path
var inrun_progress: float = 0.0  # 0 to 1 along ramp
var inrun_speed: float = 0.0
var ramp_end_position: Vector3 = Vector3.ZERO
var ramp_direction: Vector3 = Vector3(0, 0, -1)

# Wind reference
var wind_system: Node = null

# Takeoff timing
var takeoff_window: float = 0.3   # seconds at table
var takeoff_timer: float = 0.0
var optimal_timing: bool = false

# Physics constants
const GRAVITY: float = 9.81
const AIR_DENSITY: float = 1.225
const SKIER_MASS: float = 85.0    # kg
const DRAG_COEFFICIENT: float = 0.4
const LIFT_COEFFICIENT: float = 0.8
const FRONTAL_AREA: float = 0.45  # m²

# Landing detection
var landing_start_height: float = 0.0
var has_left_ramp: bool = false
var takeoff_velocity: Vector3 = Vector3.ZERO

func _ready():
	up_direction = Vector3.UP

func setup_for_hill(config: Dictionary):
	hill_config = config
	k_point = config["k_point"]
	inrun_speed = 0.0
	inrun_progress = 0.0
	current_phase = Phase.INRUN
	jump_charge = 0.0
	jump_charged = false
	jump_released = false
	style_points = 20.0
	air_time = 0.0
	distance = 0.0
	has_telemark = false
	balance_penalty = 0.0

func _physics_process(delta: float):
	match current_phase:
		Phase.INRUN:
			_process_inrun(delta)
		Phase.TAKEOFF:
			_process_takeoff(delta)
		Phase.FLIGHT:
			_process_flight(delta)
		Phase.LANDING:
			_process_landing(delta)

func _process_inrun(delta: float):
	# Accelerate down the ramp
	var ramp_angle_rad = deg_to_rad(hill_config.get("alpha", 65.0))
	var gravity_component = GRAVITY * sin(ramp_angle_rad)
	
	# Friction on ramp (ski friction is very low)
	var friction = 0.03 * GRAVITY * cos(ramp_angle_rad)
	inrun_speed += (gravity_component - friction) * delta
	inrun_speed = min(inrun_speed, 30.0)  # Cap at 108 km/h (30 m/s × 3.6)
	
	speed = inrun_speed
	inrun_progress += delta * 0.4  # normalized progress
	
	# Move along ramp
	var ramp_dir = Vector3(0, -sin(ramp_angle_rad), -cos(ramp_angle_rad))
	velocity = ramp_dir * inrun_speed
	
	# Check if reached table
	if inrun_progress >= 1.0:
		_enter_takeoff()

func _enter_takeoff():
	current_phase = Phase.TAKEOFF
	takeoff_timer = 0.0
	emit_signal("phase_changed", "takeoff")

func _process_takeoff(delta: float):
	takeoff_timer += delta
	
	# Player charges jump by holding space
	if Input.is_action_pressed("jump_charge"):
		jump_charge = min(jump_charge + delta * 2.5, 1.0)
	
	# Auto-trigger if window missed
	if takeoff_timer >= takeoff_window + 0.2:
		if not jump_released:
			_execute_jump(0.3)  # Poor timing
	
	# Jump release
	if Input.is_action_just_released("jump_charge") or jump_charge >= 1.0:
		# Calculate timing quality
		var timing_quality = 1.0 - abs(jump_charge - 0.85) / 0.85
		timing_quality = clamp(timing_quality, 0.0, 1.0)
		_execute_jump(timing_quality)

func _execute_jump(timing_quality: float):
	if jump_released:
		return
	jump_released = true
	
	var ramp_angle = deg_to_rad(hill_config.get("ramp_angle", 10.5))
	var jump_power = inrun_speed * (0.5 + timing_quality * 0.5)
	
	# Initial flight velocity
	var forward_speed = inrun_speed * cos(ramp_angle)
	var vertical_speed = jump_power * sin(deg_to_rad(30.0 + timing_quality * 10.0))
	
	velocity = Vector3(0, vertical_speed, -forward_speed)
	takeoff_velocity = velocity
	
	current_phase = Phase.FLIGHT
	has_left_ramp = true
	landing_start_height = global_position.y
	
	emit_signal("phase_changed", "flight")
	emit_signal("jump_started")

func _process_flight(delta: float):
	air_time += delta
	
	# Player controls
	var lean_input = 0.0
	if Input.is_action_pressed("lean_forward"):
		lean_input = 1.0
	elif Input.is_action_pressed("lean_backward"):
		lean_input = -1.0
	
	var balance_input = 0.0
	if Input.is_action_pressed("balance_left"):
		balance_input = -1.0
	elif Input.is_action_pressed("balance_right"):
		balance_input = 1.0
	
	lean_angle = lerp(lean_angle, lean_input, delta * 3.0)
	balance = lerp(balance, balance_input, delta * 3.0)
	
	# V-style: gradually open skis for maximum lift
	aerodynamic_position = lerp(aerodynamic_position, 1.0, delta * 1.5)
	v_style_angle = aerodynamic_position * 30.0  # degrees
	
	# Style penalties
	if abs(balance) > 0.5:
		balance_penalty += delta * 2.0
		style_points = max(0.0, 20.0 - balance_penalty)
	
	# Calculate aerodynamics
	var current_speed = velocity.length()
	speed = current_speed * 3.6  # to km/h
	
	# Lift force (V-style creates lift)
	var lift_factor = 0.3 + aerodynamic_position * 0.7
	var lift_area = FRONTAL_AREA * lift_factor
	var lift_force = 0.5 * AIR_DENSITY * current_speed * current_speed * LIFT_COEFFICIENT * lift_area
	
	# Drag force (aerodynamic drag)
	var drag_area = FRONTAL_AREA * (1.2 - aerodynamic_position * 0.4)
	var drag_force = 0.5 * AIR_DENSITY * current_speed * current_speed * DRAG_COEFFICIENT * drag_area
	
	# Lean affects aerodynamics
	lift_force *= (1.0 + lean_angle * 0.15)
	drag_force *= (1.0 - lean_angle * 0.1)
	
	# Wind effect
	var wind_force = Vector3.ZERO
	if wind_system:
		wind_force = wind_system.get_wind_force_vector()
	
	# Apply forces
	var gravity_force = Vector3(0, -GRAVITY * SKIER_MASS, 0)
	var lift_vec = Vector3(0, lift_force, 0)
	var drag_vec = -velocity.normalized() * drag_force
	var balance_force = Vector3(balance * -2.0, 0, 0)
	
	var total_force = gravity_force + lift_vec + drag_vec + wind_force * SKIER_MASS + balance_force
	velocity += (total_force / SKIER_MASS) * delta
	
	# Move using move_and_collide for proper physics integration
	var motion = velocity * delta
	var collision = move_and_collide(motion)
	if collision:
		# Landed on slope geometry - trigger landing
		if air_time > 0.3:
			_initiate_landing()
		return
	
	height = position.y - landing_start_height
	distance = -position.z  # negative Z is forward
	
	# Face direction of travel
	if velocity.length() > 0.1:
		var look_dir = velocity.normalized()
		look_dir.x = 0  # keep upright
		if look_dir != Vector3.ZERO:
			rotation.x = atan2(-look_dir.y, -look_dir.z)
	
	# Check for landing
	_check_landing()

func _check_landing():
	# Simple landing detection based on height below takeoff
	# In real implementation, this would be a collision with the slope
	var slope_height = _calculate_slope_height_at(distance)
	
	if height <= slope_height and air_time > 0.3:
		_initiate_landing()

func _calculate_slope_height_at(dist: float) -> float:
	# Calculate the slope height at given distance
	# The landing hill follows a specific mathematical profile
	var knoll_angle = deg_to_rad(hill_config.get("knoll_angle", 34.0))
	var landing_angle = deg_to_rad(hill_config.get("landing_angle", 36.0))
	var k_pt = hill_config.get("k_point", 90.0)
	
	if dist < 10.0:
		return -dist * tan(knoll_angle) * 0.3
	elif dist <= k_pt:
		return -dist * tan(landing_angle) * 0.7
	else:
		return -(k_pt * tan(landing_angle) * 0.7) - (dist - k_pt) * tan(deg_to_rad(25.0)) * 0.5

func _initiate_landing():
	current_phase = Phase.LANDING
	
	# Calculate landing quality
	var landing_speed = velocity.length()
	var impact_angle = atan2(-velocity.y, -velocity.z)
	var ideal_angle = deg_to_rad(hill_config.get("landing_angle", 36.0))
	
	# Landing quality based on angle match
	var angle_diff = abs(impact_angle - ideal_angle)
	landing_quality = clamp(1.0 - angle_diff / deg_to_rad(20.0), 0.0, 1.0)
	
	# Telemark landing (space bar at right moment)
	if Input.is_action_pressed("telemark"):
		has_telemark = true
		landing_quality = min(landing_quality + 0.2, 1.0)
	
	# Style points based on landing quality
	var landing_style_bonus = landing_quality * 4.0
	style_points = clamp(style_points - (1.0 - landing_quality) * 8.0 + landing_style_bonus, 0.0, 20.0)
	
	# Check if crashed (very bad angle)
	if landing_quality < 0.1 or abs(balance) > 0.9:
		emit_signal("crashed")
		style_points = 0.0
	else:
		emit_signal("landed", distance, landing_quality)
	
	emit_signal("phase_changed", "landing")
	current_phase = Phase.FINISHED

func get_style_points_breakdown() -> Dictionary:
	var points = {}
	var base = 20.0
	
	# Landing position (max 4 * 5 judges = 20)
	if has_telemark:
		points["landing"] = 18.5 + landing_quality * 1.5
	elif landing_quality > 0.7:
		points["landing"] = 14.0 + landing_quality * 4.0
	else:
		points["landing"] = landing_quality * 14.0
	
	points["flight"] = max(0.0, base - balance_penalty)
	points["total"] = clamp((points["landing"] + points["flight"]) / 2.0, 0.0, 20.0)
	
	return points

func get_jump_distance() -> float:
	return max(0.0, distance)

func get_current_speed_kmh() -> float:
	return velocity.length() * 3.6

func get_height_above_ground() -> float:
	return max(0.0, height - _calculate_slope_height_at(distance))
