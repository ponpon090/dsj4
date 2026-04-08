extends Control

# Results / Leaderboard screen

@onready var hill_tabs: TabContainer = $VBox/HillTabs
@onready var back_button: Button = $VBox/ButtonRow/BackButton
@onready var play_again_button: Button = $VBox/ButtonRow/PlayAgainButton

func _ready():
	_populate_leaderboards()
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if play_again_button:
		play_again_button.pressed.connect(_on_play_again_pressed)

func _populate_leaderboards():
	if not hill_tabs:
		return
	
	# Clear existing tabs
	for child in hill_tabs.get_children():
		child.queue_free()
	
	var hills = GameManager.HILLS
	for hill_key in hills.keys():
		var scroll = ScrollContainer.new()
		scroll.name = hills[hill_key]["name"]
		
		var vbox = VBoxContainer.new()
		scroll.add_child(vbox)
		
		# Header
		var header = Label.new()
		header.text = "%-5s %-20s %8s %8s %8s" % ["Rank", "Zawodnik", "Odległość", "Pkt", "Suma"]
		header.add_theme_font_size_override("font_size", 14)
		header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		vbox.add_child(header)
		
		var separator = HSeparator.new()
		vbox.add_child(separator)
		
		var scores = GameManager.get_leaderboard(hill_key)
		if scores.is_empty():
			var empty_label = Label.new()
			empty_label.text = "Brak wyników. Zagraj, aby zobaczyć wyniki!"
			empty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			vbox.add_child(empty_label)
		else:
			for i in range(scores.size()):
				var entry = scores[i]
				var row = Label.new()
				var rank = i + 1
				var medal = ""
				if rank == 1: medal = "🥇"
				elif rank == 2: medal = "🥈"
				elif rank == 3: medal = "🥉"
				else: medal = str(rank) + "."
				
				row.text = "%-5s %-20s %6.1f m %7.1f %7.1f" % [
					medal,
					entry["name"].substr(0, 18),
					entry["distance"],
					entry["points"],
					entry["total"]
				]
				
				if rank <= 3:
					row.add_theme_color_override("font_color", Color(1.0, 0.95, 0.5))
				
				vbox.add_child(row)
		
		hill_tabs.add_child(scroll)
	
	# Select tab for current hill
	var hill_keys = hills.keys()
	var current_idx = hill_keys.find(GameManager.current_hill)
	if current_idx >= 0 and hill_tabs:
		hill_tabs.current_tab = current_idx

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_play_again_pressed():
	GameManager.reset_session()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")
