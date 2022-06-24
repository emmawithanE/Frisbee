extends KinematicBody2D

const MIN_SPEED = 200
const MAX_SPEED = 800

var vel = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	# print("Bullet ready function.")
	vel = Vector2(MIN_SPEED ,0).rotated(rotation)
	Signals.emit_signal("speed_changed", get_instance_id(), MIN_SPEED)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var collision = move_and_collide(vel * delta)
	if collision:
		if (collision.get_collider().has_method("ball_collision")):
			collision.get_collider().ball_collision(self, collision)

func increase_speed():
	var v = vel.length()
	var new_v = min(MAX_SPEED, v + (MAX_SPEED-v)/4)
	vel = vel.normalized() * new_v
	Signals.emit_signal("speed_changed", get_instance_id(), new_v)
	
func die():
	queue_free()
	Signals.emit_signal("speed_changed", get_instance_id(), 0)
