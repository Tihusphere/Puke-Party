extends Node3D

var map_size: Vector2i = Vector2i(3, 3)
var map: Array

var Rooms: Dictionary = {
	"center": {"scene": preload("uid://dxrhmjmi2oxr7"), "icon": "╬"},
	"corner_hallway": {"scene": preload("uid://d3fg28omtx7iq"), "icon": "┌"},
	"corner_room": {"scene": preload("uid://db5qpe6fny7fg"), "icon": "╔"},
	"side_hallway": {"scene": preload("uid://kewdmsc5g714"), "icon": "│"},
	"side_room": {"scene": preload("uid://cwwfrbi1n3ndq"), "icon": "║"},
	"t_hallway": {"scene": preload("uid://cc5aopk1qipps"), "icon": "├"},
	"t_room": {"scene": preload("uid://7u2koin6i58b"), "icon": "╠"},
}

var RoomTypes: Dictionary = {
	"center" = [
		Rooms["center"]["icon"]
	],
	"corner" = [
		Rooms["corner_hallway"]["icon"],
		Rooms["corner_room"]["icon"]
	],
	"side" = [
		Rooms["side_hallway"]["icon"],
		Rooms["side_room"]["icon"],
		Rooms["t_hallway"]["icon"],
		Rooms["t_room"]["icon"],
	]
}

var spawn_room: Vector2i

func initialize_map() -> void:
	for x in map_size.x:
		map.append([])
		for y in map_size.y:
			map[x].append(0)

func randomize_map() -> void:
	spawn_room = Vector2i(randi_range(0, map_size.x - 1), randi_range(0, map_size.y - 1))
	for x in range(map_size.x):
		for y in range(map_size.y):
			var room_type: Array
			if x == 1 and y == 1:
				room_type = RoomTypes["center"]
			elif (x == 0 or x == map_size.x - 1) and (y == 0 or y == map_size.y - 1):
				room_type = RoomTypes["corner"]
			else:
				room_type = RoomTypes["side"]
			map[x][y] = room_type[randi_range(0, room_type.size() - 1)]

func map_to_string() -> String:
	var map_as_string: String = ""
	for y in range(map_size.y - 1, -1, -1):
		for x in map_size.x:
			map_as_string += "[" + str(map[x][y]) + "]"
		map_as_string += "\n"
	return map_as_string

func _ready() -> void:
	initialize_map()
	print("Test 1")
	randomize_map()
	print(map_to_string())
	print("Test 2")
	randomize_map()
	print(map_to_string())
	print("Test 3")
	randomize_map()
	print(map_to_string())
