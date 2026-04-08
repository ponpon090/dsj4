extends Node

# Global game state manager
# Persists across scenes

var current_hill: String = "normal_hill"
var current_difficulty: String = "medium"
var current_weather: String = "sunny"
var player_name: String = "Player"
var tournament_mode: bool = false
var current_round: int = 1
var total_rounds: int = 2

# Session scores
var round_scores: Array = []
var total_score: float = 0.0
var total_distance: float = 0.0

# Hill configurations
const HILLS = {
	"small_hill": {
		"name": "K-60 Small Hill",
		"k_point": 60.0,
		"hill_size": 65.0,
		"table_height": 0.0,
		"table_length": 7.0,
		"ramp_length": 80.0,
		"ramp_angle": 11.5,
		"knoll_angle": 34.0,
		"landing_angle": 37.0,
		"alpha": 63.0,  # inrun angle
		"points_per_meter": 2.0,
		"base_points": 60.0,
		"gate_factor": 0.6,
		"wind_factor": 6.36,
	},
	"normal_hill": {
		"name": "K-90 Normal Hill",
		"k_point": 90.0,
		"hill_size": 95.0,
		"table_height": 3.0,
		"table_length": 7.0,
		"ramp_length": 100.0,
		"ramp_angle": 10.5,
		"knoll_angle": 34.0,
		"landing_angle": 36.0,
		"alpha": 65.0,
		"points_per_meter": 2.0,
		"base_points": 60.0,
		"gate_factor": 0.7,
		"wind_factor": 7.74,
	},
	"large_hill": {
		"name": "K-120 Large Hill",
		"k_point": 120.0,
		"hill_size": 130.0,
		"table_height": 4.5,
		"table_length": 8.0,
		"ramp_length": 110.0,
		"ramp_angle": 10.0,
		"knoll_angle": 33.0,
		"landing_angle": 35.0,
		"alpha": 64.0,
		"points_per_meter": 1.8,
		"base_points": 60.0,
		"gate_factor": 0.9,
		"wind_factor": 9.90,
	},
	"flying_hill": {
		"name": "K-185 Flying Hill",
		"k_point": 185.0,
		"hill_size": 200.0,
		"table_height": 8.0,
		"table_length": 9.0,
		"ramp_length": 130.0,
		"ramp_angle": 9.5,
		"knoll_angle": 32.0,
		"landing_angle": 34.0,
		"alpha": 63.0,
		"points_per_meter": 1.2,
		"base_points": 120.0,
		"gate_factor": 1.2,
		"wind_factor": 13.60,
	}
}

# Leaderboard stored per hill
var leaderboard: Dictionary = {}

func _ready():
	# Make this autoload/singleton
	for hill_key in HILLS.keys():
		leaderboard[hill_key] = []

func get_hill_config() -> Dictionary:
	return HILLS[current_hill]

func add_score(hill_key: String, name: String, distance: float, points: float, style: float):
	if not leaderboard.has(hill_key):
		leaderboard[hill_key] = []
	
	leaderboard[hill_key].append({
		"name": name,
		"distance": distance,
		"points": points,
		"style": style,
		"total": points + style
	})
	
	# Sort by total descending
	leaderboard[hill_key].sort_custom(func(a, b): return a["total"] > b["total"])
	
	# Keep top 20
	if leaderboard[hill_key].size() > 20:
		leaderboard[hill_key].resize(20)

func get_leaderboard(hill_key: String) -> Array:
	if leaderboard.has(hill_key):
		return leaderboard[hill_key]
	return []

func calculate_distance_points(distance: float, hill_key: String) -> float:
	var config = HILLS[hill_key]
	var k_point = config["k_point"]
	var ppm = config["points_per_meter"]
	var base = config["base_points"]
	return base + (distance - k_point) * ppm

func reset_session():
	round_scores.clear()
	total_score = 0.0
	total_distance = 0.0
	current_round = 1
