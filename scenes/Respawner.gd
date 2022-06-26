extends Node2D

const RESPAWN_TIME = 5.0

func _ready():
	Signals.connect("kill_player", self, "kill_player")

func kill_player(player):
	var parent = player.get_parent()
	parent.remove_child(player)
	yield(get_tree().create_timer(RESPAWN_TIME), "timeout")
	parent.add_child(player)
	player.respawn()

func ball_oob(ball):
	pass
