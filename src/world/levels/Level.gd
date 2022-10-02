extends Node

onready var bird_spawner_left = $BirdSpawnerLeft
onready var bird_spawner_right = $BirdSpawnerRight

func _on_BirdSpawnTimer_timeout():
	if randi() % 2 == 0:
		bird_spawner_left.spawn()
	else:
		bird_spawner_right.spawn()
