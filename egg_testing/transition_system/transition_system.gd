# Implied class_name TransitionSystem
extends Node

@export var default_duration: float 
@export var default_image: Texture2D
@export var default_color: Color

var texture_rect: TextureRect = TextureRect.new()
var canvas_layer: CanvasLayer = CanvasLayer.new()
var transparent: Color = Color.TRANSPARENT

#var color_rect: ColorRect = ColorRect.new()
#var default_color: Color = Color(0.034, 0.078, 0.183, 1.0)

#@warning_ignore_start("unused_parameter")
func fade_to_image(color := default_color, duration := default_duration, image := default_image):
	
	pass

func _setup() -> void:
	if not canvas_layer.is_inside_tree():
		get_tree().root.add_child(canvas_layer)
	
	if not texture_rect.is_inside_tree():
		get_tree().add_child(texture_rect)
	
	canvas_layer.layer = 100
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# Why am I doing this. 
