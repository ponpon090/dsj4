# WindSystem.gd - Manages wind simulation
class_name WindSystem
extends Node

signal wind_changed(wind_data: Dictionary)

var current_wind_speed: float = 0.0  # m/s
var current_wind_direction: float = 0.0  # degrees, 0 = headwind
var wind_variation: float = 0.5  # variation per update
var update_interval: float = 0.5  # seconds between wind updates

var _timer: float = 0.0
var _target_wind_speed: float = 0.0
var _target_wind_direction: float = 0.0

func _ready():
	_generate_new_wind()

func _process(delta: float):
	_timer += delta
	if _timer >= update_interval:
		_timer = 0.0
		_generate_new_wind()
	
	# Smoothly interpolate to target wind
	current_wind_speed = lerp(current_wind_speed, _target_wind_speed, 0.1)
	current_wind_direction = lerp_angle(deg_to_rad(current_wind_direction), deg_to_rad(_target_wind_direction), 0.1)
	current_wind_direction = rad_to_deg(current_wind_direction)
	
	wind_changed.emit(get_wind_data())

func _generate_new_wind():
	_target_wind_speed = randf_range(0.0, 4.0)  # 0-4 m/s
	_target_wind_direction = randf_range(-30.0, 30.0)  # -30 to 30 degrees

func get_wind_vector() -> Vector3:
	var dir_rad = deg_to_rad(current_wind_direction)
	return Vector3(sin(dir_rad), 0, cos(dir_rad)) * current_wind_speed

func get_wind_data() -> Dictionary:
	return {
		"speed": current_wind_speed,
		"direction": current_wind_direction,
		"vector": get_wind_vector()
	}

func get_wind_description() -> String:
	var dir_str = "Head" if abs(current_wind_direction) < 15 else ("Left" if current_wind_direction < 0 else "Right")
	return "%.1f m/s %s" % [current_wind_speed, dir_str]
