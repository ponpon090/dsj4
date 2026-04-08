# Game.gd - Main game scene controller
class_name Game
extends Node3D

enum GameState { MENU, HILL_SELECT, INRUN, JUMP, RESULTS, LEADERBOARD }

const HILLS = [
	"res://resources/hills/K60.tres",
	"res://resources/hills/K90.tres",
	"res://resources/hills/K120.tres",
	"res://resources/hills/K185.tres",
]

var game_state: GameState = GameState.INRUN
var current_hill_idx: int = 1  # Default K90
var current_hill: HillConfig = null
var player_name: String = "Player"
var jump_count: int = 0

# Scoring
var last_distance: float = 0.0
var last_distance_pts: float = 0.0
var last_style_pts: float = 0.0

@onready var skier: Skier = $Skier
@onready var ski_jump: SkiJump = $SkiJump
@onready var hud: HUD = $HUD
@onready var results_ui: Results = $ResultsUI
@onready var wind_system: WindSystem = $WindSystem
@onready var camera: Camera3D = $Camera3D
@onready var hill_select_ui: Control = $HillSelectUI

func _ready():
	current_hill = load(HILLS[current_hill_idx])
	ski_jump.set_hill_config(current_hill)
	
	# Connect signals
	skier.landed.connect(_on_skier_landed)
	skier.jump_started.connect(_on_jump_started)
	wind_system.wind_changed.connect(_on_wind_changed)
	results_ui.try_again_pressed.connect(_on_try_again)
	results_ui.menu_pressed.connect(_on_menu_pressed)
	hud.jump_pressed.connect(_on_jump_input)
	
	_start_inrun()

func _process(delta: float):
	if game_state == GameState.INRUN or game_state == GameState.JUMP:
		_update_hud()

func _input(event: InputEvent):
	if game_state == GameState.INRUN:
		if event.is_action_pressed("jump"):
			_on_jump_input()

func _start_inrun():
	game_state = GameState.INRUN
	results_ui.hide_results()
	hud.reset()
	hud.show_jump_button()
	hud.start_timer()
	
	var start_pos = ski_jump.get_start_position()
	var takeoff_pos = ski_jump.get_takeoff_position()
	skier.reset()
	skier.start_inrun(start_pos, takeoff_pos)
	
	_update_camera_inrun()

func _on_jump_input():
	if game_state != GameState.INRUN:
		return
	game_state = GameState.JUMP
	hud.hide_jump_button()
	
	var takeoff_speed = skier.speed
	var takeoff_angle = ski_jump.get_takeoff_angle()
	skier.do_jump(takeoff_speed, takeoff_angle)
	
	_update_camera_flight()

func _on_jump_started():
	hud.start_timer()

func _on_skier_landed(distance: float, quality: float):
	game_state = GameState.RESULTS
	hud.stop_timer()
	
	last_distance = distance
	last_distance_pts = current_hill.calculate_distance_points(distance)
	last_style_pts = current_hill.calculate_style_points(quality)
	
	var total_pts = last_distance_pts + last_style_pts
	hud.update_score(total_pts)
	
	_show_results()

func _show_results():
	await get_tree().create_timer(1.0).timeout
	
	var lb_scene = load("res://scenes/ui/Leaderboard.tscn")
	var lb = lb_scene.instantiate() as Leaderboard
	var is_record = lb.is_high_score(last_distance_pts + last_style_pts)
	lb.queue_free()
	
	results_ui.show_results(last_distance, last_distance_pts, last_style_pts, is_record)
	
	# Auto-save score
	var lb2 = lb_scene.instantiate() as Leaderboard
	add_child(lb2)
	lb2.save_score(player_name, last_distance, last_distance_pts + last_style_pts, 
				   current_hill.hill_name if current_hill else "K90")
	lb2.queue_free()

func _on_try_again():
	jump_count += 1
	_start_inrun()

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")

func _on_wind_changed(wind_data: Dictionary):
	skier.set_wind(wind_data["vector"])
	hud.update_wind(wind_data)

func _update_hud():
	hud.update_speed(skier.get_speed_kmh())
	hud.update_height(skier.get_height_above_takeoff())
	hud.update_distance(skier.get_current_distance())

func _update_camera_inrun():
	if camera:
		camera.position = Vector3(15, 5, 0)
		camera.look_at(skier.global_position, Vector3.UP)

func _update_camera_flight():
	if camera:
		camera.position = Vector3(20, 10, -20)
