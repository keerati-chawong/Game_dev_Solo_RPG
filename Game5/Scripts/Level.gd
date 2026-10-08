extends Node3D
## One level: collect every coin to unlock the door, traps send you back to
## the last checkpoint.

@export var level_name := "Level 1"
@export_file("*.tscn") var next_scene := ""

var spawn_point := Vector3.ZERO
var _leaving := false

@onready var player = $Player
@onready var door = $Door
@onready var ui = $UserInterface


func _ready():
	add_to_group("Level")
	spawn_point = %SpawnPosition.global_position
	GameManager.start_level($Coins.get_child_count())
	GameManager.coins_changed.connect(_on_coins_changed)
	door.player_entered.connect(_on_door_entered)
	door.set_progress(0, GameManager.coins_total)
	ui.set_level(level_name)
	ui.flash(level_name + "\nCollect every coin to open the door", 3.5)


func _on_coins_changed():
	door.set_progress(GameManager.score, GameManager.coins_total)
	if GameManager.all_coins_collected() and GameManager.coins_total > 0:
		ui.flash("The door is open!")


# Traps and the dead zone call this through the "Level" group.
func hurt_player():
	if player.is_hurt or _leaving:
		return
	GameManager.deaths += 1
	ui.flash("Ouch!", 1.0)
	player.hurt_and_respawn(spawn_point)


func set_checkpoint(point : Vector3):
	if spawn_point.is_equal_approx(point):
		return
	spawn_point = point
	ui.flash("Checkpoint!", 1.5)


func _on_door_entered():
	if _leaving:
		return
	if not GameManager.all_coins_collected():
		ui.flash("Locked - %d coins left" % (GameManager.coins_total - GameManager.score), 1.5)
		return
	_leaving = true
	AudioManager.coin_sfx.play()
	get_tree().change_scene_to_file.call_deferred(next_scene)
