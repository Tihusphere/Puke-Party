extends Node3D

@onready var anim: AnimatedSprite3D = $AnimatedSprite3D

const START_Y: float = -0.25
const ANIM_Y: float = -0.75

var full: bool = true # temporary variable for ammo

func _ready() -> void:
	anim.set_animation("default")

func _input(_event: InputEvent) -> void:
	if not GAMEMANAGER.isPlayerDisabled() and full:
		if Input.is_action_just_pressed("shoot"):
			anim.play("starting")
			position.y = START_Y
		if Input.is_action_pressed("shoot") and not anim.is_playing():
			anim.play("vomiting")
			position.y = ANIM_Y
		if Input.is_action_just_released("shoot"):
			anim.play("stopping")
			position.y = ANIM_Y
