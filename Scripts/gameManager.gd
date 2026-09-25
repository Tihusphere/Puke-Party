class_name PaintManager
extends Node

@export var brush_texture: Texture2D:
	set(value):
		brush_texture = value
		update_brush_size()

## Texture to blend onto paintable objects via shader mask
@export var overlay_texture: Texture2D

@export var brush_size: Vector2i = Vector2i(64, 64):
	set(value):
		brush_size = value
		update_brush_size()

var active_brush_image: Image
var brush_w: int = 0
var brush_h: int = 0

func _ready() -> void:
	update_brush_size()

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
