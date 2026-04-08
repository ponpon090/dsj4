extends CanvasLayer

# HUD - Heads Up Display
# Shows: speed, height, distance, wind, points, phase indicator

@onready var speed_label: Label = $HUDPanel/VBox/SpeedRow/SpeedValue
@onready var height_label: Label = $HUDPanel/VBox/HeightRow/HeightValue
@onready var distance_label: Label = $HUDPanel/VBox/DistanceRow/DistanceValue
@onready var wind_label: Label = $HUDPanel/VBox/WindRow/WindValue
@onready var wind_arrow: Label = $HUDPanel/VBox/WindRow/WindArrow
@onready var points_label: Label = $HUDPanel/VBox/PointsRow/PointsValue
@onready var phase_label: Label = $PhaseIndicator/PhaseLabel
@onready var jump_bar: ProgressBar = $JumpChargeBar
@onready var style_bar: ProgressBar = $StyleBar/StyleProgress
@onready var wind_bar: HSlider = $WindIndicator/WindBar
@onready var k_point_indicator: Label = $KPointIndicator
@onready var instructions_label: Label = $Instructions

# Animation
var _phase_display_timer: float = 0.0

func _ready():
	jump_bar.visible = false
	phase_label.visible = false

func update_speed(speed_kmh: float):
	if speed_label:
		speed_label.text = "%.0f km/h" % speed_kmh

func update_height(height_m: float):
	if height_label:
		height_label.text = "%.1f m" % height_m

func update_distance(dist_m: float):
	if distance_label:
		distance_label.text = "%.1f m" % dist_m

func update_wind(wind_speed: float, direction: String):
	if wind_label:
		var abs_wind = abs(wind_speed)
		var label_text = "%.1f m/s" % abs_wind
		wind_label.text = label_text
	if wind_arrow:
		wind_arrow.text = direction
		if wind_speed > 0.5:
			wind_arrow.modulate = Color(0.2, 1.0, 0.2)  # green = good tailwind
		elif wind_speed < -0.5:
			wind_arrow.modulate = Color(1.0, 0.3, 0.3)  # red = bad headwind
		else:
			wind_arrow.modulate = Color(1.0, 1.0, 1.0)

func update_style_points(points: float):
	if style_bar:
		style_bar.value = points
	if points_label:
		points_label.text = "%.1f" % points

func update_jump_charge(charge: float, visible_flag: bool):
	if jump_bar:
		jump_bar.visible = visible_flag
		jump_bar.value = charge * 100.0
		
		# Color based on charge level
		var style = jump_bar.get_theme_stylebox("fill")
		if charge < 0.6:
			jump_bar.modulate = Color(0.3, 0.8, 1.0)
		elif charge < 0.85:
			jump_bar.modulate = Color(0.2, 1.0, 0.2)  # Optimal zone
		else:
			jump_bar.modulate = Color(1.0, 0.3, 0.3)  # Over-charged

func show_phase(phase_name: String):
	if phase_label:
		match phase_name:
			"inrun":
				phase_label.text = "▼ ROZJAZD"
				phase_label.modulate = Color(0.8, 0.9, 1.0)
			"takeoff":
				phase_label.text = "⚡ WYBICIE! [SPACJA]"
				phase_label.modulate = Color(1.0, 1.0, 0.2)
			"flight":
				phase_label.text = "✈ LOT"
				phase_label.modulate = Color(0.2, 1.0, 0.8)
			"landing":
				phase_label.text = "↓ LĄDOWANIE"
				phase_label.modulate = Color(0.8, 1.0, 0.4)
		
		phase_label.visible = true
		_phase_display_timer = 2.0

func _process(delta: float):
	if _phase_display_timer > 0:
		_phase_display_timer -= delta
		if _phase_display_timer <= 0:
			if phase_label and phase_label.text != "✈ LOT":
				phase_label.visible = false

func set_k_point(k: float, hill_name: String):
	if k_point_indicator:
		k_point_indicator.text = "K%d - %s" % [int(k), hill_name]

func show_instructions(phase: String):
	if not instructions_label:
		return
	match phase:
		"inrun":
			instructions_label.text = "Przygotuj się do skoku..."
		"takeoff":
			instructions_label.text = "Przytrzymaj [SPACJA] → puść w odpowiednim momencie!"
		"flight":
			instructions_label.text = "↑↓ Pochylenie  |  ←→ Balans  |  [SPACJA] Telemark przy lądowaniu"
		"landing", "finished":
			instructions_label.text = ""

func show_wind_indicator(wind_speed: float):
	if wind_bar:
		# -4 to +4 m/s mapped to 0-100
		wind_bar.value = 50.0 + (wind_speed / 4.0) * 50.0
