extends KinematicBody2D

const MIN_SPEED = 200.0
const MAX_SPEED = 800.0

var vel = Vector2()
var colour = 1

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
			update_sprite()

func ball_collision(ball, coll):
	set_vel(vel.bounce(coll.normal) + ball.vel)

func set_vel(v):
	vel = v
	Signals.emit_signal("speed_changed", get_instance_id(), vel.length())
	update_sprite()
	
func increase_speed():
	var v = vel.length()
	var new_v = min(MAX_SPEED, v + sqrt(v))
	set_vel(vel.normalized() * new_v)
	
func add_vel(v):
	set_vel(vel + v)

func update_sprite():
	var new_col = Vector2(colour, int(vel.length() > MAX_SPEED * 0.9))
	print(str(new_col))
	$Sprite.set_frame_coords(new_col)
	look_at(global_position + vel)

func die():
	queue_free()
	Signals.emit_signal("speed_changed", get_instance_id(), 0)

func set_colour(col):
	$Sprite.set_frame(col)
	colour = col

func rigid(player, coll):
	return true
