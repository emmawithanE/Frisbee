extends KinematicBody2D

export var colour = 1

var dead = false

var vel = Vector2()
const MAX_SPD = 150
const GRAV = 10
const JUMP = 300
const MAX_FALL_SPEED = 300
const JUMP_PEAK = 45
const UP = Vector2(0,-1)

enum ShootingStates {
	Empty, Ready, Grabbing, GrabBackswing
}
var shooting_state = ShootingStates.Ready # start with a bullet
const GRAB_LENGTH = 0.5
const GRAB_BACKSWING_LENGTH = 0.5
# Get bullet resource from outside
export (PackedScene) var bullet

enum DashState {
	Ready, ChargingDash, Dash, NoDash
}
var dash_state = DashState.Ready
var dash_charge = 0.0
const DASH_SCALE = 0.5 # Dash length (s) = charge time * scale
const MAX_DASH = 1 # Max dash length (s)
const DASH_BACKSWING_LENGTH = 0.5
const CHARGING_FALL_RATE = 0.5
const DASH_SPEED = 1000

var on_floor = false
var bounced = false
var has_jump = false

var respawn_pos = Vector2(0, 0)
var flicker_count = 0
var FLICKER_LENGTH = 15

var UI_LEFT = "ui_left"
var UI_RIGHT = "ui_right"
var UI_UP = "ui_up"
var UI_DOWN = "ui_down"
var UI_CLICK = "click"
var UI_JUMP = "jump"
var UI_DASH = "dash"

# Called when the node enters the scene tree for the first time.
func _ready():
	respawn_pos = global_position
	Signals.connect("disk_kill", self, "refresh_disk")
	if colour != 1:
		UI_LEFT += "_p2"
		UI_RIGHT += "_p2"
		UI_UP += "_p2"
		UI_DOWN += "_p2"
		UI_CLICK += "_p2"
		UI_JUMP += "_p2"
		UI_DASH += "_p2"

var last_aim = Vector2(1, 0)
func aim_vector():
	#var aim = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	var aim = Input.get_vector(UI_LEFT, UI_RIGHT, UI_UP, UI_DOWN)
	if aim:
		last_aim = aim
	return last_aim

func refresh_disk():
	print("giving p " + str(colour) + " a disk")
	shooting_state = ShootingStates.Ready

func set_shot_exception(shot):
	shot.add_collision_exception_with(self)
	yield(get_tree().create_timer(0.5), "timeout")
	if is_instance_valid(shot):
		shot.remove_collision_exception_with(self)

func die():
	dead = true
	Signals.emit_signal("kill_player", self)

