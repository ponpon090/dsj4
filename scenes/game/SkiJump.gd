# SkiJump.gd - Manages the ski jump hill
class_name SkiJump
extends Node3D

signal jump_ready(takeoff_speed: float, takeoff_angle: float)

var hill_config: HillConfig = null
var skier: Skier = null

# Key positions
var start_position: Vector3 = Vector3.ZERO
var takeoff_position: Vector3 = Vector3.ZERO
var k_point_position: Vector3 = Vector3.ZERO

# Hill geometry refs
@onready var inrun_mesh: MeshInstance3D = $Inrun/InrunMesh
@onready var landing_mesh: MeshInstance3D = $Landing/LandingMesh
@onready var takeoff_marker: Marker3D = $TakeoffMarker
@onready var start_marker: Marker3D = $StartMarker
@onready var k_point_marker: Marker3D = $KPointMarker

func _ready():
	if hill_config == null:
		hill_config = load("res://resources/hills/K90.tres")
	_build_hill()

func _build_hill():
	# Update position markers based on hill config
	start_marker.position = Vector3(0, hill_config.inrun_length * sin(deg_to_rad(hill_config.inrun_angle)), 
								   -hill_config.inrun_length * cos(deg_to_rad(hill_config.inrun_angle)))
	takeoff_marker.position = Vector3(0, 0, 0)
	
	# K-point is on the landing hill
	var landing_dist = hill_config.k_point
	k_point_marker.position = Vector3(0, -landing_dist * sin(deg_to_rad(hill_config.landing_angle)),
								     landing_dist * cos(deg_to_rad(hill_config.landing_angle)))
	
	start_position = start_marker.global_position
	takeoff_position = takeoff_marker.global_position
	k_point_position = k_point_marker.global_position

func set_hill_config(config: HillConfig):
	hill_config = config
	if is_inside_tree():
		_build_hill()

func get_start_position() -> Vector3:
	return start_marker.global_position

func get_takeoff_position() -> Vector3:
	return takeoff_marker.global_position

func calculate_takeoff_speed(inrun_speed: float) -> float:
	return inrun_speed  # Passed directly from inrun

func get_takeoff_angle() -> float:
	return hill_config.takeoff_angle if hill_config else 10.0

func calculate_distance_points(distance: float) -> float:
	if hill_config == null:
		return 0.0
	return hill_config.calculate_distance_points(distance)
