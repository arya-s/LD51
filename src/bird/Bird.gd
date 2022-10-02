extends Node2D

var velocity = Vector2.ZERO

onready var animation_player = $AnimationPlayer
onready var sprite = $Sprite

func _process(delta):
	sprite.flip_h = true if sign(velocity.x) == 1 else false
	
	animation_player.play("fly")
	position += velocity * delta

func _on_VisibilityNotifier2D_viewport_exited(_viewport):
	queue_free()
