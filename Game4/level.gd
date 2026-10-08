extends Node2D
## Shared logic for every level: gem counting, the exit door and respawning.

@export var level_name := "Level 1"
@export var level_width := 3000
@export_file("*.tscn") var next_scene := ""

var _total := 0
var _got := 0
var _leaving := false


func _ready():
	$Player/Camera2D.limit_right = level_width
	var gems = get_tree().get_nodes_in_group("gems")
	_total = gems.size()
	for gem in gems:
		gem.collected.connect(_on_gem_collected)
	$Player.died.connect(_on_player_died)
	$Door.entered.connect(_on_door_entered)
	$Door.locked_touch.connect(_on_door_locked)
	$HUD.set_level(level_name)
	$HUD.set_gems(_got, _total)
	$HUD.show_message(level_name + "\nCollect every gem to open the door")


func _on_gem_collected():
	_got += 1
	$HUD.set_gems(_got, _total)
	$GemSound.play()
	if _got == _total:
		$Door.open()
		$DoorSound.play()
		$HUD.show_message("The door is open!")


func _on_door_locked():
	$HUD.show_message("Locked - %d gems left" % (_total - _got))


func _on_door_entered():
	if _leaving:
		return
	_leaving = true
	get_tree().change_scene_to_file.call_deferred(next_scene)


func _on_player_died():
	$DeathSound.play()
	$HUD.show_message("Ouch! Try again")
	await get_tree().create_timer(1.2).timeout
	get_tree().reload_current_scene()
