class_name Rules
extends RefCounted
## Board rules, upgrade cards and the enemy AI.
##
## The board is an Array of 64 PieceData (or null). Index = row * 8 + col,
## row 0 is White's home rank. A round is won by capturing the enemy King,
## so there is no check / checkmate rule.

enum { PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING }

const WHITE := 0
const BLACK := 1

# Ability flags (PieceData.abilities).
const A_STEP := 1
const A_LEAP := 2
const A_ORTHO := 4
const A_DIAG := 8
const A_SPRINT := 16
const A_THORNS := 32
const A_GUARD := 64

const MAX_SHIELD := 3
const REACH := 2  # Range granted by Rook's / Bishop's Reach.

const TYPE_NAMES := ["Pawn", "Knight", "Bishop", "Rook", "Queen", "King"]
const VALUE := [100, 320, 330, 500, 900, 100000]
const XP_VALUE := [1, 3, 3, 5, 9, 0]

const KNIGHT_D := [[1, 2], [2, 1], [2, -1], [1, -2], [-1, -2], [-2, -1], [-2, 1], [-1, 2]]
const ORTHO_D := [[1, 0], [-1, 0], [0, 1], [0, -1]]
const DIAG_D := [[1, 1], [1, -1], [-1, 1], [-1, -1]]
const ALL_D := [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [1, -1], [-1, 1], [-1, -1]]

# bit 0 means "shield" (stackable), anything else is an ability flag.
const CARDS := [
	{"id": "shield", "bit": 0, "name": "Shield",
		"desc": "Blocks one capture each round. Stacks up to 3."},
	{"id": "step", "bit": A_STEP, "name": "King's Step",
		"desc": "Can also move or capture 1 square in any direction."},
	{"id": "leap", "bit": A_LEAP, "name": "Knight's Leap",
		"desc": "Can also jump like a Knight."},
	{"id": "ortho", "bit": A_ORTHO, "name": "Rook's Reach",
		"desc": "Can also slide up to 2 squares in straight lines."},
	{"id": "diag", "bit": A_DIAG, "name": "Bishop's Reach",
		"desc": "Can also slide up to 2 squares diagonally."},
	{"id": "sprint", "bit": A_SPRINT, "name": "Sprint",
		"desc": "Pawn may always advance 2 squares."},
	{"id": "thorns", "bit": A_THORNS, "name": "Thorns",
		"desc": "When captured, the attacker is destroyed too (Kings are immune)."},
	{"id": "guard", "bit": A_GUARD, "name": "Battle Guard",
		"desc": "Capturing an enemy grants a shield if it has none."},
]


# --- Movement ---------------------------------------------------------------

static func moves(b: Array, from: int) -> Array:
	var p: PieceData = b[from]
	var out := []
	var r := from >> 3
	var c := from & 7
	var ab := p.abilities
	var t := p.type

	if t == PAWN:
		var dir := 1 if p.side == WHITE else -1
		var start := 1 if p.side == WHITE else 6
		var r1 := r + dir
		if r1 >= 0 and r1 < 8:
			if b[r1 * 8 + c] == null:
				out.append(r1 * 8 + c)
				var r2 := r1 + dir
				if (r == start or (ab & A_SPRINT) != 0) and r2 >= 0 and r2 < 8 and b[r2 * 8 + c] == null:
					out.append(r2 * 8 + c)
			for dc in [-1, 1]:
				var cc: int = c + dc
				if cc >= 0 and cc < 8:
					var q = b[r1 * 8 + cc]
					if q != null and q.side != p.side:
						out.append(r1 * 8 + cc)

	if t == KNIGHT or (ab & A_LEAP) != 0:
		_jumps(b, p, r, c, KNIGHT_D, out)
	if t == KING or (ab & A_STEP) != 0:
		_jumps(b, p, r, c, ALL_D, out)

	var ortho := 7 if (t == ROOK or t == QUEEN) else (REACH if (ab & A_ORTHO) != 0 else 0)
	var diag := 7 if (t == BISHOP or t == QUEEN) else (REACH if (ab & A_DIAG) != 0 else 0)
	if ortho > 0:
		_slides(b, p, r, c, ORTHO_D, ortho, out)
	if diag > 0:
		_slides(b, p, r, c, DIAG_D, diag, out)
	return out


static func _jumps(b: Array, p: PieceData, r: int, c: int, dirs: Array, out: Array) -> void:
	for d in dirs:
		var rr: int = r + d[0]
		var cc: int = c + d[1]
		if rr < 0 or rr > 7 or cc < 0 or cc > 7:
			continue
		var i := rr * 8 + cc
		var q = b[i]
		if (q == null or q.side != p.side) and not out.has(i):
			out.append(i)


static func _slides(b: Array, p: PieceData, r: int, c: int, dirs: Array, reach: int, out: Array) -> void:
	for d in dirs:
		var rr := r
		var cc := c
		for k in reach:
			rr += d[0]
			cc += d[1]
			if rr < 0 or rr > 7 or cc < 0 or cc > 7:
				break
			var i := rr * 8 + cc
			var q = b[i]
			if q == null:
				if not out.has(i):
					out.append(i)
			else:
				if q.side != p.side and not out.has(i):
					out.append(i)
				break


## Every move for `side`, packed as from * 64 + to, captures first.
static func all_moves(b: Array, side: int) -> Array:
	var captures := []
	var quiet := []
	for i in 64:
		var p = b[i]
		if p == null or p.side != side:
			continue
		for t in moves(b, i):
			if b[t] != null:
				captures.append(i * 64 + t)
			else:
				quiet.append(i * 64 + t)
	captures.append_array(quiet)
	return captures


