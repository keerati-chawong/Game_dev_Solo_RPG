extends Node3D
## Rogue Chess 3D - game flow, input, board visuals and UI.

enum State { PLAYER, BUSY, OVER }

signal card_picked(index: int)

const ENEMY_CARDS_PER_ROUND := 2

const THEMES := [
	{"name": "Emerald Meadow", "decor": "trees", "light": Color("d9dfb8"), "dark": Color("4f7d41"),
		"ground": Color("5f9a48"), "sky": Color("9fd3e6"), "frame": Color("4a321e"), "sun": Color("fff4dc")},
	{"name": "Sunset Desert", "decor": "cacti", "light": Color("f3dfb0"), "dark": Color("c0763a"),
		"ground": Color("e0b877"), "sky": Color("f2b27a"), "frame": Color("5a3418"), "sun": Color("ffd9a8")},
	{"name": "Frost Citadel", "decor": "crystals", "light": Color("e6f1fa"), "dark": Color("5d7fa8"),
		"ground": Color("c9dceb"), "sky": Color("3a4d73"), "frame": Color("24324d"), "sun": Color("dcebff")},
	{"name": "Shadow Keep", "decor": "pillars", "light": Color("b9adc9"), "dark": Color("4a3a66"),
		"ground": Color("2c2438"), "sky": Color("151022"), "frame": Color("1a1424"), "sun": Color("e2c8ff")},
]

var back_rank := [Rules.ROOK, Rules.KNIGHT, Rules.BISHOP, Rules.QUEEN, Rules.KING, Rules.BISHOP, Rules.KNIGHT, Rules.ROOK]

var board := []
var roster := []  # The player's 16 pieces; they keep their upgrades between rounds.
var enemy_upgrades := []  # {card, type} applied to every new enemy army.
var round_no := 1
var state := State.BUSY
var selected := -1
var targets := []

var _squares := []
var _markers := []
var _square_mats := []
var _marker_mats := {}
var _ground_mat := StandardMaterial3D.new()
var _frame_mat := StandardMaterial3D.new()
var _banner_tween: Tween

@onready var camera: Camera3D = $Camera3D
@onready var sun: DirectionalLight3D = $Sun
@onready var environment: Environment = $WorldEnvironment.environment
@onready var board_root: Node3D = $Board
@onready var decor_root: Node3D = $Decor
@onready var marker_root: Node3D = $Markers
@onready var pieces_root: Node3D = $Pieces
@onready var round_label: Label = $UI/RoundLabel
@onready var turn_label: Label = $UI/TurnLabel
@onready var info_label: Label = $UI/InfoPanel/InfoLabel
@onready var enemy_label: Label = $UI/EnemyPanel/EnemyLabel
@onready var banner: Label = $UI/Banner
@onready var overlay: Control = $UI/CardOverlay
@onready var card_title: Label = $UI/CardOverlay/Box/CardTitle
@onready var card_sub: Label = $UI/CardOverlay/Box/CardSub
@onready var card_row: HBoxContainer = $UI/CardOverlay/Box/CardRow


func _ready():
	randomize()
	camera.position = Vector3(0, 9.6, 8.4)
	camera.look_at(Vector3(0, 0, 0.75))
	sun.rotation_degrees = Vector3(-52, -38, 0)
	_build_board()
	new_run()


# --- Run / round setup ------------------------------------------------------

func new_run():
	round_no = 1
	enemy_upgrades.clear()
	roster.clear()
	for c in 8:
		roster.append(PieceData.new(back_rank[c], Rules.WHITE, c))
		roster.append(PieceData.new(Rules.PAWN, Rules.WHITE, 8 + c))
	start_round(0)


