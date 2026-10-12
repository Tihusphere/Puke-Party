class_name MapGenerator
extends Node3D

@onready var grid_map: GridMap = $GridMap
@onready var rooms: Node3D = $Rooms
@onready var bg_music: AudioStreamPlayer = $BackgroundMusic

var map_size: Vector2i = Vector2i(3, 3)
var map: Array

var player_scene = preload("res://Scenes/player_controller.tscn")
var pickup_scene = preload("res://Scenes/Resources/pick_up.tscn")

# Stores room scene data
var Rooms: Dictionary = {
	"center": preload("uid://dxrhmjmi2oxr7"),
	"corner_hallway": preload("uid://d3fg28omtx7iq"),
	"corner_room": preload("uid://db5qpe6fny7fg"),
	"side_hallway": preload("uid://kewdmsc5g714"),
	"side_room": preload("uid://cwwfrbi1n3ndq"),
	"t_hallway": preload("uid://cc5aopk1qipps"),
	"t_room": preload("uid://7u2koin6i58b"),
}

# Stores similar rooms
var RoomTypes: Dictionary = {
	"center" = [
		Rooms["center"]
	],
	"corner" = [
		Rooms["corner_hallway"],
		Rooms["corner_room"]
	],
	"side" = [
		Rooms["side_hallway"],
		Rooms["side_room"]
	],
	"t" = [
		Rooms["t_hallway"],
		Rooms["t_room"]
	]
}

# Creates an nested array using map_size
func initialize_map() -> void:
	for x in map_size.x:
		map.append([])
		for y in map_size.y:
			map[x].append(0)

# Picks a random room based on the index of the map array
func randomize_map() -> void:
	var sideCount: int = 0 # Notifies how many side rooms have been generated (up to 4)
	var hasT: bool = false # DeterminRangees whether a side room is a T variation

	for x in map_size.x:
		for y in map_size.y:
			var room_type: Array
			# Choose room type
			if x == 1 and y == 1:
				room_type = RoomTypes["center"]
			elif (x == 0 or x == map_size.x - 1) and (y == 0 or y == map_size.y - 1):
				room_type = RoomTypes["corner"]
			else:
				if randi_range(0, 1) == 0:
					room_type = RoomTypes["side"]
				else:
					room_type = RoomTypes["t"]
					hasT = true
				
				sideCount += 1
		
				# Check if a T room exists (to prevent a map with inaccessible rooms)
				if not hasT and sideCount == 4:
					room_type = RoomTypes["t"]
					hasT = true
			
			# Choose random room to fill from RoomTypes
			map[x][y] = room_type[randi_range(0, room_type.size() - 1)]
			# print(Rooms.find_key(map[x][y]) + " x: " + str(x) + " y: " + str(y))
	
# Place randomized rooms and rotate based on gridmap cell location
func generate_map() -> void:
	var cell_position: Vector3 = Vector3i.ZERO
	var cell_rotation: Vector3 = Vector3i.ZERO
	var cell_scale: int = 16

	for x in map_size.x:
		for y in map_size.y:
			var room = map[x][y]
			cell_position = Vector3i(x * cell_scale, 0, y * cell_scale)
			
			if room in RoomTypes["center"]:
				cell_position.y = -0.5 # the center room model is higher for some reason

			if room in RoomTypes["corner"]:
				if x == 2 and y == 0:
					cell_rotation.y = 270
				elif x == 2 and y == 2:
					cell_rotation.y = 180
				elif x == 0 and y == 2:
					cell_rotation.y = 90
				else:
					cell_rotation.y = 0
			
			elif room in RoomTypes["side"]:
				if y == 1:
					cell_rotation.y = 90
				else:
					cell_rotation.y = 0
			
			elif room in RoomTypes["t"]:
				if x == 2 and y == 1:
					cell_rotation.y = 270
				elif x == 1 and y == 2:
					cell_rotation.y = 180
				elif x == 0 and y == 1:
					cell_rotation.y = 90
				else: # 1, 0
					cell_rotation.y = 0
			
			else:
				print("All cells rotated")

			var roomScene = room.instantiate()
			rooms.add_child(roomScene)
			roomScene.set_position(cell_position)
			roomScene.set_rotation_degrees(cell_rotation)

# Spawn player in a random room
func spawn_player() -> void:
	var spawn_room: Vector3i = Vector3i(12, 2, 16)
	var player = player_scene.instantiate()
	add_child(player)
	player.position = spawn_room

	player.set_physics_process(false)
	GAMEMANAGER.disablePlayer(true)

	
func start_game() -> void:
	var countdown = Timer.new()
	countdown.autostart = true
	countdown.wait_time = 3
	countdown.one_shot = true
	add_child(countdown)
	countdown.connect("timeout", _on_countdown_timeout)

func _on_countdown_timeout() -> void:
	get_node("Player").set_physics_process(true)
	GAMEMANAGER.disablePlayer(false)
	print("go!")

	var game = Timer.new()
	game.autostart = true
	game.wait_time = 60
	game.one_shot = true
	add_child(game)
	game.connect("timeout", _on_game_timeout)

func _on_game_timeout() -> void:
	get_node("Player").set_physics_process(false)
	GAMEMANAGER.disablePlayer(true)
	print("game over!")
	# get_tree().change_scene_to_file("res://Scenes/Screens/end.tscn")

func _ready() -> void:
	initialize_map()
	randomize_map()
	generate_map()
	spawn_player()
	start_game()
