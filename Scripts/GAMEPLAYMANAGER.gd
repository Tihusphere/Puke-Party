extends Node

var score : int = 0
var percentage : int = 0

var brushSize : int  = 10
var storedFood : int = 100

var vomitImage : Image
var vomitTexture : ImageTexture

func _ready():
	pass
	#vomitImage = load("res://icon.svg")
	#vomitTexture = ImageTexture.create_from_image(vomitImage)

func _process(delta: float) -> void:
	pass

func increaseRadius(delta):
	brushSize += delta

func addFood(delta):
	storedFood += delta

func rainbowTime():
	pass
