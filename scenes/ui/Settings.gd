# Settings.gd - Game settings
class_name Settings
extends Control

signal back_pressed
signal settings_changed(settings: Dictionary)

const SAVE_FILE = "user://settings.cfg"

@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicContainer/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SFXContainer/SFXSlider
@onready var quality_option: OptionButton = $Panel/VBoxContainer/QualityContainer/QualityOption
@onready var difficulty_option: OptionButton = $Panel/VBoxContainer/DifficultyContainer/DifficultyOption
@onready var back_btn: Button = $Panel/BackButton

var current_settings: Dictionary = {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"quality": 1,
	"difficulty": 1
}

func _ready():
	back_btn.pressed.connect(_on_back_pressed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	quality_option.item_selected.connect(_on_quality_changed)
	difficulty_option.item_selected.connect(_on_difficulty_changed)
	
	_populate_options()
	load_settings()
	_apply_settings()

func _populate_options():
	quality_option.clear()
	quality_option.add_item("Low", 0)
	quality_option.add_item("Medium", 1)
	quality_option.add_item("High", 2)
	
	difficulty_option.clear()
	difficulty_option.add_item("Easy", 0)
	difficulty_option.add_item("Normal", 1)
	difficulty_option.add_item("Hard", 2)

func load_settings():
	var config = ConfigFile.new()
	if config.load(SAVE_FILE) == OK:
		current_settings["music_volume"] = config.get_value("audio", "music", 0.8)
		current_settings["sfx_volume"] = config.get_value("audio", "sfx", 1.0)
		current_settings["quality"] = config.get_value("graphics", "quality", 1)
		current_settings["difficulty"] = config.get_value("game", "difficulty", 1)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "music", current_settings["music_volume"])
	config.set_value("audio", "sfx", current_settings["sfx_volume"])
	config.set_value("graphics", "quality", current_settings["quality"])
	config.set_value("game", "difficulty", current_settings["difficulty"])
	config.save(SAVE_FILE)

func _apply_settings():
	music_slider.value = current_settings["music_volume"]
	sfx_slider.value = current_settings["sfx_volume"]
	quality_option.select(current_settings["quality"])
	difficulty_option.select(current_settings["difficulty"])

func _on_back_pressed():
	save_settings()
	back_pressed.emit()

func _on_music_changed(value: float):
	current_settings["music_volume"] = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))
	settings_changed.emit(current_settings)

func _on_sfx_changed(value: float):
	current_settings["sfx_volume"] = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))
	settings_changed.emit(current_settings)

func _on_quality_changed(index: int):
	current_settings["quality"] = index
	settings_changed.emit(current_settings)

func _on_difficulty_changed(index: int):
	current_settings["difficulty"] = index
	settings_changed.emit(current_settings)