func respawn():
	global_position = respawn_pos
	shooting_state = ShootingStates.Ready
	dead = false
	# invuln for a bit
	set_collision_mask_bit(1, false)
	set_collision_layer_bit(3, false)
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
		set_collision_mask_bit(1, true)
		set_collision_layer_bit(3, true)
		timer.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	# Fun with sprites
	var point = aim_vector().angle()
	if point > PI/2 || point < -PI/2:
		$Sprite.flip_h = true
		$Pointing.flip_h = true
		$Pointing.set_rotation(point - PI)
		$Pointing.set_position(Vector2(1,-2))
	else:
		$Sprite.flip_h = false
		$Pointing.flip_h = false
		$Pointing.set_rotation(point)
		$Pointing.set_position(Vector2(-1,-2))
		
	match shooting_state:
		ShootingStates.Ready:
			$Pointing.set_frame_coords(Vector2(1 + 3 * int(!on_floor), colour - 1))
		ShootingStates.Grabbing:
			$Pointing.set_frame_coords(Vector2(2, colour - 1))
		_:
			$Pointing.set_frame_coords(Vector2(0  + 3 * int(!on_floor), colour - 1))

	$Pointing.set_visible(true)
	match dash_state:
		DashState.ChargingDash:
			$Sprite.set_frame_coords(Vector2(2, colour - 1))
			$Pointing.set_visible(false)
		DashState.Dash:
			$Sprite.set_frame_coords(Vector2(3, colour - 1))
			$Sprite.rotation = vel.angle() - PI/2
			$Pointing.set_visible(false)
		_:
			if on_floor:
				$Sprite.set_frame_coords(Vector2(0, colour - 1))
			else:
				$Sprite.set_frame_coords(Vector2(1, colour - 1))

	# Throw or catch a ball
	if Input.is_action_just_pressed(UI_CLICK):
		match shooting_state:
			ShootingStates.Ready:
				# print("Click!")
				var shot_instance = bullet.instance()
				shot_instance.set_colour(colour)
				shot_instance.position = $Pointing/End.global_position
				set_shot_exception(shot_instance)
				shot_instance.rotation = aim_vector().angle()
				get_parent().add_child(shot_instance)
				# print("Shot fired.")
				shooting_state = ShootingStates.Empty
			ShootingStates.Empty:
				$GrabTimer.start(GRAB_LENGTH)
				shooting_state = ShootingStates.Grabbing
				print("setting ss to grabbing")
			ShootingStates.Grabbing:
				pass
			ShootingStates.GrabBackswing:
				pass
			_:
				assert(false, "unhandled shooting state " + str(shooting_state))

	# friction
	if on_floor:
		vel.x /= 2 # hard clamp
		if abs(vel.x) < 1:
			vel.x = 0 # floating point
	else:
		# gentle clamp
		vel.x -= vel.x*vel.x*sign(vel.x)*0.01*delta
		vel.x -= sign(vel.x)*min(abs(vel.x), 15)
	if bounced:
		vel.y -= vel.y*vel.y*sign(vel.y)*0.01*delta
	# jumping
	if has_jump:
		if Input.is_action_just_pressed(UI_JUMP):
			vel.y = -JUMP
			has_jump = false
	
	# movement
	var left = Input.is_action_pressed(UI_LEFT)
	var right = Input.is_action_pressed(UI_RIGHT)
	if left != right:
		if dash_state != DashState.ChargingDash:
			var dx = -MAX_SPD*int(left) + MAX_SPD*int(right)
			if abs(vel.x) > MAX_SPD :
				vel.x += dx*delta
			else:
				vel.x = dx

	var gravity = GRAV
	
	match dash_state:
		DashState.Ready:
			if Input.is_action_just_pressed(UI_DASH):
				dash_state = DashState.ChargingDash
				dash_charge = 0
				vel = Vector2(0, 0)
		DashState.ChargingDash:
			vel.y = CHARGING_FALL_RATE
			dash_charge += delta
			if Input.is_action_just_released(UI_DASH):
				dash_state = DashState.Dash
				$DashTimer.start(min(MAX_DASH, dash_charge * DASH_SCALE))
				vel = aim_vector() * DASH_SPEED
		DashState.Dash:
			gravity = 0
			
	# Gravity time
	vel.y += gravity
	var remaining_force = vel*delta
	on_floor = false
	for _i in range(4):
		if !remaining_force.length():
			break
		var coll = move_and_collide(remaining_force)
		if !coll:
			break
		else:
			if coll.normal.y < 0:
				on_floor = true
				bounced = false
				has_jump = true
				if dash_state == DashState.NoDash:
					dash_state = DashState.Ready

			remaining_force = coll.remainder
			remaining_force += (remaining_force*coll.normal).length()*coll.normal
			if (coll.collider.has_method("bouncy")) && coll.collider.bouncy(self, coll):
				print("bounce")
				bounced = true
				vel = vel.bounce(coll.normal) + coll.normal*Vector2(800, 800)
				remaining_force += coll.normal*Vector2(800, 800)*delta
			elif coll.collider.has_method("rigid") && coll.collider.rigid(self, coll):
				pass
			else:
				#if dv.length() > vel.length() / 2:
				if dash_state == DashState.Dash:
					vel = vel.bounce(coll.normal) * 0.2
					end_dash()
				else:
					var normal = coll.normal
					# don't bounce off slopes
					if coll.normal.x && coll.normal.y:
						normal.x = 0
					var dv = (vel*normal).length()*normal
					vel += dv


func grab_timeout():
	print("timeout")
	match shooting_state:
		ShootingStates.Grabbing:
			shooting_state = ShootingStates.GrabBackswing
			$GrabTimer.start(GRAB_BACKSWING_LENGTH)
			print("setting ss to backswing")
		ShootingStates.GrabBackswing:
			print("setting ss to empty")
			shooting_state = ShootingStates.Empty
		_:
			assert(false, "shooting state=" + str(shooting_state) + " when timer ended")

func end_dash():
	$DashTimer.stop()
	dash_state = DashState.NoDash
	$Sprite.set_frame_coords(Vector2(1, colour - 1))
	$Sprite.rotation = 0
	print("setting dash to backswing")

func dash_timeout():
	match dash_state:
		DashState.Dash:
			vel = vel.normalized() * max(vel.length() - DASH_SPEED+200, MAX_SPD)
			end_dash()
		_:
			assert(false, "dash state=" + str(dash_state) + " when timer ended")

func ball_collision(ball, _collision):
	print("ball collision")
	print("ss == " + str(shooting_state))
	print("ds == " + str(dash_state))
	if shooting_state == ShootingStates.Grabbing:
		ball.die()
		shooting_state = ShootingStates.Ready
		$GrabTimer.stop()
	elif dash_state == DashState.Dash:
		ball.add_vel(vel * 0.6)
		ball.colour = colour
		ball.update_sprite()
	else:
		die()
		ball.die()
		Signals.emit_signal("disk_kill")

func world_ball_collision(ball):
	print("world ball collision")
	if shooting_state == ShootingStates.Empty:
		ball.die()
		shooting_state = ShootingStates.Ready


func left_screen():
	if !dead:
		die()
