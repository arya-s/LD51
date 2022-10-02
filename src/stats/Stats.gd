extends Node

var jumps = 0
var birds = 0
var score = 0

func jumped():
	jumps += 1
	score += 10
	
func bird():
	birds += 1
	score *= 2	

func reset():
	jumps = 0
	birds = 0
	score = 0
