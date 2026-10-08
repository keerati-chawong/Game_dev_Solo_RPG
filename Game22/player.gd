extends Area2D

signal hit

@export var speed = 380  # How fast the hero moves (pixels/sec).
var screen_size


func _ready():
	screen_size = get_viewport_rect().size
	hide()


func _process(delta):
	var velocity = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if velocity == Vector2.ZERO:
		# WASD as an alternative to the arrow keys.
		velocity.x = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		velocity.y = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2(24, 60), screen_size - Vector2(24, 36))

	if velocity.x != 0:
		$AnimatedSprite2D.flip_h = velocity.x < 0


func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false


func _on_body_entered(_body):
	hide()  # Hero disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$CollisionShape2D.set_deferred("disabled", true)
