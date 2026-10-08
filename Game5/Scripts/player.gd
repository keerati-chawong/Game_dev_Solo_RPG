# ----------------------------------------------------------------------------------- #
# -------------- FEEL FREE TO USE IN ANY PROJECT, COMMERCIAL OR NON-COMMERCIAL ------ #
# ---------------------- 3D PLATFORMER CONTROLLER BY SD STUDIOS --------------------- #
# ---------------------------- ATTRIBUTION NOT REQUIRED ----------------------------- #
# ----------------------------------------------------------------------------------- #
# Lab 5 changes: the Gobot model was replaced by the "Adventurer" character from
# Poly Pizza, its animations are remapped to the names the kit expects, and the
# player can now be hurt and respawned by traps.

extends CharacterBody3D

# ---------- VARIABLES ---------- #

@export_category("Player Properties")
@export var move_speed : float = 6
@export var jump_force : float = 5
@export var follow_lerp_factor : float = 4
@export var jump_limit : int = 2

@export_group("Game Juice")
@export var jumpStretchSize := Vector3(0.8, 1.2, 0.8)

# The kit's animation names -> [animation inside adventurer.glb, loops?]
const ANIMATION_MAP := {
	"Idle": ["CharacterArmature|Idle", true],
	"Run": ["CharacterArmature|Run", true],
	"Jump": ["CharacterArmature|Run", false],
	"Flip": ["CharacterArmature|Roll", false],
	"Hurt": ["CharacterArmature|HitRecieve", false],
}

# Booleans
var is_grounded = false
var can_double_jump = false
var is_hurt = false

# Onready Variables
@onready var model = $Adventurer
@onready var animation : AnimationPlayer = $Adventurer/AnimationPlayer
@onready var spring_arm = %Gimbal

@onready var particle_trail = $ParticleTrail
@onready var footsteps = $Footsteps

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 2

# ---------- FUNCTIONS ---------- #

func _ready():
	setup_animations()
	animation.play("Idle")

# Gives the new model the same animation names the original Gobot had.
func setup_animations():
	var source : AnimationLibrary = animation.get_animation_library("")
	var library := AnimationLibrary.new()
	for kit_name in ANIMATION_MAP:
		var anim : Animation = source.get_animation(ANIMATION_MAP[kit_name][0]).duplicate()
		anim.loop_mode = Animation.LOOP_LINEAR if ANIMATION_MAP[kit_name][1] else Animation.LOOP_NONE
		library.add_animation(kit_name, anim)
	animation.remove_animation_library("")
	animation.add_animation_library("", library)

func _process(delta):
	player_animations()
	get_input(delta)

	# Smoothly follow player's position
	spring_arm.position = lerp(spring_arm.position, position, delta * follow_lerp_factor)

	# Player Rotation
	if is_moving():
		var look_direction = Vector2(velocity.z, velocity.x)
		model.rotation.y = lerp_angle(model.rotation.y, look_direction.angle(), delta * 12)
		if spring_arm.auto_rotate:
			spring_arm.rotation.y = lerp_angle(spring_arm.rotation.y, look_direction.angle()-deg_to_rad(180), delta*0.4)
			spring_arm.rotation.x = lerp_angle(spring_arm.rotation.x, deg_to_rad(0), delta*0.4)

	# Check if player is grounded or not
	is_grounded = true if is_on_floor() else false

	# Handle Jumping
	if is_grounded:
		can_double_jump = true

	if Input.is_action_just_pressed("jump") and not is_hurt:
		if is_on_floor():
			perform_jump()
		elif can_double_jump:
			if is_moving():
				perform_flip_jump()

	velocity.y -= gravity * delta

func perform_jump():
	AudioManager.jump_sfx.play()
	AudioManager.jump_sfx.pitch_scale = 1.12

	jumpTween()
	animation.play("Jump", 0.1, 0.6)
	velocity.y = jump_force

func perform_flip_jump():
	AudioManager.jump_sfx.play()
	AudioManager.jump_sfx.pitch_scale = 0.8
	can_double_jump = false
	animation.play("Flip", -1, 2)
	velocity.y = jump_force

func is_moving():
	return abs(velocity.z) > 0 || abs(velocity.x) > 0

func jumpTween():
	var tween = get_tree().create_tween()
	tween.tween_property(self, "scale", jumpStretchSize, 0.1)
	tween.tween_property(self, "scale", Vector3(1,1,1), 0.1)

# Get Player Input
func get_input(_delta):
	var move_direction := Vector3.ZERO
	if not is_hurt:
		move_direction.x = Input.get_axis("move_left", "move_right")
		move_direction.z = Input.get_axis("move_forward", "move_back")

	# Move The player Towards Spring Arm/Camera Rotation
	move_direction = move_direction.rotated(Vector3.UP, spring_arm.rotation.y).normalized()
	velocity = Vector3(move_direction.x * move_speed, velocity.y, move_direction.z * move_speed)

	move_and_slide()

# Handle Player Animations
func player_animations():
	particle_trail.emitting = false
	footsteps.stream_paused = true

	if is_hurt:
		return

	if is_on_floor():
		if is_moving(): # Checks if player is moving
			animation.play("Run", 0.5)
			particle_trail.emitting = true
			footsteps.stream_paused = false
		else:
			animation.play("Idle", 0.5)

# Called by the level when a trap hits the player: play the hurt pose, then
# put the player back on the last spawn point.
func hurt_and_respawn(spawn_position : Vector3):
	if is_hurt:
		return
	is_hurt = true
	velocity = Vector3.ZERO
	animation.play("Hurt", 0.05)
	await get_tree().create_timer(0.45).timeout
	global_position = spawn_position
	velocity = Vector3.ZERO
	spring_arm.position = position
	is_hurt = false
