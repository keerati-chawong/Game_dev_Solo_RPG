extends Area2D

signal collected


func _ready():
	var tween = create_tween().set_loops()
	tween.tween_property($Sprite2D, "position:y", -6.0, 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property($Sprite2D, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body):
	if body.is_in_group("player"):
		collected.emit()
		queue_free()