func make_enemy_army() -> Array:
	var army := []
	for c in 8:
		var type: int = back_rank[c]
		# The first rounds are a warm-up: the enemy brings its heavy pieces later.
		if round_no == 1 and (type == Rules.ROOK or type == Rules.QUEEN):
			continue
		if round_no == 2 and type == Rules.QUEEN:
			continue
		army.append(PieceData.new(type, Rules.BLACK, 56 + c))
	for c in 8:
		army.append(PieceData.new(Rules.PAWN, Rules.BLACK, 48 + c))
	for up in enemy_upgrades:
		Rules.give_to_type(up, army)
	return army


func start_round(new_enemy_cards: int):
	for view in pieces_root.get_children():
		view.queue_free()
	board.clear()
	board.resize(64)

	var army := make_enemy_army()
	var gained := []
	for k in new_enemy_cards:
		var options := Rules.type_options(army, 1)
		if options.is_empty():
			break
		enemy_upgrades.append(options[0])
		Rules.give_to_type(options[0], army)
		gained.append(_type_card_name(options[0]))

	for p in roster:
		p.shield = p.max_shield
		board[p.home] = p
		_spawn(p)
	for p in army:
		board[p.home] = p
		_spawn(p)

	var theme: Dictionary = THEMES[(round_no - 1) % THEMES.size()]
	_apply_theme(theme)
	round_label.text = "Round %d - %s" % [round_no, theme.name]
	_refresh_enemy_label()
	_deselect()
	state = State.PLAYER
	turn_label.text = "Your turn"
	if gained.is_empty():
		show_banner("Round %d\nCapture the enemy King!" % round_no)
	else:
		show_banner("Round %d\nEnemy gained: %s" % [round_no, ", ".join(gained)], 4.0)


func ai_depth() -> int:
	return 2 if round_no < 2 else 3


# --- Input ------------------------------------------------------------------

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		var sq := _square_at(event.position)
		if sq >= 0 and board[sq] != null:
			_show_info(board[sq])
		elif selected >= 0 and board[selected] != null:
			_show_info(board[selected])
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click(_square_at(event.position))


func _square_at(mouse: Vector2) -> int:
	var origin := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	# Slightly above the board so clicking a piece's body picks its own square.
	var hit = Plane(Vector3.UP, 0.25).intersects_ray(origin, dir)
	if hit == null:
		return -1
	var c := int(floor(hit.x + 4.0))
	var r := int(floor(4.0 - hit.z))
	if r < 0 or r > 7 or c < 0 or c > 7:
		return -1
	return r * 8 + c


func _click(sq: int):
	if state != State.PLAYER or sq < 0:
		return
	if selected >= 0 and board[selected] != null and board[selected].side == Rules.WHITE and targets.has(sq):
		_player_move(selected, sq)
	elif board[sq] != null:
		_select(sq)
	else:
		_deselect()


func _select(sq: int):
	_deselect()
	selected = sq
	targets = Rules.moves(board, sq)
	var mine: bool = board[sq].side == Rules.WHITE
	_mark(sq, "select")
	for t in targets:
		if not mine:
			_mark(t, "enemy")
		elif board[t] != null:
			_mark(t, "capture")
		else:
			_mark(t, "move")
	_show_info(board[sq])


func _deselect():
	selected = -1
	targets = []
	for marker in _markers:
		marker.visible = false


# --- Turns ------------------------------------------------------------------

func _player_move(from: int, to: int):
	state = State.BUSY
	_deselect()
	if await _perform(from, to, true):
		return
	await _enemy_turn()


func _enemy_turn():
	turn_label.text = "Enemy is thinking..."
	await get_tree().create_timer(0.3).timeout
	var m := Rules.best_move(board, Rules.BLACK, ai_depth())
	if m < 0:
		await _end_round(true)
		return
	if await _perform(m >> 6, m & 63, false):
		return
	if Rules.all_moves(board, Rules.WHITE).is_empty():
		await _end_round(false)
		return
	state = State.PLAYER
	turn_label.text = "Your turn"


