extends Node2D

@export var ball_scene: PackedScene

const MAX_BALLS = 60


func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spawn_ball(event.position)
	elif event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()


func spawn_ball(at: Vector2):
	if $Balls.get_child_count() >= MAX_BALLS:
		$Balls.get_child(0).queue_free()
	var ball = ball_scene.instantiate()
	ball.position = at
	ball.get_node("Sprite2D").modulate = Color.from_hsv(randf(), 0.35, 1.0)
	$Balls.add_child(ball)
	$Hint.text = "Click: drop a slime   |   Enter: reset   |   Slimes: %d" % $Balls.get_child_count()
