extends Node

@export var mob_scene: PackedScene
@export var gem_scene: PackedScene

const GEM_XP = 3

var score = 0
var level = 1
var xp = 0


func _ready():
	# Monsters spawn along the edge of the screen, clockwise.
	var size = get_viewport().get_visible_rect().size
	var curve = Curve2D.new()
	for point in [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y), Vector2.ZERO]:
		curve.add_point(point)
	$MobPath.curve = curve
	$HUD.update_stats(score, level, xp, xp_needed())


func xp_needed():
	return 4 + level * 4


func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$GemTimer.stop()
	$HUD.show_game_over(level, score)
	$Music.stop()
	$DeathSound.play()


func new_game():
	score = 0
	level = 1
	xp = 0
	get_tree().call_group("mobs", "queue_free")
	get_tree().call_group("gems", "queue_free")
	$MobTimer.wait_time = 0.6
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_stats(score, level, xp, xp_needed())
	$HUD.show_message("Get Ready!")
	$Music.play()


func gain_xp(amount):
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		# Every level the dungeon gets a little meaner.
		$MobTimer.wait_time = max(0.2, 0.6 - 0.05 * (level - 1))
		$HUD.show_message("LEVEL UP!\nLv.%d" % level)
		$LevelUpSound.play()
	$HUD.update_stats(score, level, xp, xp_needed())


func _on_mob_timer_timeout():
	var mob = mob_scene.instantiate()

	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	mob.position = mob_spawn_location.position

	# Perpendicular to the path (into the screen), with some randomness.
	var direction = mob_spawn_location.rotation + PI / 2
	direction += randf_range(-PI / 4, PI / 4)

	var speed = randf_range(130.0, 220.0) * (1.0 + 0.08 * (level - 1))
	add_child(mob)
	mob.set_direction(Vector2(speed, 0.0).rotated(direction))


func _on_gem_timer_timeout():
	var size = get_viewport().get_visible_rect().size
	var gem = gem_scene.instantiate()
	gem.position = Vector2(randf_range(40, size.x - 40), randf_range(90, size.y - 70))
	gem.collected.connect(_on_gem_collected)
	add_child(gem)


func _on_gem_collected():
	score += 5
	$GemSound.play()
	gain_xp(GEM_XP)


func _on_score_timer_timeout():
	score += 1
	gain_xp(1)


func _on_start_timer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
	$GemTimer.start()


func _on_music_finished():
	$Music.play()