## Plays a move on the board and returns what happened (also used to undo).
## `auto_promote` turns a pawn on the last rank into a Queen straight away.
static func apply(b: Array, from: int, to: int, auto_promote := true) -> Dictionary:
	var p: PieceData = b[from]
	var t: PieceData = b[to]
	var u := {
		"from": from, "to": to, "p": p, "t": t,
		"p_shield": p.shield, "t_shield": 0 if t == null else t.shield, "p_type": p.type,
		"blocked": false, "thorns": false, "promoted": false, "king": false,
	}
	if t != null:
		if t.shield > 0:
			# The shield absorbs the hit and the attacker stays where it was.
			t.shield -= 1
			u.blocked = true
			return u
		u.king = t.type == KING
		if (t.abilities & A_THORNS) != 0 and p.type != KING:
			b[to] = null
			b[from] = null
			u.thorns = true
			return u
		if (p.abilities & A_GUARD) != 0 and p.shield < 1:
			p.shield = 1
	b[to] = p
	b[from] = null
	if p.type == PAWN and (to >> 3) == (7 if p.side == WHITE else 0):
		u.promoted = true
		if auto_promote:
			p.type = QUEEN
	return u


static func undo(b: Array, u: Dictionary) -> void:
	var p: PieceData = u.p
	b[u.from] = p
	b[u.to] = u.t
	p.shield = u.p_shield
	p.type = u.p_type
	if u.t != null:
		u.t.shield = u.t_shield


# --- AI ---------------------------------------------------------------------

static func evaluate(b: Array, side: int) -> float:
	var score := 0.0
	for i in 64:
		var p: PieceData = b[i]
		if p == null:
			continue
		var v: float = VALUE[p.type] + 25.0 * p.ability_count + 50.0 * p.shield
		var r := i >> 3
		var c := i & 7
		if p.type == PAWN:
			v += 10.0 * (r if p.side == WHITE else 7 - r)
		elif p.type != KING:
			v += 6.0 * (3.5 - max(abs(r - 3.5), abs(c - 3.5)))
		score += v if p.side == side else -v
	return score


static func _negamax(b: Array, side: int, depth: int, alpha: float, beta: float) -> float:
	if depth == 0:
		return evaluate(b, side)
	var list := all_moves(b, side)
	if list.is_empty():
		return -900000.0
	var best := -1e9
	for m in list:
		var u := apply(b, m >> 6, m & 63)
		var s: float
		if u.king:
			s = 1000000.0 + depth
		else:
			s = -_negamax(b, 1 - side, depth - 1, -beta, -alpha)
		undo(b, u)
		if s > best:
			best = s
		if best > alpha:
			alpha = best
		if alpha >= beta:
			break
	return best


## Best move for `side` (packed from * 64 + to), or -1 when there is none.
static func best_move(b: Array, side: int, depth: int) -> int:
	var best := -1
	var best_score := -1e12
	for m in all_moves(b, side):
		var u := apply(b, m >> 6, m & 63)
		var s: float
		if u.king:
			s = 1000000.0 + depth
		else:
			s = -_negamax(b, 1 - side, depth - 1, -1e9, 1e9)
		undo(b, u)
		s += randf() * 6.0  # A little variety between equal moves.
		if s > best_score:
			best_score = s
			best = m
	return best


# --- Upgrade cards ----------------------------------------------------------

static func card_valid(card: Dictionary, type: int) -> bool:
	match card.id:
		"step":
			return type != QUEEN and type != KING
		"leap":
			return type != KNIGHT
		"ortho":
			return type != ROOK and type != QUEEN and type != KING
		"diag":
			return type != BISHOP and type != QUEEN and type != KING
		"sprint":
			return type == PAWN
		"thorns":
			return type != KING
	return true


static func can_take(card: Dictionary, p: PieceData) -> bool:
	if not card_valid(card, p.type):
		return false
	if card.bit == 0:
		return p.max_shield < MAX_SHIELD
	return (p.abilities & card.bit) == 0


static func give(card: Dictionary, p: PieceData) -> void:
	if card.bit == 0:
		p.max_shield += 1
		p.shield += 1
	else:
		p.abilities |= card.bit
		p.ability_count += 1


## Up to `count` random cards this single piece can still take.
static func piece_options(p: PieceData, count := 3, allow_sprint := true) -> Array:
	var pool := []
	for card in CARDS:
		if can_take(card, p) and (allow_sprint or card.id != "sprint"):
			pool.append(card)
	pool.shuffle()
	return pool.slice(0, count)


## Up to `count` random {card, type} upgrades that affect a whole piece type.
static func type_options(pieces: Array, count := 3) -> Array:
	var pool := []
	for type in 6:
		for card in CARDS:
			for p in pieces:
				if p.type == type and can_take(card, p):
					pool.append({"card": card, "type": type})
					break
	pool.shuffle()
	return pool.slice(0, count)


static func give_to_type(up: Dictionary, pieces: Array) -> void:
	for p in pieces:
		if p.type == up.type and can_take(up.card, p):
			give(up.card, p)


static func ability_names(p: PieceData) -> Array:
	var names := []
	for card in CARDS:
		if card.bit != 0 and (p.abilities & card.bit) != 0:
			names.append(card.name)
	return names
