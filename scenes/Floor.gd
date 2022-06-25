extends TileMap

const DEFAULT_COLOUR = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func ball_collision(ball, collision):
	ball.vel = ball.vel.bounce(collision.get_normal())
	ball.increase_speed()

	var cell = collision.get_collider().world_to_map(collision.get_position() - collision.get_normal())

	var me = 0
	var enemy = 0

	for i in range(-1, 2):
		for j in range(-1, 2):
			var c = cell + Vector2(i, j)
			var cell_type = get_cellv(c)
			if cell_type == INVALID_CELL || cell_type == ball.colour:
				continue
			match cell_type:
				0:
					me += 1
				_:
					me += 1
					enemy -= 1
			var index = get_cell_autotile_coord(c.x, c.y)
			set_cellv(c, ball.colour, false, false, false, index)

	Signals.emit_signal("paint_area_changed", ball.colour, me, enemy)

func bouncy(obj, collision):
	var cell = collision.get_collider().world_to_map(collision.get_position() - collision.get_normal())
	var cell_type = get_cellv(cell)
	if cell_type != INVALID_CELL && cell_type != DEFAULT_COLOUR:
		return true
	return false

