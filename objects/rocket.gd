extends Node2D

# Moves itself and raycasts from its last position to its next one every frame, so even a very
# fast rocket can't skip through a thin wall.

const EXPLOSION_SCENE = preload("res://objects/explosion.tscn")
const LIFETIME = 3.0
# world + props
const HIT_MASK = 1 | 4
# The rocket's position is the point that hits things, so the body is drawn behind it with the
# nose tip exactly on that point
const BODY_LENGTH = 9.0
const BODY_HALF_WIDTH = 2.0
const NOSE_LENGTH = 3.0
const FIN_LENGTH = 3.0
const FIN_SPREAD = 2.0
const BODY_COLOR = Color(0.85, 0.85, 0.8)
const NOSE_COLOR = Color(0.9, 0.3, 0.25)
# Exhaust trail along the path actually flown, oldest point fades out
const TRAIL_POINTS = 10
const TRAIL_WIDTH = 2.0
const TRAIL_COLOR = Color(1, 0.7, 0.3, 0.6)

var direction = Vector2.RIGHT
var shooter = null
var age = 0.0
var trail = []


func _ready():
	rotation = direction.angle()


func _physics_process(delta):
	age += delta
	if age > LIFETIME:
		queue_free()
		return
	var next = global_position + direction * Game.tuning.rocket_speed * delta
	var query = PhysicsRayQueryParameters2D.create(global_position, next, HIT_MASK)
	if shooter:
		query.exclude = [shooter.get_rid()]
	var hit = get_world_2d().direct_space_state.intersect_ray(query)
	if hit:
		_explode(hit.position)
		return
	trail.push_front(global_position)
	if trail.size() > TRAIL_POINTS:
		trail.pop_back()
	global_position = next
	queue_redraw()


func _explode(point):
	var explosion = EXPLOSION_SCENE.instantiate()
	get_parent().add_child(explosion)
	explosion.global_position = point
	explosion.detonate()
	queue_free()


func _draw():
	var previous = Vector2.ZERO
	for i in trail.size():
		var point = to_local(trail[i])
		var color = TRAIL_COLOR
		color.a *= 1.0 - float(i) / TRAIL_POINTS
		draw_line(previous, point, color, TRAIL_WIDTH)
		previous = point

	var tail = -NOSE_LENGTH - BODY_LENGTH
	draw_rect(Rect2(tail, -BODY_HALF_WIDTH, BODY_LENGTH, BODY_HALF_WIDTH * 2), BODY_COLOR)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-NOSE_LENGTH, -BODY_HALF_WIDTH), Vector2(0, 0), Vector2(-NOSE_LENGTH, BODY_HALF_WIDTH)]),
		NOSE_COLOR)
	for side in [-1, 1]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(tail + FIN_LENGTH, side * BODY_HALF_WIDTH),
			Vector2(tail, side * (BODY_HALF_WIDTH + FIN_SPREAD)),
			Vector2(tail, side * BODY_HALF_WIDTH)]), NOSE_COLOR)
