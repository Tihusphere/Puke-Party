extends Node3D

@onready var anim: AnimatedSprite3D = $AnimatedSprite3D

const START_Y: float = -0.25
const ANIM_Y: float = -0.75

var vomit_player := AudioStreamPlayer.new()
var vomit_sfx := load("res://Sounds/vomit.mp3")

func _ready() -> void:
	anim.set_animation("default")

	# Setup vomit sound
	vomit_player.stream = vomit_sfx
	vomit_player.volume_db = 20.0
	add_child(vomit_player)

func play_sfx() -> void:
	if not vomit_player.playing:
		vomit_player.play()

func _input(_event: InputEvent) -> void:
	if not GAMEMANAGER.isPlayerDisabled() and GAMEMANAGER.current_hunger > 0:
		# Animate
		if Input.is_action_just_pressed("shoot"):
			anim.play("starting")
			position.y = START_Y
			play_sfx()
		if Input.is_action_pressed("shoot") and not anim.is_playing():
			anim.play("vomiting")
			position.y = ANIM_Y
			play_sfx()
		if Input.is_action_just_released("shoot"):
			anim.play("stopping")
			position.y = ANIM_Y
			vomit_player.stop()
	if GAMEMANAGER.current_hunger == 0:
		if anim.get_animation() != "stopping":
			anim.play("stopping")
			position.y = ANIM_Y
			vomit_player.stop()