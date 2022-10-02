extends Node2D

var Bird = preload("res://src/bird/Bird.tscn")

export(Vector2) var bird_velocity = Vector2.RIGHT
export(int) var bird_speed = 100

onready var spawn_position = $SpawnPosition

func spawn():
	var bird = global.instance_scene_on_main(Bird, spawn_position.global_position)
	bird.velocity = bird_velocity * bird_speed
	bird.rotation = rotation
