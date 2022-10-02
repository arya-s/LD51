extends Node

onready var audio = $AudioStreamPlayer

func _on_Timer_timeout():
	audio.play()
