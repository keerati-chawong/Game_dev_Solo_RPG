extends Control

# ---------- VARIABLES ---------- #

@onready var coinsLabel = $CoinsLabel

# ---------- FUNCTIONS ---------- #

func _process(_delta):
	# Set the coin label text to the score variable
	coinsLabel.text = "x %d / %d" % [GameManager.score, GameManager.coins_total]
	$DeathsLabel.text = "Retries: %d" % GameManager.deaths
