extends Node2D

const KILL_SCORE = 5000
var green = 0
var purple = 0
var green_area = 0
var purple_area = 0
var green_lives = 0
var purple_lives = 0
var running = true

const DISPLAY_SCALE = 0.01

const HEADS_ELEVATION = 32
const HEADS_SPACING = 32
var green_head = load("res://sprites/greenhead.png")
var purple_head = load("res://sprites/purplehead.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	Signals.connect("paint_area_changed", self, "on_paint")
	Signals.connect("kill_player", self, "on_kill")
	Signals.connect("win", self, "on_win")
	Signals.connect("lives_changed", self, "lives_changed")
	$GreenScore.set_text(str(green))
	$PurpleScore.set_text(str(purple))

func on_paint(ball, me, enemy):
	if ball == 1:
		green_area += me
		purple_area += enemy
	else:
		purple_area += me
		green_area += enemy
	print("paint area changed, green=" + str(green_area) + ", puple = " + str(purple_area))

func on_tick():
	if running:
		green += green_area
		purple += purple_area

	$GreenScore.set_text(str(int(green * DISPLAY_SCALE)))
	$PurpleScore.set_text(str(int(purple * DISPLAY_SCALE)))
	update()

func on_kill(player):
	if player.colour == 1:
		purple += KILL_SCORE
	else:
		green += KILL_SCORE

func on_win(player):
	running = false
	if player == 1:
		print("green won")
	else:
		print("purple won")

func lives_changed(green, purple):
	green_lives = green
	purple_lives = purple
	print("green lives " + str(green_lives) + " purple " + str(purple_lives))
	$GreenScore.set_text(str(int(green * DISPLAY_SCALE)))
	$PurpleScore.set_text(str(int(purple * DISPLAY_SCALE)))
	
func _draw():
	print("drawing")
	# Draw green heads above green score
	var green_pos = $GreenScore.get_position() - Vector2(0,HEADS_ELEVATION)
	print("green_pos: " + str(green_pos))
	for i in green_lives:
		draw_texture(green_head, green_pos + Vector2(i * HEADS_SPACING, 0))
		
	# Draw purple heads above purple score
	var purple_pos = $PurpleScore.get_position() - Vector2(0,HEADS_ELEVATION)
	for i in purple_lives:
		draw_texture(purple_head, purple_pos - Vector2(i * HEADS_SPACING, 0))
