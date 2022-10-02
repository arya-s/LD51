extends Node

var is_playing = false

func _process(delta):
	if Input.is_action_just_pressed("ui_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
		
	if Input.is_action_just_pressed("reset"):
		global.reset()

func instance_scene_on_main(scene, position):
	var main = get_tree().current_scene
	var instance = scene.instance()
	main.add_child(instance)
	instance.global_position = position
	return instance

func reset():
	stats.reset()
	get_tree().change_scene("res://src/world/levels/Level.tscn")
