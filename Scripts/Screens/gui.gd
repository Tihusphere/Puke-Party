extends Control

## GAME MANAGER ## 

@onready var countdown_timer: Timer = GAMEMANAGER.countdown_timer
@onready var game_timer: Timer = GAMEMANAGER.game_timer

## NODES ##

@onready var timer_label: Label = $GameTimerLabel
@onready var score_label: Label = $ScoreLabel

@onready var hunger_bar: TextureProgressBar = $HungerBar
@onready var hunger_label: Label = $HungerBar/HungerLabel
var divisor: int = GAMEMANAGER.MAX_HUNGER / 100

func _process(_delta: float) -> void:
	# Timer
	if not game_timer.is_stopped():
		timer_label.text = str(int(game_timer.time_left))
	else:
		timer_label.text = str(int(countdown_timer.time_left + 1))
	
	# Hunger
	hunger_bar.min_value = 0
	hunger_bar.max_value = GAMEMANAGER.MAX_HUNGER
	hunger_bar.set_value(GAMEMANAGER.current_hunger)

	hunger_label.text = str(GAMEMANAGER.current_hunger / divisor) + " / 100"
	score_label.text = "Score: " + str(GAMEMANAGER.score)
