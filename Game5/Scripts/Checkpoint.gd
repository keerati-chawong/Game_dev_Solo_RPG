extends Area3D
## Touching the flag makes it the respawn point.


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("Player"):
		get_tree().call_group("Level", "set_checkpoint", global_position + Vector3(0, 1.0, 0))
