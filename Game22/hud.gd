extends CanvasLayer

# Notifies `Main` node that the button has been pressed
signal start_game


func show_message(text):
	$Message.text = text
	$Message.show()
	$MessageTimer.start()


func show_game_over(level, score):
	show_message("Game Over\nLv.%d  Score %d" % [level, score])
	# Wait until the MessageTimer has counted down.
	await $MessageTimer.timeout

	$Message.text = "Dungeon Dodge"
	$Message.show()
	# Make a one-shot timer and wait for it to finish.
	await get_tree().create_timer(1.0).timeout
	$StartButton.show()
	$StartButton.grab_focus()
	$HowTo.show()


func update_stats(score, level, xp, xp_needed):
	$ScoreLabel.text = "Score %d" % score
	$LevelLabel.text = "Lv.%d" % level
	$XPBar.max_value = xp_needed
	$XPBar.value = xp


func _ready():
	$StartButton.grab_focus()


func _on_start_button_pressed():
	$StartButton.hide()
	$HowTo.hide()
	start_game.emit()


func _on_message_timer_timeout():
	$Message.hide()
