extends AnimatableBody2D

@export var travel := Vector2(300, 0)  # Offset the platform slides to and back from.
@export var duration := 2.5


func _ready():
	var start = position
	var tween = create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "position", start + travel, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", start, duration).set_trans(Tween.TRANS_SINE)
