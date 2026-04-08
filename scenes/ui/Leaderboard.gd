# Leaderboard.gd - Shows top 10 scores
class_name Leaderboard
extends Control

signal back_pressed

const SAVE_FILE = "user://leaderboard.json"
const MAX_ENTRIES = 10

@onready var entries_container: VBoxContainer = $Panel/ScrollContainer/EntriesContainer
@onready var back_btn: Button = $Panel/BackButton

var scores: Array = []

func _ready():
	back_btn.pressed.connect(func(): back_pressed.emit())
	load_scores()
	_refresh_display()

func load_scores():
	if FileAccess.file_exists(SAVE_FILE):
		var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_str) == OK:
				scores = json.get_data()
	else:
		scores = []

func save_score(player_name: String, distance: float, points: float, hill_name: String) -> bool:
	load_scores()
	var entry = {
		"name": player_name,
		"distance": distance,
		"points": points,
		"hill": hill_name,
		"date": Time.get_date_string_from_system()
	}
	scores.append(entry)
	scores.sort_custom(func(a, b): return a["points"] > b["points"])
	if scores.size() > MAX_ENTRIES:
		scores.resize(MAX_ENTRIES)
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(scores, "\t"))
		file.close()
		return true
	return false

func is_high_score(points: float) -> bool:
	if scores.size() < MAX_ENTRIES:
		return true
	if scores.size() > 0:
		return points > scores[scores.size() - 1]["points"]
	return true

func _refresh_display():
	for child in entries_container.get_children():
		child.queue_free()
	
	if scores.is_empty():
		var lbl = Label.new()
		lbl.text = "No scores yet. Be the first!"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		entries_container.add_child(lbl)
		return
	
	for i in range(scores.size()):
		var entry = scores[i]
		var hbox = HBoxContainer.new()
		
		var rank_lbl = Label.new()
		rank_lbl.text = "%d." % (i + 1)
		rank_lbl.custom_minimum_size = Vector2(30, 0)
		hbox.add_child(rank_lbl)
		
		var name_lbl = Label.new()
		name_lbl.text = entry.get("name", "Player")
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)
		
		var dist_lbl = Label.new()
		dist_lbl.text = "%.1fm" % entry.get("distance", 0)
		dist_lbl.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(dist_lbl)
		
		var pts_lbl = Label.new()
		pts_lbl.text = "%.1f pts" % entry.get("points", 0)
		pts_lbl.custom_minimum_size = Vector2(80, 0)
		hbox.add_child(pts_lbl)
		
		var hill_lbl = Label.new()
		hill_lbl.text = entry.get("hill", "K90")
		hbox.add_child(hill_lbl)
		
		entries_container.add_child(hbox)
