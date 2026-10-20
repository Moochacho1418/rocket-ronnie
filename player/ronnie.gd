extends CharacterBody2D

# Ronnie's own movement is deliberately weak: a run and a tiny hop. Real height and distance come
# from rocket blasts, which add straight to velocity in apply_blast(). She is a CharacterBody2D,
# not a RigidBody2D, so every jump is exact and repeatable.

const ROCKET_SCENE = preload("res://objects/rocket.tscn")
const AIM_LINE_LENGTH = 22.0
const AIM_COLOR = Color(1, 1, 1, 0.5)
# Crosshair sits on the mouse, or this far out along the stick when aiming with a controller
const CROSSHAIR_DISTANCE = 48.0
const CROSSHAIR_RADIUS = 5.0
const CROSSHAIR_GAP = 2.0
const CROSSHAIR_TICK = 4.0
const CROSSHAIR_COLOR = Color(1, 1, 1, 0.9)
# How far below the bottom of the terrain counts as falling out of the level
const KILL_MARGIN = 200.0

var tuning
var rockets = 0
var health = 0
var coyote_timer = 0.0
var hop_buffer_timer = 0.0
var fire_buffer_timer = 0.0
var fire_cooldown_timer = 0.0
var fire_held = false
var kill_y = INF
# Aim follows whichever was touched last: moving the mouse switches to mouse aim, pushing the
# right stick switches to stick aim. Letting go of the stick keeps the last direction.
var aim_dir = Vector2.DOWN
var using_stick_aim = false


func _ready():
	tuning = Game.tuning
	rockets = tuning.rocket_count
	health = tuning.max_health
	# The crosshair replaces the system cursor
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_fit_camera_to_terrain()


func _input(event):
	if event is InputEventMouseMotion:
		using_stick_aim = false


func _unhandled_input(event):
	if not event.is_action("fire"):
		return
	# A trigger sends a stream of events while held, so only the moment it crosses the
	# deadzone counts as a shot
	var pressed = event.is_action_pressed("fire")
	if pressed and not fire_held:
		fire_buffer_timer = tuning.fire_buffer_time
	fire_held = pressed


func _physics_process(delta):
	_update_aim()
	var on_floor = is_on_floor()
	if not on_floor:
		velocity.y = min(velocity.y + tuning.gravity * delta, tuning.max_fall_speed)
	_run(delta, on_floor)
	_hop(delta, on_floor)
	_fire_when_ready(delta)
	move_and_slide()

	if is_on_floor():
		rockets = tuning.rocket_count
	if global_position.y > kill_y:
		Game.restart()
	queue_redraw()


func _run(delta, on_floor):
	var dir = Input.get_axis("move_left", "move_right")
	var target = dir * tuning.run_speed
	if on_floor:
		var rate = tuning.ground_accel if dir != 0 else tuning.ground_decel
		velocity.x = move_toward(velocity.x, target, rate * delta)
		return

	# In the air, steering never slows down blast momentum in the direction you're already going.
	# Anything above run speed only bleeds off through air drag.
	var going_fast_same_way = abs(velocity.x) > tuning.run_speed and sign(dir) == sign(velocity.x)
	if dir != 0 and not going_fast_same_way:
		velocity.x = move_toward(velocity.x, target, tuning.air_accel * delta)
	if abs(velocity.x) > tuning.run_speed:
		velocity.x = move_toward(velocity.x, sign(velocity.x) * tuning.run_speed, tuning.air_drag * delta)


func _hop(delta, on_floor):
	coyote_timer = tuning.coyote_time if on_floor else max(coyote_timer - delta, 0.0)
	if Input.is_action_just_pressed("hop"):
		hop_buffer_timer = tuning.hop_buffer_time
	if hop_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = -tuning.hop_velocity
		hop_buffer_timer = 0.0
		coyote_timer = 0.0
	hop_buffer_timer = max(hop_buffer_timer - delta, 0.0)


func _fire_when_ready(delta):
	fire_cooldown_timer = max(fire_cooldown_timer - delta, 0.0)
	if fire_buffer_timer > 0 and fire_cooldown_timer == 0 and rockets > 0:
		_fire()
		fire_buffer_timer = 0.0
	fire_buffer_timer = max(fire_buffer_timer - delta, 0.0)


func _fire():
	rockets -= 1
	fire_cooldown_timer = tuning.rocket_cooldown
	if not is_on_floor():
		apply_blast(-aim_dir * tuning.air_recoil)
	var rocket = ROCKET_SCENE.instantiate()
	rocket.direction = aim_dir
	rocket.shooter = self
	get_parent().add_child(rocket)
	# Starts at her centre, not a muzzle, so a shot straight down can't spawn inside the floor
	rocket.global_position = global_position


func _update_aim():
	var stick = Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick != Vector2.ZERO:
		using_stick_aim = true
		aim_dir = stick.normalized()
	elif not using_stick_aim:
		var mouse = get_local_mouse_position().normalized()
		if mouse != Vector2.ZERO:
			aim_dir = mouse


# Called by explosions. push is already scaled by strength and falloff.
func apply_blast(push):
	var dir = push.normalized()
	var against = velocity.dot(dir)
	if tuning.cancel_opposing_velocity and against < 0:
		velocity -= dir * against
	velocity = (velocity + push).limit_length(tuning.max_speed)


func _draw():
	draw_line(Vector2.ZERO, aim_dir * AIM_LINE_LENGTH, AIM_COLOR, 1.0)
	var at = aim_dir * CROSSHAIR_DISTANCE if using_stick_aim else get_local_mouse_position()
	draw_arc(at, CROSSHAIR_RADIUS, 0, TAU, 24, CROSSHAIR_COLOR, 1.0)
	for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var start = dir * (CROSSHAIR_RADIUS + CROSSHAIR_GAP)
		draw_line(at + start, at + start + dir * CROSSHAIR_TICK, CROSSHAIR_COLOR, 1.0)


# Camera limits and the fall-out-of-level line come from whatever terrain the level has,
# so any new room works without setup
func _fit_camera_to_terrain():
	var bounds = null
	for layer in get_tree().get_nodes_in_group("terrain"):
		var used = layer.get_used_rect()
		var tile = Vector2(layer.tile_set.tile_size)
		var rect = Rect2(layer.to_global(Vector2(used.position) * tile), Vector2(used.size) * tile)
		bounds = rect if bounds == null else bounds.merge(rect)
	if bounds == null:
		return
	var camera = $Camera2D
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	kill_y = bounds.end.y + KILL_MARGIN
