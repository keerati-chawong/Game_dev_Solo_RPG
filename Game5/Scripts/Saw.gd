extends Node3D
## Saw blade that slides back and forth between its start and `travel`.

@export var travel := Vector3(5, 0, 0)
@export var duration := 2.0


func _ready():
	var start = position
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position", start + travel, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", start, duration).set_trans(Tween.TRANS_SINE)


func _process(delta):
	$Blade/Disc.rotate_object_local(Vector3.UP, 9.0 * delta)
