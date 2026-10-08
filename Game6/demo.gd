extends Node3D
## Lab 6 demo: shows the Blender-made character playing every animation in the
## Open Animation Library (MeleeLib), retargeted through the Mixamo bone map.

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var list: ItemList = $UI/Panel/List
@onready var now_playing: Label = $UI/NowPlaying
@onready var pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var names: Array[String] = []
var index := 0


func _ready():
	for anim_name in anim.get_animation_list():
		# Skip the single-frame reference pose that ships inside the library.
		if not anim_name.begins_with("Armature|"):
			names.append(anim_name)
	for anim_name in names:
		list.add_item(anim_name)
	list.grab_focus()
	play(max(names.find("LightIdle"), 0))


func play(i: int):
	index = wrapi(i, 0, names.size())
	anim.get_animation(names[index]).loop_mode = Animation.LOOP_LINEAR
	anim.play(names[index], 0.25)
	list.select(index)
	list.ensure_current_is_visible()
	now_playing.text = "%s   (%d / %d)" % [names[index], index + 1, names.size()]


func _on_list_item_selected(i: int):
	if i != index:
		play(i)


func _on_prev_pressed():
	play(index - 1)


func _on_next_pressed():
	play(index + 1)


func _unhandled_input(event):
	# Hold the right mouse button and drag to orbit; the wheel zooms.
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
		pivot.rotation_degrees.y -= event.relative.x * 0.3
		pivot.rotation_degrees.x = clamp(pivot.rotation_degrees.x - event.relative.y * 0.3, -60, 20)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.position.z = max(2.0, camera.position.z - 0.3)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.position.z = min(7.0, camera.position.z + 0.3)
