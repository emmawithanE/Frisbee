extends Area2D

var flicker_count = 9
var FLICKER_LENGTH = 20

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn()

func _physics_process(delta):
	for b in get_overlapping_bodies():
		if b.has_method("world_ball_collision"):
			b.world_ball_collision(self)
	
func spawn():
	# invuln for a bit
	set_collision_mask_bit(2, false)
	set_collision_layer_bit(4, false)
	flicker_count = 0
	var timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", self, "flicker", [timer])
	timer.start(0.1)

func flicker(timer):
	flicker_count += 1
	visible = !visible
	if flicker_count == FLICKER_LENGTH:
		visible = true
		set_collision_mask_bit(2, true)
		set_collision_layer_bit(4, true)
		timer.queue_free()

func die():
	queue_free()
