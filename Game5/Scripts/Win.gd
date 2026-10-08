extends Control


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Deaths.text = "Retries: %d" % GameManager.deaths
	$PlayAgain.grab_focus()


func _on_play_again_pressed():
	GameManager.new_game()
