extends Node3D
## Rotating bar trap: jump over the bar as it sweeps the platform.

@export var speed_degrees := 90.0


func _process(delta):
	$Bar.rotate_y(deg_to_rad(speed_degrees) * delta)
