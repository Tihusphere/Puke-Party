extends Control

@onready var timer_label: Label = $GameTimerLabel
@onready var countdown_timer: Timer = GAMEMANAGER.countdown_timer
@onready var game_timer: Timer = GAMEMANAGER.game_timer


func _process(_delta: float) -> void:
	if not game_timer.is_stopped():
		timer_label.text = str(int(game_timer.time_left))
	else:
		timer_label.text = str(int(countdown_timer.time_left + 1))
