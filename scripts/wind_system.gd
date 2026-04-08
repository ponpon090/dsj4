extends Node3D

# Wind system that affects the skier during flight
# Positive wind = tailwind (helps), Negative wind = headwind (hurts)

signal wind_changed(wind_speed: float, wind_direction: String)

var wind_speed: float = 0.0  # m/s, positive = tailwind, negative = headwind
var wind_direction: String = "→"
var wind_angle: float = 0.0  # radians, 0 = from behind (tailwind)
var wind_turbulence: float = 0.0

# Wind configuration
var max_wind_speed: float = 4.0  # m/s
var wind_change_speed: float = 0.5  # how fast wind changes
var turbulence_intensity: float = 0.3

var _target_wind: float = 0.0
var _change_timer: float = 0.0
var _change_interval: float = 3.0  # seconds between wind changes

func _ready():
	_generate_new_wind()

func _process(delta: float):
	_change_timer += delta
	
	if _change_timer >= _change_interval:
		_change_timer = 0.0
		_generate_new_wind()
	
	# Smoothly interpolate to target wind
	wind_speed = lerp(wind_speed, _target_wind, wind_change_speed * delta)
	
	# Add turbulence
	wind_turbulence = randf_range(-turbulence_intensity, turbulence_intensity)
	
	# Update direction indicator
	_update_direction()

func _generate_new_wind():
	_target_wind = randf_range(-max_wind_speed, max_wind_speed)
	_change_interval = randf_range(2.0, 5.0)
	wind_changed.emit(wind_speed, wind_direction)

func _update_direction():
	if wind_speed > 0.5:
		wind_direction = "→"  # tailwind (good)
	elif wind_speed < -0.5:
		wind_direction = "←"  # headwind (bad)
	else:
		wind_direction = "↔"  # calm

func get_effective_wind() -> float:
	return wind_speed + wind_turbulence

func get_wind_force_vector() -> Vector3:
	# Wind affects Z-axis (forward/back) with 0.15 factor and Y-axis (lift) with 0.10 factor.
	# These scale wind m/s to approximate aerodynamic force in Newtons per kg of skier mass.
	var effective = get_effective_wind()
	return Vector3(0, effective * 0.1, effective * 0.15)

func set_weather(weather: String):
	match weather:
		"sunny":
			max_wind_speed = 2.0
			turbulence_intensity = 0.1
		"cloudy":
			max_wind_speed = 3.5
			turbulence_intensity = 0.2
		"snow":
			max_wind_speed = 4.0
			turbulence_intensity = 0.4
		"fog":
			max_wind_speed = 1.5
			turbulence_intensity = 0.1
		"stormy":
			max_wind_speed = 6.0
			turbulence_intensity = 0.8

func get_wind_indicator_arrows() -> String:
	var strength = abs(wind_speed)
	var arrows = ""
	if strength < 1.0:
		arrows = "○"
	elif strength < 2.0:
		arrows = wind_direction
	elif strength < 3.5:
		arrows = wind_direction + wind_direction
	else:
		arrows = wind_direction + wind_direction + wind_direction
	return arrows
