extends Node3D

@onready var grid_map: GridMap = $GridMap

var map_size: Vector2i = Vector2i(3, 3)
var map: Array

var player_scene = preload("res://Scenes/player_controller.tscn")

# Basis orientations for rotating cells
# See 'https://stackoverflow.com/questions/67443086/'
var rotation_0: int = 0
var rotation_90: int = 16
var rotation_180: int = 10
var rotation_270: int = 22

# Stores room scene data
var Rooms: Dictionary = {
	"center": {"scene": preload("uid://dxrhmjmi2oxr7"), "icon": "╬"},
	"corner_hallway": {"scene": preload("uid://d3fg28omtx7iq"), "icon": "┌"},
	"corner_room": {"scene": preload("uid://db5qpe6fny7fg"), "icon": "╔"},
	"side_hallway": {"scene": preload("uid://kewdmsc5g714"), "icon": "│"},
	"side_room": {"scene": preload("uid://cwwfrbi1n3ndq"), "icon": "║"},
	"t_hallway": {"scene": preload("uid://cc5aopk1qipps"), "icon": "├"},
	"t_room": {"scene": preload("uid://7u2koin6i58b"), "icon": "╠"},
}

# Stores similar rooms by icon
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
		Rooms["side_room"]["icon"]
	],
	"t" = [
		Rooms["t_hallway"]["icon"],
		Rooms["t_room"]["icon"]
	]
}

# Converts map characters to integers corresponding to their mesh order in the MeshLibrary resource
# x: 	the x coordinate in the map array
# y: 	the y coordinate in the map array
# arr:	the array to sort through (for custom map layouts, not randomized map) 
func map_to_mesh(x: int, y: int, arr: Array) -> int:
	match arr[x][y]:
		"╬":
			return 0
		"┌":
			return 1
		"╔":
			return 2
		"│":
			return 3
		"║":
			return 4
		"├":
			return 5
		"╠":
			return 6
		_:
			return -1

# Converts integers to map characters corresponding to the room type they represent
# num: 	the index of the mesh in the MeshLibrary resource
func mesh_to_map(num: int):
	match num:
		0:
			return "╬"
		1:
			return "┌"
		2:
			return "╔"
		3:
			return "│"
		4:
			return "║"
		5:
			return "├"
		6:
			return "╠"
		_:
			return ""

# Creates an nested array using map_size
func initialize_map() -> void:
	for x in map_size.x:
		map.append([])
		for y in map_size.y:
			map[x].append(0)

# Picks a random room based on the index of the map array
func randomize_map() -> void:
	var sideCount: int = 0 # Notifies how many side rooms have been generated (up to 4)
	var hasT: bool = false # Determines whether a side room is a T variation
	
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

# Place randomized rooms and rotate based on gridmap cell location
func generate_map(arr = null) -> void:
	var cell_position: Vector3i
	var room: int
	var cell_rotation: int = rotation_0

	if arr == null: arr = map # Only used for custom maps (for debugging)

	for x in map_size.x:
		for y in map_size.y:
			cell_position = Vector3i(x * 8, 0, y * 8)
			room = map_to_mesh(x, y, arr)

			# Rotate corners
			if mesh_to_map(room) in RoomTypes["corner"]:
				if x == 2 and y == 0: # Top right
					cell_rotation = rotation_270
				elif x == 0 and y == 2: # Bottom left
					cell_rotation = rotation_90
				elif x == 2 and y == 2: # Bottom right
					cell_rotation = rotation_180
				else: # Top left
					cell_rotation = rotation_0
			
			# Rotate sides
			elif mesh_to_map(room) in RoomTypes["side"]:
				if x == 1 and y == 0: # Top
					cell_rotation = rotation_90
				elif x == 1 and y == 2: # Bottom
					cell_rotation = rotation_90
				else:
					cell_rotation = rotation_0
			
			# Rotate t's
			elif mesh_to_map(room) in RoomTypes["t"]:
				if x == 1 and y == 0: # Top
					cell_rotation = rotation_270
				elif x == 1 and y == 2: # Bottom
					cell_rotation = rotation_90
				elif x == 2 and y == 1: # Left
					cell_rotation = rotation_180
				else: # Right
					cell_rotation = rotation_0
			
			else:
				print("All cells rotated")
			
			grid_map.set_cell_item(cell_position, room, cell_rotation)

# Spawn player in a random room
func spawn_player() -> void:
	randomize()
	var spawn_room: Vector3i = Vector3i(randi_range(0, map_size.x - 1), 2, randi_range(0, map_size.y - 1))
	var player = player_scene.instantiate()
	add_child(player)
	player.position = spawn_room

# Formats map array into a readable string (for debugging) (see icons in Rooms)
func map_to_string() -> String:
	var map_as_string: String = ""
	for x in map_size.x:
		for y in map_size.y:
			map_as_string += "[" + str(map[y][x]) + "]"
		map_as_string += "\n"
	return map_as_string

func _ready() -> void:
	initialize_map()
	randomize_map()
	# map = [["┌", "╠", "┌", ], ["╠", "╬", "╠", ], ["┌", "╠", "╔", ]]
	generate_map(map)
	print(map_to_string())
	spawn_player()
