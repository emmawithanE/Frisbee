extends KinematicBody2D

var colour = 2

var vel = Vector2()
const MAX_SPD = 100
const GRAV = 10
const JUMP = 300
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
const DASH_SPEED = 400

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	$Pointing.look_at(get_global_mouse_position())
	
	var pointdir = fposmod($Pointing.rotation_degrees, 360)
	
	if pointdir > 90 && pointdir <= 270:
		$Sprite.flip_h = true
	else:
		$Sprite.flip_h = false
	
	if Input.is_action_just_pressed("click"):
		match shooting_state:
			ShootingStates.Ready:
				# print("Click!")
				var shot_instance = bullet.instance()
				shot_instance.colour = colour
				shot_instance.position = $Pointing/End.global_position
				shot_instance.rotation = $Pointing.rotation
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
	
	# Side to side movement	
	vel.x = 0
	if Input.is_action_pressed("ui_right"):
		vel.x += MAX_SPD
	if Input.is_action_pressed("ui_left"):
		vel.x -= MAX_SPD
	
	# Here there be jumping
	if is_on_floor():
		if Input.is_action_just_pressed("ui_up"):
			vel.y = -JUMP
	
	# Handle dashing
	if (Input.is_action_just_pressed("dash") && dash_state == DashState.Ready):
		dash_state = DashState.ChargingDash
	
	if (dash_state == DashState.ChargingDash):
		dash_charge += delta
	
	if (Input.is_action_just_released("dash") && dash_state == DashState.ChargingDash):
		dash_state = DashState.Dash
		$DashTimer.start(min(MAX_DASH, dash_charge * DASH_SCALE))
		vel = get_local_mouse_position().normalized() * DASH_SPEED
	# Gravity time
	var gravity = 0
	if (vel.y <= JUMP_PEAK && vel.y >= -JUMP_PEAK):
		gravity += GRAV/2
	else:
		gravity += GRAV
		
	match dash_state:
		DashState.ChargingDash:
			gravity = min(gravity, CHARGING_FALL_RATE)
		DashState.Dash:
			gravity = 0
	
	vel.y += gravity

	vel = move_and_slide(vel,UP)

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

func dash_timeout():
	match dash_state:
		DashState.Dash:
			dash_state = DashState.NoDash
			$DashTimer.start(DASH_BACKSWING_LENGTH)
			print("setting dash to backswing")
		DashState.NoDash:
			print("setting dash to ready")
			dash_state = DashState.Ready
		_:
			assert(false, "dash state=" + str(dash_state) + " when timer ended")

func ball_collision(ball, collision):
	print("ball collision")
	print("ss == " + str(shooting_state))
	if shooting_state == ShootingStates.Grabbing:
		ball.die()
		shooting_state = ShootingStates.Ready
		$GrabTimer.stop()
