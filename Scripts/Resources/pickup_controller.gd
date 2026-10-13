class_name PickUpController
extends Area3D

# BUFFS #

enum Buff {SPEED, JUMP, RAINBOW}
var buffType: Buff = Buff.SPEED

const SPEED_INCREASE: float = 5.0
const JUMP_INCREASE: float = 5.0

const COOLDOWN: int = 10

# NODES # 

@onready var sprite := $Sprite3D
@onready var collision := $CollisionShape3D
@onready var eat_sfx := $Eat

func _ready() -> void:
	var randomBuff: int = randi_range(0, Buff.size() - 1)
	buffType = Buff.values()[randomBuff]
	match buffType:
		Buff.SPEED:
			sprite.texture = load("res://textures/Food/miniJam_applejuice.png")
		Buff.JUMP:
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
	eat_sfx.play()
	GAMEMANAGER.refillHunger()
	match buffType:
		Buff.SPEED:
			GAMEMANAGER.setPlayerSpeed(SPEED_INCREASE)
			GAMEMANAGER.score += 10
			print("speed increased!!")
		Buff.JUMP:
			GAMEMANAGER.setPlayerJump(JUMP_INCREASE)
			print("jump increased!!")
			GAMEMANAGER.score += 20
		Buff.RAINBOW:
			GAMEMANAGER.setRainbow(true)
			print("rainbow!!!")
			GAMEMANAGER.score += 50

	start_timer()

func _on_timer_timeout():
	match buffType:
		Buff.SPEED:
			GAMEMANAGER.setPlayerSpeed(-SPEED_INCREASE)
			print("radius normal")
		Buff.JUMP:
			GAMEMANAGER.setPlayerJump(-JUMP_INCREASE)
			print("agility normal")
		Buff.RAINBOW:
			GAMEMANAGER.setRainbow(false)
			print("no more rainbow")
	
	self.set_collision_mask_value(2, true)
	sprite.visible = true
