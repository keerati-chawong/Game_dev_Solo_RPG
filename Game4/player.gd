extends CharacterBody2D

signal died

const SPEED = 260.0
const JUMP_VELOCITY = -620.0
const GRAVITY = 1400.0
const COYOTE_TIME = 0.1  # Grace period to still jump just after leaving a ledge.
const JUMP_BUFFER = 0.12  # A jump pressed slightly early still counts on landing.
const FALL_LIMIT = 760.0

var alive = true
var _coyote = 0.0
var _buffer = 0.0


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_SPACE, KEY_UP, KEY_W]:
			_buffer = JUMP_BUFFER


func _physics_process(delta):
	if not alive:
		return

	var direction = Input.get_axis("ui_left", "ui_right")
	if direction == 0:
		direction = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))

	if is_on_floor():
		_coyote = COYOTE_TIME
	else:
		_coyote -= delta
		velocity.y += GRAVITY * delta

	_buffer -= delta
	if _buffer > 0 and _coyote > 0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0

	velocity.x = direction * SPEED
	move_and_slide()
	position.x = max(position.x, 20.0)

	if direction != 0:
		$AnimatedSprite2D.flip_h = direction < 0
		$AnimatedSprite2D.play("walk")
	else:
		$AnimatedSprite2D.stop()

	if position.y > FALL_LIMIT:
		die()


## Small hop after stomping an enemy.
func bounce():
	velocity.y = JUMP_VELOCITY * 0.7


func die():
	if not alive:
		return
	alive = false
	hide()
	died.emit()
