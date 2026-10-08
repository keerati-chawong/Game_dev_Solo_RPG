extends AnimatableBody3D
## Platform that glides between its start and `travel` and carries the player.

@export var travel := Vector3(6, 0, 0)
@export var duration := 3.0


func _ready():
	var start = position
	var tween = create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position", start + travel, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.4)
	tween.tween_property(self, "position", start, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.4)
