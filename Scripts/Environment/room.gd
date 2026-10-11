extends Node3D

@onready var player: Node3D = $PlayerController

func spawn(player_position: Vector3, player_rotation: Vector3) -> void:
	player.position = player_position
	player.rotation = player_rotation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn(Vector3(0, 1, 0), Vector3.ZERO)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
