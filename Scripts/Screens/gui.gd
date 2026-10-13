extends Control

## GAME MANAGER ## 

@onready var countdown_timer: Timer = GAMEMANAGER.countdown_timer
@onready var game_timer: Timer = GAMEMANAGER.game_timer

## NODES ##

@onready var timer_label: Label = $GameTimerLabel
@onready var hunger_label: Label = $HungerLabel
@onready var score_label: Label = $ScoreLabel

func _process(_delta: float) -> void:
	# Timer
	if not game_timer.is_stopped():
		timer_label.text = str(int(game_timer.time_left))
	else:
		timer_label.text = str(int(countdown_timer.time_left + 1))
	
	# Hunger
	hunger_label.text = "Hunger: " + str(GAMEMANAGER.current_hunger)
	score_label.text = "Score: " + str(GAMEMANAGER.score)
