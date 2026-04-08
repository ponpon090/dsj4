extends Node3D

# Main game controller
# Manages the jump lifecycle and scene

@onready var skier: CharacterBody3D = $Skier
@onready var hud = $HUD
@onready var wind_system = $WindSystem
@onready var camera_pivot = $CameraPivot
@onready var jump_camera = $CameraPivot/JumpCamera
@onready var inrun_camera = $InrunCamera
@onready var results_overlay = $ResultsOverlay
@onready var round_label = $HUD/RoundLabel

var hill_config: Dictionary = {}
var current_jump_distance: float = 0.0
var current_style_points: float = 0.0
var is_jump_complete: bool = false
var round_number: int = 1

# Camera modes
enum CameraMode { INRUN, FOLLOW, SIDE, LANDING }
var camera_mode: CameraMode = CameraMode.INRUN

func _ready():
	hill_config = GameManager.get_hill_config()
	
	# Setup wind
	if wind_system:
		wind_system.set_weather(GameManager.current_weather)
		skier.wind_system = wind_system
	
	# Setup HUD
	if hud:
		hud.set_k_point(hill_config["k_point"], hill_config["name"])
		hud.show_instructions("inrun")
		hud.show_phase("inrun")
	
	# Setup skier
	if skier:
		skier.setup_for_hill(hill_config)
		skier.connect("phase_changed", _on_phase_changed)
		skier.connect("jump_started", _on_jump_started)
		skier.connect("landed", _on_landed)
		skier.connect("crashed", _on_crashed)
	
	# Connect wind signal
	if wind_system:
		wind_system.connect("wind_changed", _on_wind_changed)
	
	# Setup camera
	_set_camera_mode(CameraMode.INRUN)
	
	# Round indicator
	if round_label:
		round_label.text = "Seria %d / %d" % [GameManager.current_round, GameManager.total_rounds]
	
	# Hide results initially
	if results_overlay:
		results_overlay.visible = false
		var next_btn = results_overlay.get_node_or_null("Panel/VBox/ButtonRow/NextButton")
		var menu_btn = results_overlay.get_node_or_null("Panel/VBox/ButtonRow/MenuButton")
		if next_btn:
			next_btn.pressed.connect(_on_next_round_pressed)
		if menu_btn:
			menu_btn.pressed.connect(_on_back_to_menu_pressed)

func _process(delta: float):
	if not skier or is_jump_complete:
		return
	
	# Update HUD
	if hud:
		hud.update_speed(skier.get_current_speed_kmh())
		hud.update_height(skier.get_height_above_ground())
		hud.update_distance(skier.get_jump_distance())
		hud.update_style_points(skier.style_points)
		
		if skier.current_phase == skier.Phase.TAKEOFF:
			hud.update_jump_charge(skier.jump_charge, true)
		else:
			hud.update_jump_charge(0.0, false)
		
		if wind_system:
			hud.update_wind(wind_system.wind_speed, wind_system.wind_direction)
			hud.show_wind_indicator(wind_system.wind_speed)
	
	# Update camera
	_update_camera(delta)

func _update_camera(delta: float):
	if not skier:
		return
	
	match camera_mode:
		CameraMode.FOLLOW:
			# Camera follows skier from behind/above
			var target_pos = skier.global_position + Vector3(0, 2, 5)
			if camera_pivot:
				camera_pivot.global_position = lerp(camera_pivot.global_position, target_pos, delta * 5.0)
		CameraMode.SIDE:
			# Side view camera
			if camera_pivot:
				camera_pivot.global_position.z = skier.global_position.z

func _on_phase_changed(phase: String):
	if hud:
		hud.show_phase(phase)
		hud.show_instructions(phase)
	
	match phase:
		"takeoff":
			_set_camera_mode(CameraMode.FOLLOW)
		"flight":
			_set_camera_mode(CameraMode.SIDE)
		"landing":
			_set_camera_mode(CameraMode.LANDING)

