class_name PickUpController
extends Area3D

# BUFFS #

enum Buff {RADIUS, AGILITY, RAINBOW}
var buffType: Buff = Buff.AGILITY

const FOOD_INCREASE: int = 10
const RADIUS_INCREASE: int = 5
const JUMP_INCREASE: float = 2.0
const SPEED_INCREASE: float = 2.0

const COOLDOWN: int = 10

# NODES # 

@onready var sprite := $Sprite3D
@onready var collision := $CollisionShape3D

func _ready() -> void:
	var randomBuff: int = randi_range(0, Buff.size() - 1)
	buffType = Buff.values()[randomBuff]
	print(Buff.keys()[randomBuff])
	match buffType:
		Buff.RADIUS:
			sprite.texture = load("res://textures/Food/miniJam_applejuice.png")
		Buff.AGILITY:
			sprite.texture = load("res://textures/Food/miniJam_cookie.png")
		Buff.RAINBOW:
			sprite.texture = load("res://textures/Food/miniJam_egg.png")

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		pickup()
		self.set_collision_mask_value(2, false)
		sprite.visible = false

func start_timer() -> void:
	var timer := Timer.new()
	timer.autostart = true
	timer.wait_time = COOLDOWN
	timer.one_shot = true
	timer.connect("timeout", _on_timer_timeout)
	add_child(timer)

func pickup() -> void:
	GAMEMANAGER.refillHunger()
	match buffType:
		Buff.RADIUS:
			GAMEMANAGER.changeRadius(RADIUS_INCREASE)
			GAMEMANAGER.score += 10
			print("radius increased!!")
		Buff.AGILITY:
			GAMEMANAGER.changePlayerJump(JUMP_INCREASE)
			GAMEMANAGER.changePlayerSpeed(SPEED_INCREASE)
			print("agility increased!!")
			GAMEMANAGER.score += 20
		Buff.RAINBOW:
			GAMEMANAGER.setRainbow(true)
			print("rainbow!!!")
			GAMEMANAGER.score += 50

	start_timer()

func _on_timer_timeout():
	match buffType:
		Buff.RADIUS:
			GAMEMANAGER.changeRadius(-RADIUS_INCREASE)
			print("radius normal")
		Buff.AGILITY:
			GAMEMANAGER.changePlayerJump(-JUMP_INCREASE)
			GAMEMANAGER.changePlayerSpeed(-SPEED_INCREASE)
			print("agility normal")
		Buff.RAINBOW:
			GAMEMANAGER.setRainbow(false)
			print("no more rainbow")
	
	self.set_collision_mask_value(2, true)
	sprite.visible = true
