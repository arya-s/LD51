extends Control

onready var play_button = $PlayButton
onready var quit_button = $QuitButton

var music_bus = AudioServer.get_bus_index("Music")
var sfx_bus = AudioServer.get_bus_index("SFX")

func _ready():
	if OS.get_name() == "HTML":
		quit_button.visible = false
		
	change_audio_volume(music_bus, -10)
	change_audio_volume(sfx_bus, -10)
		
func _process(delta):
	if Input.is_action_just_pressed("ui_select"):
		global.is_playing = true
		get_tree().change_scene("res://src/world/levels/Level.tscn")
	
	play_button.text = "CONTINUE" if global.is_playing else "PLAY"
	
func _on_PlayButton_pressed():
	global.is_playing = true
	get_tree().change_scene("res://src/world/levels/Level.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()

func change_audio_volume(bus, volume):
	AudioServer.set_bus_volume_db(bus, volume)
	
	if volume == -30:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
	
func _on_MusicSlider_value_changed(volume):
	change_audio_volume(music_bus, volume)

func _on_SFXSlider_value_changed(volume):
	change_audio_volume(sfx_bus, volume)

func _on_FullscreenToggle_pressed():
	OS.window_fullscreen = !OS.window_fullscreen
