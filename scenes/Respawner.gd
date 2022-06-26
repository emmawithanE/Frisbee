extends Node2D

const RESPAWN_TIME = 5.0
const LIVES = 3
var green_deaths = 0
var purple_deaths = 0
export (Vector2) var ball_respawn_pos
export (PackedScene) var world_ball

func _ready():
	Signals.connect("kill_player", self, "kill_player")
	Signals.connect("ball_lost", self, "ball_oob")
	Signals.emit_signal("lives_changed", LIVES-green_deaths, LIVES-purple_deaths)

func kill_player(player):
	if player.colour == 1:
		green_deaths += 1
		if green_deaths == LIVES:
			print("green ool")
			Signals.emit_signal("win", 2)
			return
	else:
		purple_deaths += 1
		if purple_deaths == LIVES:
			print("purple ool")
			Signals.emit_signal("win", 1)
			return
	Signals.emit_signal("lives_changed", LIVES-green_deaths, LIVES-purple_deaths)

	var parent = player.get_parent()
	parent.remove_child(player)
	yield(get_tree().create_timer(RESPAWN_TIME), "timeout")
	parent.add_child(player)
	player.respawn()

func ball_oob(ball):
	print("ball die")
	ball.die()
	var new_ball = world_ball.instance()
	new_ball.position = ball_respawn_pos
	get_parent().add_child(new_ball)
