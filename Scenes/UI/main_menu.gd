extends Control

@onready var play_button : Button = $MenuPanel/MarginContainer/VBoxContainer/ButtonPlay
@onready var exit_button : Button = $MenuPanel/MarginContainer/VBoxContainer/ButtonExit

@export var tutorialScreen : Panel

func _ready() -> void:
	pass

func _on_button_play_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/map_generator.tscn")


func _on_button_exit_pressed() -> void:
	tutorialScreen.visible = true


func _on_close_pressed() -> void:
	tutorialScreen.visible = false
