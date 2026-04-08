# Results.gd - Shows jump results
class_name Results
extends CanvasLayer

signal try_again_pressed
signal menu_pressed

@onready var distance_label: Label = $Panel/VBoxContainer/DistanceLabel
@onready var points_label: Label = $Panel/VBoxContainer/PointsLabel
@onready var style_label: Label = $Panel/VBoxContainer/StyleLabel
@onready var grade_label: Label = $Panel/VBoxContainer/GradeLabel
@onready var try_again_btn: Button = $Panel/VBoxContainer/TryAgainButton
@onready var menu_btn: Button = $Panel/VBoxContainer/MenuButton
@onready var new_record_label: Label = $Panel/VBoxContainer/NewRecordLabel

func _ready():
	try_again_btn.pressed.connect(func(): try_again_pressed.emit())
	menu_btn.pressed.connect(func(): menu_pressed.emit())
	visible = false

func show_results(distance: float, distance_pts: float, style_pts: float, is_record: bool = false):
	var total = distance_pts + style_pts
	distance_label.text = "Distance: %.1f m" % distance
	points_label.text = "Total: %.1f pts" % total
	style_label.text = "Style: %.1f pts" % style_pts
	grade_label.text = "Grade: %s" % _get_grade(total)
	new_record_label.visible = is_record
	visible = true

func _get_grade(points: float) -> String:
	if points >= 130: return "EXCELLENT!"
	elif points >= 110: return "GREAT"
	elif points >= 90: return "GOOD"
	elif points >= 70: return "FAIR"
	else: return "POOR"

func hide_results():
	visible = false
