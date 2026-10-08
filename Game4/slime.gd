extends Area2D

@export var distance := 200.0  # How far right of its start the slime patrols.
@export var speed := 70.0

var _start_x := 0.0
var _direction := 1.0


func _ready():
	_start_x = position.x
	$AnimatedSprite2D.play("walk")


func _physics_process(delta):
	position.x += _direction * speed * delta
	if position.x > _start_x + distance:
		_direction = -1.0
	elif position.x < _start_x:
		_direction = 1.0
	$AnimatedSprite2D.flip_h = _direction < 0


func _on_body_entered(body):
	if not body.is_in_group("player"):
		return
	# Landing on top squashes the slime; touching it any other way hurts.
	if body.velocity.y > 0 and body.global_position.y < global_position.y - 20:
		body.bounce()
		queue_free()
	else:
		body.die()
