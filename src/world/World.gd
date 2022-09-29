extends Node

onready var tilemap = $SolidTilemap

func _ready():
	print(tilemap.get_cell(0, 179/8))

func _process(_delta: float):
	if Input.is_action_just_pressed("ui_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
