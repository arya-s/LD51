extends Node

onready var bird_spawner_left = $BirdSpawnerLeft
onready var bird_spawner_right = $BirdSpawnerRight

onready var player = $Player
onready var moon = $Moon

var moon_pos = Vector2(272, 32)

func _physics_process(delta):
	if player.global_position.x > 160:
		moon.global_position.x = move_toward(moon.global_position.x, 270, delta)
	else:
		moon.global_position.x = move_toward(moon.global_position.x, moon_pos.x, delta)
		
	if player.global_position.y > 90:
		moon.global_position.y = move_toward(moon.global_position.y, 34, delta)
	else:
		moon.global_position.y = move_toward(moon.global_position.y, moon_pos.y, delta)
		
	if player.global_position.y > 200:
		stats.reset()
		get_tree().change_scene("res://src/ui/DeathScreen.tscn")

func _on_BirdSpawnTimer_timeout():
	if randi() % 2 == 0:
		bird_spawner_left.spawn()
	else:
		bird_spawner_right.spawn()