## Plays one move with animation. Returns true when the round has ended.
func _perform(from: int, to: int, is_player: bool) -> bool:
	var mover: PieceData = board[from]
	var u := Rules.apply(board, from, to, not is_player)
	var victim: PieceData = u.t

	if u.blocked:
		await _anim_bump(mover.view, from, to)
		victim.view.refresh()
		show_banner("Blocked by a shield!", 1.2)
		return false

	await _anim_move(mover.view, to)

	if u.thorns:
		show_banner("Thorns! Both pieces fall.", 1.4)
		_anim_remove(victim.view)
		await _anim_remove(mover.view)
		return false

	if victim != null:
		_anim_remove(victim.view)
		mover.view.refresh()
		if u.king:
			await _end_round(mover.side == Rules.WHITE)
			return true
		await _gain_xp(mover, Rules.XP_VALUE[victim.type], is_player)

	if u.promoted:
		await _promote(mover, is_player)
	return false


func _gain_xp(piece: PieceData, amount: int, is_player: bool):
	piece.xp += amount
	while piece.xp >= piece.xp_needed():
		piece.xp -= piece.xp_needed()
		piece.level += 1
		var options := Rules.piece_options(piece)
		if not options.is_empty():
			if is_player:
				var i: int = await choose("%s reached Lv.%d!" % [Rules.TYPE_NAMES[piece.type], piece.level],
						"Choose an upgrade for this piece", options)
				Rules.give(options[i], piece)
			else:
				Rules.give(options[0], piece)
				show_banner("Enemy %s reached Lv.%d: %s" % [Rules.TYPE_NAMES[piece.type], piece.level, options[0].name], 1.8)
		piece.view.refresh()


## A pawn on the far rank is upgraded twice, then turns into another piece.
func _promote(piece: PieceData, is_player: bool):
	if is_player:
		for k in 2:
			var options := Rules.piece_options(piece, 3, false)
			if options.is_empty():
				break
			var i: int = await choose("Pawn promotion - upgrade %d of 2" % (k + 1),
					"This pawn keeps its upgrades after it transforms", options)
			Rules.give(options[i], piece)
			piece.view.refresh()
		var types := [Rules.QUEEN, Rules.ROOK, Rules.BISHOP, Rules.KNIGHT]
		var shown := []
		for t in types:
			shown.append({"name": Rules.TYPE_NAMES[t], "desc": "Transform this pawn into a %s." % Rules.TYPE_NAMES[t]})
		var pick: int = await choose("Pawn promotion", "Choose what the pawn becomes", shown)
		piece.type = types[pick]
	else:
		# The AI's pawn already became a Queen inside Rules.apply().
		for k in 2:
			var options := Rules.piece_options(piece, 1)
			if not options.is_empty():
				Rules.give(options[0], piece)
		show_banner("An enemy pawn was promoted!", 1.8)
	piece.view.rebuild()


func _end_round(player_won: bool):
	state = State.BUSY
	if player_won:
		var options := Rules.type_options(roster, 3)
		if not options.is_empty():
			var shown := []
			for o in options:
				shown.append({"name": _type_card_name(o), "desc": o.card.desc})
			var i: int = await choose("Round %d cleared!" % round_no,
					"Reward: upgrade every piece of one type", shown)
			Rules.give_to_type(options[i], roster)
		round_no += 1
		start_round(ENEMY_CARDS_PER_ROUND)
	else:
		state = State.OVER
		turn_label.text = "Defeated"
		await choose("Defeated in Round %d" % round_no, "Your King has fallen.",
				[{"name": "Try again", "desc": "Start a new run from Round 1."}])
		new_run()


# --- Cards UI ---------------------------------------------------------------

## Shows the options as cards and returns the index the player picked.
func choose(title: String, subtitle: String, options: Array) -> int:
	for child in card_row.get_children():
		child.queue_free()
	card_title.text = title
	card_sub.text = subtitle
	for i in options.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(250, 220)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text = "%s\n\n%s" % [options[i].name, options[i].desc]
		button.add_theme_font_size_override("font_size", 20)
		button.pressed.connect(func(): card_picked.emit(i))
		card_row.add_child(button)
	overlay.show()
	var picked: int = await card_picked
	overlay.hide()
	return picked


