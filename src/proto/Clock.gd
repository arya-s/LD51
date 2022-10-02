extends Node2D

onready var timer = $Timer
onready var hole_timer = $HoleTimer
onready var pivot = $Pivot
onready var hole_pivot = $Pivot/HolePivot

var r = 0

export(int) var f = 2
export(int) var a = 72 - 32
export(float) var offset = 0

var t = 0

func _ready():
	rotation = deg2rad(offset)

func _process(delta):
	if timer.time_left > 0:
		r += delta * 2 * PI / timer.wait_time
	
	t += delta
	var m = sin(t * f) * a
	hole_pivot.position.y -= m * delta
	
	pivot.rotation = r
