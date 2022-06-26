extends Node2D

const KILL_SCORE = 1000
var green = 0
var purple = 0
var green_area = 0
var purple_area = 0
var green_lives = 0
var purple_lives = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.connect("paint_area_changed", self, "on_paint")
	Signals.connect("kill_player", self, "on_kill")
	Signals.connect("win", self, "on_win")
	Signals.connect("lives_changed", self, "lives_changed")

func on_paint(ball, me, enemy):
	if ball == 1:
		green_area += me
		purple_area += enemy
	else:
		purple_area += me
		green_area += enemy
	print("paint area changed, green=" + str(green_area) + ", puple = " + str(purple_area))

func on_tick():
	green += green_area
	purple += purple_area

func on_kill(player):
	if player.colour == 1:
		purple += KILL_SCORE
	else:
		green += KILL_SCORE

func on_win(player):
	if player == 1:
		print("green won")
	else:
		print("purple won")

func lives_changed(green, purple):
	green_lives = green
	purple_lives = purple
	print("green lives " + str(green_lives) + " purple " + str(purple_lives))