func show_banner(text: String, seconds := 2.5):
	if _banner_tween != null:
		_banner_tween.kill()
	banner.text = text
	banner.modulate.a = 1.0
	banner.show()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(seconds)
	_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	_banner_tween.tween_callback(banner.hide)


func _show_info(p: PieceData):
	var lines := ["%s %s   Lv.%d" % ["Your" if p.side == Rules.WHITE else "Enemy", Rules.TYPE_NAMES[p.type], p.level]]
	lines.append("XP %d / %d" % [p.xp, p.xp_needed()])
	if p.max_shield > 0 or p.shield > 0:
		lines.append("Shield %d / %d" % [p.shield, p.max_shield])
	for ability in Rules.ability_names(p):
		lines.append("- " + ability)
	info_label.text = "\n".join(lines)


func _refresh_enemy_label():
	var lines := ["Enemy upgrades"]
	if enemy_upgrades.is_empty():
		lines.append("(none yet)")
	for up in enemy_upgrades:
		lines.append("- " + _type_card_name(up))
	enemy_label.text = "\n".join(lines)


func _type_card_name(up: Dictionary) -> String:
	return "%ss: %s" % [Rules.TYPE_NAMES[up.type], up.card.name]


# --- Board visuals ----------------------------------------------------------

func sq_pos(sq: int) -> Vector3:
	return Vector3((sq & 7) - 3.5, 0, 3.5 - (sq >> 3))


func _spawn(p: PieceData):
	var view := PieceView.new()
	pieces_root.add_child(view)
	view.setup(p)
	view.position = sq_pos(p.home)


func _build_board():
	_square_mats = [StandardMaterial3D.new(), StandardMaterial3D.new()]
	var tile := BoxMesh.new()
	tile.size = Vector3(1, 0.2, 1)
	var dot := CylinderMesh.new()
	dot.top_radius = 0.2
	dot.bottom_radius = 0.2
	dot.height = 0.03
	for sq in 64:
		var square := MeshInstance3D.new()
		square.mesh = tile
		square.material_override = _square_mats[((sq >> 3) + (sq & 7) + 1) % 2]
		square.position = sq_pos(sq) + Vector3(0, -0.1, 0)
		board_root.add_child(square)
		_squares.append(square)

		var marker := MeshInstance3D.new()
		marker.mesh = dot
		marker.position = sq_pos(sq) + Vector3(0, 0.02, 0)
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		marker.visible = false
		marker_root.add_child(marker)
		_markers.append(marker)

	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(8.7, 0.3, 8.7)
	frame.mesh = frame_mesh
	frame.material_override = _frame_mat
	frame.position.y = -0.2
	board_root.add_child(frame)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	ground.mesh = plane
	ground.material_override = _ground_mat
	ground.position.y = -0.36
	board_root.add_child(ground)

	for kind in ["move", "capture", "select", "enemy"]:
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_marker_mats[kind] = mat
	_marker_mats.move.albedo_color = Color(0.2, 0.9, 0.4, 0.8)
	_marker_mats.capture.albedo_color = Color(1.0, 0.25, 0.25, 0.7)
	_marker_mats.select.albedo_color = Color(1.0, 0.85, 0.2, 0.6)
	_marker_mats.enemy.albedo_color = Color(1.0, 0.55, 0.15, 0.7)


func _mark(sq: int, kind: String):
	var marker: MeshInstance3D = _markers[sq]
	marker.material_override = _marker_mats[kind]
	var size := 1.0 if kind == "move" or kind == "enemy" else 2.2
	marker.scale = Vector3(size, 1, size)
	marker.visible = true


