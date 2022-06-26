extends Node2D

var UI_RESTART = "ui_restart"
var UI_QUIT = "ui_quit"
var UI_RESTART_P2 = UI_RESTART + "_p2"
var UI_QUIT_P2 = UI_QUIT + "_p2"

func _process(delta):
	if Input.is_action_just_pressed(UI_RESTART) || Input.is_action_just_pressed(UI_RESTART_P2):
		get_tree().change_scene("res://scenes/World.tscn")
	elif Input.is_action_just_pressed(UI_QUIT) || Input.is_action_just_pressed(UI_QUIT_P2):
		get_tree().quit()
