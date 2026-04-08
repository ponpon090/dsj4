# HillConfig.gd - Resource class for hill configuration
class_name HillConfig
extends Resource

@export var hill_name: String = "K90"
@export var k_point: float = 90.0  # K-point in meters
@export var critical_point: float = 99.0  # Critical point (HS)
@export var hill_size: float = 90.0  # Hill size HS
@export var inrun_length: float = 110.0  # Inrun/slope length
@export var inrun_angle: float = 33.0  # Inrun angle in degrees
@export var takeoff_angle: float = 10.0  # Takeoff ramp angle
@export var landing_angle: float = 33.5  # Landing hill angle
@export var table_height: float = 0.0
@export var judges_points: float = 60.0  # Base judge points at K-point
@export var wind_factor: float = 1.0  # Wind compensation factor

# Calculate style points based on jump quality
func calculate_style_points(jump_quality: float) -> float:
	# jump_quality: 0.0-1.0
	return 60.0 * jump_quality

# Calculate distance points
func calculate_distance_points(distance: float) -> float:
	var diff = distance - k_point
	# 1.8 points per meter beyond K-point, -1.8 per meter below
	return judges_points + diff * 1.8
