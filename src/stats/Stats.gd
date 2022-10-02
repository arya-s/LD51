extends Node

var jumps = 0
var birds = 0
var score = 0
var highscore = 0
var prev_score = 0

func jumped():
	jumps += 1
	score += 10
	highscore = max(score, highscore)
	
func bird():
	birds += 1
	score *= 2
	highscore = max(score, highscore)

func reset():
	prev_score = score
	jumps = 0
	birds = 0
	score = 0
