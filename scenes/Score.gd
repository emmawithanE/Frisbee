extends Node2D

var green = 0
var purple = 0
var green_area = 0
var purple_area = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.connect("paint_area_changed", self, "on_paint")

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
