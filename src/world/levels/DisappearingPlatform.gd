extends KinematicBody2D

onready var despawn_timer = $DespawnTimer
onready var respawn_timer = $RespawnTimer

onready var sprite = $Sprite
onready var collider = $Collider
onready var player_detector = $PlayerDetector

func despawn():
	collider.disabled = true
	player_detector.monitoring = false
	visible = false
	respawn_timer.start()
	
func respawn():
	collider.disabled = false
	player_detector.monitoring = true
	visible = true

func _on_PlayerDetector_body_entered(body):
	if body.is_in_group("player"):
		despawn_timer.start()

func _on_DespawnTimer_timeout():
	despawn()

func _on_RespawnTimer_timeout():
	respawn()
