class_name GameManagerClass
extends Node

## BRUSH ##

var brush_texture: Texture2D:
	set(value):
		brush_texture = value
		update_brush_size()

var brush_size: Vector2i = Vector2i(64, 64):
	set(value):
		brush_size = value
		update_brush_size()

var overlay_texture: Texture2D # Texture to blend onto paintable objects via shader mask
var active_brush_image: Image
var brush_w: int = 0
var brush_h: int = 0
var brush_img = "res://textures/splat.png"
var vomit_img = "res://textures/splat.png"

## PLAYER ## 

# Physics

var speed: float = 5.0 # default speed
var jump: float = 6.0 # default jump

# Pickups

var player_input: bool = true
var rainbow: bool = false

const MAX_HUNGER: int = 1000
var current_hunger: int = MAX_HUNGER

## GAME ##

var score: int = 0
var countdown_timer: Timer = Timer.new()
var game_timer: Timer = Timer.new()
var playing: bool = false

func _ready() -> void:
	brush_texture = load(brush_img)
	overlay_texture = load(vomit_img)
	update_brush_size()
	toggleRainbows(true)

	add_child(countdown_timer)
	add_child(game_timer)

func update_brush_size() -> void:
	if brush_texture:
		active_brush_image = brush_texture.get_image()
		active_brush_image.convert(Image.FORMAT_RGBA8)
		active_brush_image.resize(brush_size.x, brush_size.y, Image.INTERPOLATE_BILINEAR)
		
		brush_w = active_brush_image.get_width()
		brush_h = active_brush_image.get_height()
	else:
		active_brush_image = null
		brush_w = 0
		brush_h = 0

func toggleRainbows(type):
	for child in get_children():
		if child is PaintableObject:
			child.toggle_rainbow(type)

func setStaticHues(hue):
	for child in get_children():
		if child is PaintableObject:
			child.set_static_hue(hue)

func resetOverlayColors():
	for child in get_children():
		if child is PaintableObject:
			child.reset_overlay_color()

func refillHunger():
	current_hunger = MAX_HUNGER

func changeRadius(size: int = 5):
	pass

func setPlayerSpeed(new_speed: float) -> void:
	speed = new_speed

func getPlayerSpeed() -> float:
	return speed

func setPlayerJump(new_jump: float) -> void:
	jump = new_jump

func getPlayerJump() -> float:
	return jump

func setRainbow(is_rainbow: bool = !rainbow) -> void: # toggles by default
	rainbow = is_rainbow

func getRainbow() -> bool:
	return rainbow

func disablePlayer(disabled: bool) -> void:
	player_input = disabled
	print("Player disabled is ", disabled)

func isPlayerDisabled() -> bool:
	return player_input

func start_game() -> void:
	print("countdown...")
	disablePlayer(true)
	playing = true

	countdown_timer.wait_time = 3
	countdown_timer.one_shot = true
	countdown_timer.start()
	countdown_timer.connect("timeout", _on_countdown_timer_timeout)

func _on_countdown_timer_timeout() -> void:
	countdown_timer.queue_free()
	print("game start!")
	disablePlayer(false)

	game_timer.wait_time = 60
	game_timer.one_shot = true
	game_timer.start()
	game_timer.connect("timeout", _on_game_timer_timeout)

func _on_game_timer_timeout() -> void:
	game_timer.queue_free()
	playing = false

	get_tree().change_scene_to_file("res://Scenes/Screens/end.tscn")
