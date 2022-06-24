extends TileMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func ball_collision(ball, collision):
	set_cellv(collision.get_collider().world_to_map(collision.get_position() - collision.get_normal()), -1)
	ball.vel = ball.vel.bounce(collision.get_normal()) * 1.1;
