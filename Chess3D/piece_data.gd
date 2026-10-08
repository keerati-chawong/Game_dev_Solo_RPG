class_name PieceData
extends RefCounted
## State of one chess piece: what it is plus everything it has earned.

var type: int
var side: int
var home: int  # Board index the piece starts each round on.

var abilities := 0  # Bitmask of Rules.A_* flags.
var ability_count := 0
var max_shield := 0
var shield := 0
var xp := 0
var level := 1

var view: Node3D = null


func _init(p_type: int, p_side: int, p_home: int):
	type = p_type
	side = p_side
	home = p_home


func xp_needed() -> int:
	return level * 3
