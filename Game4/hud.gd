extends CanvasLayer


func set_level(text):
	$LevelLabel.text = text


func set_gems(got, total):
	$GemLabel.text = "Gems %d / %d" % [got, total]


func show_message(text, seconds := 2.0):
	$Message.text = text
	$Message.show()
	$MessageTimer.start(seconds)


func _on_message_timer_timeout():
	$Message.hide()
