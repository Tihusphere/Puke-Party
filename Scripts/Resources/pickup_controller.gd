class_name PickUpController
extends Area3D

enum Buff {RADIUS, FOOD, RAINBOW}

const ANIMATION_SPEED: int = 1

@export var buffType: Buff
@export var quantity: int

func _process(_delta: float) -> void:
	rotate_x(deg_to_rad(ANIMATION_SPEED))
	rotate_y(deg_to_rad(ANIMATION_SPEED))

func pickup() -> void:
	match buffType:
		Buff.RADIUS:
			GameManagerClass.increaseRadius(quantity)
			print("Radius!")
		Buff.FOOD:
			GameManagerClass.addFood(quantity)
			print("Food!")
		Buff.RAINBOW:
			GameManagerClass.rainbowTime(quantity)
			print("Rainbow!")

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		pickup()
		self.queue_free()
