# Implied class_name SaveSystem
extends Node

signal save_loaded(save_data : SaveData)
signal save_saved(save_data : SaveData)

const SAVE_DIRECTORY = "user://saves"

var saveNum : int = 0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"quick_save"):
		save_data(1, SaveData.new())
	
	if event.is_action_pressed(&"quick_load"):
		load_data(1)

func save_data(save_slot : int, data : SaveData):
	if not DirAccess.dir_exists_absolute(SAVE_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)
	

func load_data(save_slot : int):
	return
