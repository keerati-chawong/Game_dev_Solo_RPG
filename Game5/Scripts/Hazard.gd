extends Area3D
## Anything that hurts: spikes, saws, spinning bars, lava and the dead zone.


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("Player"):
		get_tree().call_group("Level", "hurt_player")
