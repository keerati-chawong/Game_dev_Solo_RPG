extends CanvasLayer


func set_level(text : String):
	$GameUI/LevelLabel.text = text


# Shows a short message in the middle of the screen.
func flash(text : String, seconds := 2.0):
	$GameUI/Message.text = text
	$GameUI/Message.show()
	$MessageTimer.start(seconds)


func _on_message_timer_timeout():
	$GameUI/Message.hide()