func _on_jump_started():
	pass

func _on_landed(distance: float, quality: float):
	current_jump_distance = distance
	is_jump_complete = true
	
	# Calculate scoring
	var distance_points = GameManager.calculate_distance_points(distance, GameManager.current_hill)
	var style_breakdown = skier.get_style_points_breakdown()
	current_style_points = style_breakdown["total"]
	
	# Wind compensation (simplified)
	var wind_comp = 0.0
	if wind_system:
		wind_comp = wind_system.wind_speed * hill_config.get("wind_factor", 7.74) * 0.1
	
	var total_points = distance_points + current_style_points + wind_comp
	
	# Show results
	_show_jump_results(distance, distance_points, current_style_points, total_points, quality)
	
	# Save to leaderboard
	GameManager.add_score(
		GameManager.current_hill,
		GameManager.player_name,
		distance,
		distance_points,
		current_style_points
	)

func _on_crashed():
	is_jump_complete = true
	_show_crash_results()

func _show_jump_results(dist: float, dist_pts: float, style_pts: float, total: float, quality: float):
	if not results_overlay:
		return
	
	results_overlay.visible = true
	var dist_label = results_overlay.get_node_or_null("Panel/VBox/DistanceLabel")
	var pts_label = results_overlay.get_node_or_null("Panel/VBox/PointsLabel")
	var style_label = results_overlay.get_node_or_null("Panel/VBox/StyleLabel")
	var total_label = results_overlay.get_node_or_null("Panel/VBox/TotalLabel")
	var quality_label = results_overlay.get_node_or_null("Panel/VBox/QualityLabel")
	
	if dist_label:
		dist_label.text = "Odległość: %.1f m" % dist
		# Color based on K-point
		if dist >= hill_config["k_point"]:
			dist_label.modulate = Color(0.2, 1.0, 0.4)
		else:
			dist_label.modulate = Color(1.0, 0.8, 0.2)
	
	if pts_label:
		pts_label.text = "Punkty odległość: %.1f" % dist_pts
	if style_label:
		style_label.text = "Punkty styl: %.1f" % style_pts
	if total_label:
		total_label.text = "SUMA: %.1f pkt" % total
		total_label.modulate = Color(1.0, 0.95, 0.2)
	
	if quality_label:
		var q_text = "Lądowanie: "
		if quality > 0.85:
			q_text += "TELEMARK! ★★★"
			quality_label.modulate = Color(0.2, 1.0, 0.8)
		elif quality > 0.65:
			q_text += "Dobre ★★"
			quality_label.modulate = Color(0.5, 1.0, 0.5)
		elif quality > 0.4:
			q_text += "Przeciętne ★"
			quality_label.modulate = Color(1.0, 0.8, 0.3)
		else:
			q_text += "Słabe"
			quality_label.modulate = Color(1.0, 0.4, 0.4)
		quality_label.text = q_text

func _show_crash_results():
	if not results_overlay:
		return
	results_overlay.visible = true
	var dist_label = results_overlay.get_node_or_null("Panel/VBox/DistanceLabel")
	var total_label = results_overlay.get_node_or_null("Panel/VBox/TotalLabel")
	
	if dist_label:
		dist_label.text = "UPADEK! - Dyskwalifikacja"
		dist_label.modulate = Color(1.0, 0.2, 0.2)
	if total_label:
		total_label.text = "0.0 pkt"

func _set_camera_mode(mode: CameraMode):
	camera_mode = mode
	if inrun_camera:
		inrun_camera.current = (mode == CameraMode.INRUN)
	if jump_camera:
		jump_camera.current = (mode != CameraMode.INRUN)

func _on_next_round_pressed():
	GameManager.current_round += 1
	if GameManager.current_round > GameManager.total_rounds:
		# Go to final results
		get_tree().change_scene_to_file("res://scenes/Results.tscn")
	else:
		# Reload game for next round
		get_tree().reload_current_scene()

func _on_back_to_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_to_menu_pressed()
