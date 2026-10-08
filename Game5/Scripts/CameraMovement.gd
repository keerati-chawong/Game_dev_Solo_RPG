# ----------------------------------------------------------------------------------- #
# -------------- FEEL FREE TO USE IN ANY PROJECT, COMMERCIAL OR NON-COMMERCIAL ------ #
# ---------------------- 3D PLATFORMER CONTROLLER BY SD STUDIOS --------------------- #
# ---------------------------- ATTRIBUTION NOT REQUIRED ----------------------------- #
# ----------------------------------------------------------------------------------- #
# Lab 5 change: the camera angle stays locked behind the player. It only turns
# while the right mouse button is held and dragged, and the cursor is never captured.

extends Node3D

# ---------- VARIABLES ---------- #

# Control Mouse Sensitivity through inspector or from here
@export var mouse_sensitivity := 0.2

# Assign Camera Node here it might be named different in your Project
@onready var camera = $Camera3D
@onready var auto_rotate = false
@onready var timer = $CameraControlTimer

# ---------- FUNCTIONS ---------- #

func _ready():
	top_level = true

# Handling Camera Movement
func _unhandled_input(event):
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
		rotation_degrees.x -= event.relative.y * mouse_sensitivity
		rotation_degrees.x = clamp(rotation_degrees.x, -60, -0)

		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.y = wrapf(rotation_degrees.y, 0, 360)


# The kit turned the camera by itself after this timer; the angle is locked now.
func _on_camera_control_timer_timeout():
	pass
