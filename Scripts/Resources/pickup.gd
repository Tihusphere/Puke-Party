class_name pickup
extends Resource

enum Buff { RADIUS, FOOD, RAINBOW }

@export var name : String
@export var buffType : Buff
@export var quantity : int

func _ready():
	pass

func pickup() -> void:
	match buffType:
		Buff.RADIUS: 
				Gameplaymanager.increaseRadius(quantity)
		Buff.FOOD:
				Gameplaymanager.addFood(quantity)
		Buff.RAINBOW:
				Gameplaymanager.rainbowTime()
