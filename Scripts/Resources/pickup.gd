class_name PickupResource
extends Resource

enum Buff {RADIUS, FOOD, RAINBOW}

@export var name: String
@export var buffType: Buff
@export var quantity: int

func pickup() -> void:
	match buffType:
		Buff.RADIUS:
			GameManagerClass.increaseRadius(quantity)
		Buff.FOOD:
			GameManagerClass.addFood(quantity)
		Buff.RAINBOW:
			GameManagerClass.rainbowTime(quantity)
