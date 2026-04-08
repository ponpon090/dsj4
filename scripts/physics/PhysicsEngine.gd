# PhysicsEngine.gd - Handles realistic ski jump physics
class_name PhysicsEngine
extends Node

const GRAVITY: float = 9.81  # m/s²
const AIR_DENSITY: float = 1.225  # kg/m³
const SKIER_MASS: float = 80.0  # kg (skier + equipment)
const DRAG_COEFFICIENT: float = 0.4  # aerodynamic drag
const LIFT_COEFFICIENT: float = 0.6  # aerodynamic lift
const FRONTAL_AREA: float = 0.5  # m² frontal area

# Calculate drag force
static func calculate_drag(velocity: Vector3) -> Vector3:
	var speed = velocity.length()
	if speed < 0.001:
		return Vector3.ZERO
	var drag_magnitude = 0.5 * AIR_DENSITY * DRAG_COEFFICIENT * FRONTAL_AREA * speed * speed
	return -velocity.normalized() * drag_magnitude / SKIER_MASS

# Calculate lift force during flight based on angle of attack
# body_pitch: skier's pitch angle in degrees (positive = nose up)
static func calculate_lift(velocity: Vector3, body_pitch: float) -> Vector3:
	var speed = velocity.length()
	if speed < 0.001:
		return Vector3.ZERO
	# Angle of attack = difference between body pitch and velocity pitch angle
	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	var vel_pitch_deg = rad_to_deg(atan2(-velocity.y, horiz_speed))
	var angle_of_attack = clamp(body_pitch - vel_pitch_deg, -30.0, 30.0)
	var lift_magnitude = 0.5 * AIR_DENSITY * LIFT_COEFFICIENT * FRONTAL_AREA * speed * speed
	return Vector3.UP * lift_magnitude * sin(deg_to_rad(angle_of_attack)) / SKIER_MASS

# Simulate slope acceleration
static func calculate_slope_acceleration(slope_angle_deg: float, friction: float = 0.03) -> float:
	var slope_rad = deg_to_rad(slope_angle_deg)
	return GRAVITY * (sin(slope_rad) - friction * cos(slope_rad))

# Apply wind effect on trajectory
static func apply_wind(velocity: Vector3, wind_velocity: Vector3, dt: float) -> Vector3:
	var wind_effect = wind_velocity * 0.1  # Scale wind influence
	return velocity + wind_effect * dt
