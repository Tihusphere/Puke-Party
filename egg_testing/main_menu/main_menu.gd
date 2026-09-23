class_name MainMenu extends Node2D

var test_scene_path: String = "res://Scenes/test.tscn"

func _ready() -> void:
	if SaveSystem.saveNum <= 0:
		%ButtonContinue.visible = false
		%ButtonLoadGame.visible = false
		
	%ButtonContinue.pressed.connect(_on_button_continue_pressed)
	%ButtonNewGame.pressed.connect(_on_button_new_game_pressed)
	%ButtonLoadGame.pressed.connect(_on_button_load_game_pressed)
	%ButtonExit.pressed.connect(_on_button_exit_pressed)

func _on_button_continue_pressed() -> void:
	pass

func _on_button_new_game_pressed() -> void:
	pass

func _on_button_load_game_pressed() -> void:
	pass

func _on_button_exit_pressed() -> void:
	pass
