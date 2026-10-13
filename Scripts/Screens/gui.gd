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

@onready var speed_label := $Notifications/SpeedLabel
@onready var jump_label := $Notifications/JumpLabel
@onready var rainbow_label := $Notifications/RainbowLabel

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

	# Score
	score_label.text = "Score: " + str(GAMEMANAGER.score)

	# Notifications
	match GAMEMANAGER.get_active_pickup():
		PickUpController.Buff.SPEED:
			speed_label.show()
			jump_label.hide()
			rainbow_label.hide()
		PickUpController.Buff.JUMP:
			speed_label.hide()
			jump_label.show()
			rainbow_label.hide()
		PickUpController.Buff.RAINBOW:
			speed_label.hide()
			jump_label.hide()
			rainbow_label.show()
		null:
			speed_label.hide()
			jump_label.hide()
			rainbow_label.hide()
		_:
			speed_label.show()
			jump_label.show()
			rainbow_label.show()