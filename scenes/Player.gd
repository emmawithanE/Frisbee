extends KinematicBody2D

export var colour = 1

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

var UI_LEFT = "ui_left"
var UI_RIGHT = "ui_right"
var UI_UP = "ui_up"
var UI_DOWN = "ui_down"
var UI_CLICK = "click"
var UI_JUMP = "jump"
var UI_DASH = "dash"

# Called when the node enters the scene tree for the first time.
func _ready():
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

func set_shot_exception(shot):
	shot.add_collision_exception_with(self)
	yield(get_tree().create_timer(0.5), "timeout")
	if is_instance_valid(shot):
		shot.remove_collision_exception_with(self)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Fun with sprites
	$Pointing.set_rotation(aim_vector().angle())
	
	var pointdir = fposmod($Pointing.rotation_degrees, 360)
	
	if pointdir > 90 && pointdir <= 270:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false

	match dash_state:
		DashState.ChargingDash:
			$Sprite.set_frame_coords(Vector2(2, colour - 1))
		DashState.Dash:
			$Sprite.set_frame_coords(Vector2(3, colour - 1))
			$Sprite.rotation = vel.angle() - PI/2
		_:
			if on_floor:
				$Sprite.set_frame_coords(Vector2(0, colour - 1))
			else:
				$Sprite.set_frame_coords(Vector2(1, colour - 1))

	if Input.is_action_just_pressed(UI_CLICK):
		match shooting_state:
			ShootingStates.Ready:
				# print("Click!")
				var shot_instance = bullet.instance()
				shot_instance.set_colour(colour)
				shot_instance.position = $Pointing/End.global_position
				shot_instance.rotation = $Pointing.rotation
				set_shot_exception(shot_instance)
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
	if on_floor:
		if Input.is_action_just_pressed(UI_JUMP):
			vel.y = -JUMP
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
					var dv = (vel*coll.normal).length()*coll.normal
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

func ball_collision(ball, collision):
	print("ball collision")
	print("ss == " + str(shooting_state))
	print("ds == " + str(dash_state))
	if shooting_state == ShootingStates.Grabbing:
		ball.die()
		shooting_state = ShootingStates.Ready
		$GrabTimer.stop()
		return
	if dash_state == DashState.Dash:
		ball.add_vel(vel * 0.6)
		ball.colour = colour
		ball.update_sprite()
