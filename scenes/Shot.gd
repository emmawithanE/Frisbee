extends KinematicBody2D

export (int) var speed

var vel = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	# print("Bullet ready function.")
	vel = Vector2(speed,0).rotated(rotation)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var collision = move_and_collide(vel * delta)
	if collision:
		if (collision.get_collider().has_method("ball_collision")):
			collision.get_collider().ball_collision(self, collision)
