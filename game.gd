extends Node

# Autoload. Holds the one shared tuning resource and handles restart and slow motion, which work
# the same in every room.

const SLOW_MOTION_SCALE = 0.3

var tuning = preload("res://tuning/tuning.tres")


func _unhandled_input(event):
	if event.is_action_pressed("restart"):
		restart()
	elif event.is_action_pressed("slow_motion"):
		set_slow_motion(not is_slow_motion())


func restart():
	get_tree().reload_current_scene.call_deferred()


func is_slow_motion():
	return Engine.time_scale < 1.0


func set_slow_motion(on):
	Engine.time_scale = SLOW_MOTION_SCALE if on else 1.0
