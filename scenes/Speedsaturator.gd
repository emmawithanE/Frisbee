extends TextureRect

func _ready():
	Signals.connect("speed_changed", self, "_speed_changed")

func _speed_changed(speed):
	print("speed changed to " + str(speed))
	material.set_shader_param("amount", (speed-Globals.min_speed) / (Globals.max_speed))
