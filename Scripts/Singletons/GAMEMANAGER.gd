class_name GameManagerClass
extends Node

var brush_texture: Texture2D:
	set(value):
		brush_texture = value
		update_brush_size()

## Texture to blend onto paintable objects via shader mask
var overlay_texture: Texture2D

var brush_size: Vector2i = Vector2i(64, 64):
	set(value):
		brush_size = value
		update_brush_size()

var active_brush_image: Image
var brush_w: int = 0
var brush_h: int = 0

var brush_img = "res://textures/splat.png"
var vomit_img = "res://textures/splat.png"

var speed: float = 5.0 # default speed
var jump: float = 6.0 # default jump


func _ready() -> void:
	brush_texture = load(brush_img)
	overlay_texture = load(vomit_img)
	update_brush_size()
	toggleRainbows(true)

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

func changeFood(amount: int = 10):
	pass

func changeRadius(size: int = 5):
	pass

func changePlayerSpeed(new_speed: float) -> void:
	speed += new_speed

func changePlayerJump(new_jump: float) -> void:
	jump += new_jump

func getPlayerSpeed() -> float:
	return speed

func getPlayerJump() -> float:
	return jump