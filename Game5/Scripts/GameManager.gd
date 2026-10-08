extends Node3D

# ---------- VARIABLES ---------- #

signal coins_changed

var score = 0  # Coins collected in the current level.
var coins_total = 0
var deaths = 0

# ---------- FUNCTIONS ---------- #

func _process(_delta):
	show_mouse_cursor()

# Making Cursor visible using "mouse_visible" key which is assigned in Project Settings > Input Map
func show_mouse_cursor():
	if Input.is_action_just_pressed("mouse_visible"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func add_score():
	score += 1
	coins_changed.emit()

# Called by each level when it starts.
func start_level(total : int):
	score = 0
	coins_total = total
	coins_changed.emit()

func all_coins_collected() -> bool:
	return score >= coins_total

func new_game():
	deaths = 0
	get_tree().change_scene_to_file("res://Scenes/Levels/level_1.tscn")
