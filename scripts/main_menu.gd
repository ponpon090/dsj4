extends Control

# Main Menu controller

@onready var hill_option: OptionButton = $CenterContainer/Panel/VBox/HillOption
@onready var difficulty_option: OptionButton = $CenterContainer/Panel/VBox/DifficultyOption
@onready var weather_option: OptionButton = $CenterContainer/Panel/VBox/WeatherOption
@onready var player_name_input: LineEdit = $CenterContainer/Panel/VBox/PlayerNameInput
@onready var tournament_check: CheckButton = $CenterContainer/Panel/VBox/TournamentCheck
@onready var start_button: Button = $CenterContainer/Panel/VBox/StartButton
@onready var leaderboard_button: Button = $CenterContainer/Panel/VBox/LeaderboardButton
@onready var version_label: Label = $VersionLabel

func _ready():
	# Populate hill options
	if hill_option:
		hill_option.clear()
		hill_option.add_item("K-60 Mała skocznia")
		hill_option.add_item("K-90 Normalna skocznia")
		hill_option.add_item("K-120 Duża skocznia")
		hill_option.add_item("K-185 Skocznia lotów")
		hill_option.selected = 1  # default: normal hill
	
	# Difficulty
	if difficulty_option:
		difficulty_option.clear()
		difficulty_option.add_item("Łatwy")
		difficulty_option.add_item("Średni")
		difficulty_option.add_item("Trudny")
		difficulty_option.selected = 1
	
	# Weather
	if weather_option:
		weather_option.clear()
		weather_option.add_item("☀ Słonecznie")
		weather_option.add_item("☁ Pochmurno")
		weather_option.add_item("❄ Śnieg")
		weather_option.add_item("🌫 Mgła")
		weather_option.selected = 0
	
	# Player name
	if player_name_input:
		player_name_input.text = GameManager.player_name
	
	if version_label:
		version_label.text = "DSJ4 v1.0 | Godot 4.x"
	
	# Connect signals
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if leaderboard_button:
		leaderboard_button.pressed.connect(_on_leaderboard_pressed)

func _on_start_pressed():
	# Save settings to GameManager
	var hills = ["small_hill", "normal_hill", "large_hill", "flying_hill"]
	var difficulties = ["easy", "medium", "hard"]
	var weathers = ["sunny", "cloudy", "snow", "fog"]
	
	if hill_option:
		GameManager.current_hill = hills[hill_option.selected]
	if difficulty_option:
		GameManager.current_difficulty = difficulties[difficulty_option.selected]
	if weather_option:
		GameManager.current_weather = weathers[weather_option.selected]
	if player_name_input and player_name_input.text.strip_edges() != "":
		GameManager.player_name = player_name_input.text.strip_edges()
	if tournament_check:
		GameManager.tournament_mode = tournament_check.button_pressed
		GameManager.total_rounds = 2 if GameManager.tournament_mode else 1
	
	GameManager.reset_session()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_leaderboard_pressed():
	get_tree().change_scene_to_file("res://scenes/Results.tscn")

func _input(event):
	if event.is_action_pressed("ui_accept"):
		_on_start_pressed()
