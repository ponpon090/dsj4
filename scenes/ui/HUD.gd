# HUD.gd - Heads-Up Display during gameplay
class_name HUD
extends CanvasLayer

@onready var speed_label: Label = $Panel/VBoxContainer/SpeedLabel
@onready var height_label: Label = $Panel/VBoxContainer/HeightLabel
@onready var distance_label: Label = $Panel/VBoxContainer/DistanceLabel
@onready var wind_label: Label = $Panel/VBoxContainer/WindLabel
@onready var score_label: Label = $Panel/VBoxContainer/ScoreLabel
@onready var timer_label: Label = $Panel/VBoxContainer/TimerLabel
@onready var wind_indicator: ColorRect = $WindIndicator
@onready var jump_button: Button = $JumpButton

signal jump_pressed

var _elapsed_time: float = 0.0
var _counting: bool = false

func _ready():
	jump_button.pressed.connect(_on_jump_pressed)

func _process(delta: float):
	if _counting:
		_elapsed_time += delta
		timer_label.text = "Time: %.2fs" % _elapsed_time

func update_speed(speed_kmh: float):
	speed_label.text = "Speed: %.1f km/h" % speed_kmh

func update_height(height_m: float):
	height_label.text = "Height: %.1f m" % height_m

func update_distance(dist_m: float):
	distance_label.text = "Distance: %.1f m" % dist_m

func update_wind(wind_data: Dictionary):
	var speed = wind_data.get("speed", 0.0)
	var direction = wind_data.get("direction", 0.0)
	var dir_str = "HEAD" if abs(direction) < 15 else ("LEFT" if direction < 0 else "RIGHT")
	wind_label.text = "Wind: %.1f m/s %s" % [speed, dir_str]
	
	# Update wind indicator arrow position
	var indicator_x = (direction / 30.0) * 40.0  # Scale to pixel offset
	wind_indicator.position.x = 120 + indicator_x

func update_score(points: float):
	score_label.text = "Points: %.1f" % points

func start_timer():
	_elapsed_time = 0.0
	_counting = true

func stop_timer():
	_counting = false

func reset():
	_elapsed_time = 0.0
	_counting = false
	update_speed(0)
	update_height(0)
	update_distance(0)
	update_score(0)

func show_jump_button():
	jump_button.visible = true

func hide_jump_button():
	jump_button.visible = false

func _on_jump_pressed():
	jump_pressed.emit()
