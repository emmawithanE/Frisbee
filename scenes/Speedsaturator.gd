extends TextureRect

# ball id => speed
var speeds = {}

func _ready():
	Signals.connect("speed_changed", self, "_speed_changed")
	Signals.connect("win", self, "game_ended")

func _speed_changed(id, s):
	if s == 0:
		speeds.erase(id)
	else:
		speeds[id] = s
	var total_speed = 0
	for i in speeds.values():
		total_speed += i
	print("speed changed to " + str(total_speed))
	material.set_shader_param("amount", (total_speed) / (500))

func game_ended(_p):
	visible = false
