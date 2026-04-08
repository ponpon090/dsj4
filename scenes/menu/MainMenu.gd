# MainMenu.gd - Main menu of DSJ4
class_name MainMenu
extends Control

signal start_game_pressed
signal leaderboard_pressed
signal settings_pressed

@onready var start_btn: Button = $CenterContainer/VBoxContainer/StartButton
@onready var leaderboard_btn: Button = $CenterContainer/VBoxContainer/LeaderboardButton
@onready var settings_btn: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_btn: Button = $CenterContainer/VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var bg_anim: AnimationPlayer = $BackgroundAnim

var _anim_time: float = 0.0

func _ready():
	start_btn.pressed.connect(func(): start_game_pressed.emit())
	leaderboard_btn.pressed.connect(func(): leaderboard_pressed.emit())
	settings_btn.pressed.connect(func(): settings_pressed.emit())
	quit_btn.pressed.connect(func(): get_tree().quit())
	
	if bg_anim and bg_anim.has_animation("bg_float"):
		bg_anim.play("bg_float")

func _process(delta: float):
	# Animate title
	_anim_time += delta
	if title_label:
		title_label.modulate = Color(
			1.0,
			0.8 + sin(_anim_time * 2.0) * 0.2,
			0.2 + sin(_anim_time * 1.5) * 0.1,
			1.0
		)