func _apply_theme(theme: Dictionary):
	_square_mats[0].albedo_color = theme.light
	_square_mats[1].albedo_color = theme.dark
	_frame_mat.albedo_color = theme.frame
	_ground_mat.albedo_color = theme.ground
	environment.background_color = theme.sky
	environment.ambient_light_color = theme.sky.lerp(Color.WHITE, 0.6)
	sun.light_color = theme.sun

	for child in decor_root.get_children():
		child.queue_free()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(theme.name)
	var placed := 0
	while placed < 26:
		var pos := Vector3(rng.randf_range(-15, 15), -0.36, rng.randf_range(-16, 3.5))
		if abs(pos.x) < 5.6 and pos.z > -5.6:
			continue  # Keep the board itself clear.
		_add_prop(theme.decor, pos, rng)
		placed += 1


func _add_prop(kind: String, pos: Vector3, rng: RandomNumberGenerator):
	var prop := Node3D.new()
	prop.position = pos
	prop.rotation.y = rng.randf() * TAU
	var s := rng.randf_range(0.8, 1.5)
	prop.scale = Vector3(s, s, s)
	decor_root.add_child(prop)
	match kind:
		"trees":
			_prop_cyl(prop, 0.14, 0.14, 0.7, 0.0, Color("6b4a2b"))
			_prop_cyl(prop, 0.75, 0.0, 1.3, 0.6, Color("3f8f3a"), 7)
			_prop_cyl(prop, 0.55, 0.0, 1.1, 1.3, Color("4faa45"), 7)
		"cacti":
			if rng.randf() < 0.6:
				_prop_cyl(prop, 0.22, 0.2, 1.5, 0.0, Color("4f9a55"), 8)
				_prop_cyl(prop, 0.12, 0.12, 0.6, 0.6, Color("4f9a55"), 8).position.x = 0.36
				_prop_cyl(prop, 0.12, 0.12, 0.5, 0.4, Color("4f9a55"), 8).position.x = -0.36
			else:
				_prop_cyl(prop, 0.9, 0.0, 1.1, 0.0, Color("c99a5a"), 4)
		"crystals":
			_prop_cyl(prop, 0.35, 0.0, 1.8, 0.0, Color("a8dcff"), 5).rotation.z = rng.randf_range(-0.3, 0.3)
			_prop_cyl(prop, 0.22, 0.0, 1.0, 0.0, Color("d8f1ff"), 5).position.x = 0.4
		"pillars":
			_prop_cyl(prop, 0.4, 0.4, 0.2, 0.0, Color("5a4f6e"), 6)
			_prop_cyl(prop, 0.28, 0.28, rng.randf_range(1.2, 2.6), 0.2, Color("6c6082"), 6)
			_prop_cyl(prop, 0.12, 0.0, 0.3, 0.0, Color("c084ff"), 5).position = Vector3(0.6, 0.15, 0)


func _prop_cyl(parent: Node3D, bottom: float, top: float, height: float, y: float, color: Color, segments := 8) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position.y = y + height / 2.0
	parent.add_child(node)
	return node


# --- Animations -------------------------------------------------------------

func _anim_move(view: Node3D, to: int):
	var target := sq_pos(to)
	var mid := (view.position + target) / 2.0 + Vector3(0, 0.6, 0)
	var tween := create_tween()
	tween.tween_property(view, "position", mid, 0.14).set_ease(Tween.EASE_OUT)
	tween.tween_property(view, "position", target, 0.14).set_ease(Tween.EASE_IN)
	await tween.finished


func _anim_bump(view: Node3D, from: int, to: int):
	var home := sq_pos(from)
	var tween := create_tween()
	tween.tween_property(view, "position", home.lerp(sq_pos(to), 0.6), 0.12)
	tween.tween_property(view, "position", home, 0.16)
	await tween.finished


func _anim_remove(view: Node3D):
	var tween := create_tween()
	tween.tween_property(view, "scale", Vector3(0.01, 0.01, 0.01), 0.18)
	tween.tween_callback(view.queue_free)
	await tween.finished
