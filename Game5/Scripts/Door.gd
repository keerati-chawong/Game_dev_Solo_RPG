extends Area3D
## Exit door: locked (red) until every coin in the level is collected.

signal player_entered

@export var locked_material : Material
@export var open_material : Material


func _ready():
	body_entered.connect(_on_body_entered)


func set_progress(collected : int, total : int):
	if collected >= total:
		$Panel.material_override = open_material
		$Label.text = "OPEN"
		$Label.modulate = Color(0.5, 1.0, 0.6)
	else:
		$Panel.material_override = locked_material
		$Label.text = "COINS %d / %d" % [collected, total]
		$Label.modulate = Color(1.0, 0.8, 0.4)


func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_entered.emit()
