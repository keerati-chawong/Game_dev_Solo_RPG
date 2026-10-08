extends Area2D

signal entered
signal locked_touch

@export var open_texture: Texture2D

var is_open = false


func open():
	is_open = true
	$Sprite2D.texture = open_texture


func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	if is_open:
		entered.emit()
	else:
		locked_touch.emit()
