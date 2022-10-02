extends Node

onready var bgm = $BGM

func _ready():
	VisualServer.set_default_clear_color(Color('0e151c'))

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
		
	if Input.is_action_just_pressed("reset"):
		stats.reset()
		global.reset_scene()

	


func _on_BGMTimer_timeout():
	bgm.play()
