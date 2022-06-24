extends TileMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func ball_collision(ball, collision):
	ball.vel = ball.vel.bounce(collision.get_normal())
	ball.increase_speed()

	var cell = collision.get_collider().world_to_map(collision.get_position() - collision.get_normal())

	for i in range(-1, 2):
		for j in range(-1, 2):
			var c = cell + Vector2(i, j)
			if get_cellv(c) != INVALID_CELL:
				var index = get_cell_autotile_coord(c.x, c.y)
				set_cellv(c, ball.colour, false, false, false, index)
