extends Control

@onready var play_button : Button = $MenuPanel/MarginContainer/VBoxContainer/ButtonPlay
@onready var exit_button : Button = $MenuPanel/MarginContainer/VBoxContainer/ButtonExit

func _ready() -> void:
	pass

func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/map_generator.tscn")
