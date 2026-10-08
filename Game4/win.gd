extends Control


func _ready():
	$PlayAgain.grab_focus()


func _on_play_again_pressed():
	get_tree().change_scene_to_file("res://level_1.tscn")
