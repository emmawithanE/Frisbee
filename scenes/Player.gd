extends KinematicBody2D

var vel = Vector2()
const MAX_SPD = 100
const GRAV = 20
const JUMP = 600
const UP = Vector2(0,-1)

enum ShootingStates {
	Empty, Ready, Grabbing, GrabBackswing
}
var shooting_state = ShootingStates.Ready # start with a bullet
const GRAB_LENGTH = 0.5
const GRAB_BACKSWING_LENGTH = 0.5
# Get bullet resource from outside
export (PackedScene) var bullet


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
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
				shot_instance.position = $Pointing/End.global_position
				shot_instance.rotation = $Pointing.rotation
				get_parent().add_child(shot_instance)
				# print("Shot fired.")
				shooting_state = ShootingStates.Empty
			ShootingStates.Empty:
				$Timer.start(GRAB_LENGTH)
				shooting_state = ShootingStates.Grabbing
				print("setting ss to grabbing")
			ShootingStates.Grabbing:
				pass
			ShootingStates.GrabBackswing:
				pass
			_:
				assert(false, "unhandled shooting state " + str(shooting_state))

	vel.y += GRAV
	
#	if Input.is_action_pressed("ui_right"):
#		vel.x = MAX_SPD
#	elif Input.is_action_pressed("ui_left"):
#		vel.x = -MAX_SPD
#	else:
#		vel.x = 0
		
	vel.x = 0
	
	if Input.is_action_pressed("ui_right"):
		vel.x += MAX_SPD
	if Input.is_action_pressed("ui_left"):
		vel.x -= MAX_SPD
	
	if is_on_floor():
		if Input.is_action_just_pressed("ui_up"):
			vel.y = -JUMP
	
	vel = move_and_slide(vel,UP)

func timeout():
	print("timeout")
	match shooting_state:
		ShootingStates.Grabbing:
			shooting_state = ShootingStates.GrabBackswing
			$Timer.start(GRAB_BACKSWING_LENGTH)
			print("setting ss to backswing")
		ShootingStates.GrabBackswing:
			print("setting ss to empty")
			shooting_state = ShootingStates.Empty
		_:
			assert(false, "shooting state=" + str(shooting_state) + " when timer ended")

func ball_collision(ball, collision):
	print("ball collision")
	print("ss == " + str(shooting_state))
	if shooting_state == ShootingStates.Grabbing:
		ball.die()
		shooting_state = ShootingStates.Ready
		$Timer.stop()
