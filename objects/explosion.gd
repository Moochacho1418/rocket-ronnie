extends Node2D

# One blast: pushes everything in the radius away from the centre, then breaks breakable tiles.
# Uses an instant shape query rather than an Area2D, because an Area2D only learns about overlaps
# on the next physics frame and the push would land a frame late.

const DEBRIS_SCENE = preload("res://objects/debris.tscn")
# player + props + debris
const PUSH_MASK = 2 | 4 | 8
const MAX_PUSHED = 64
# Caps chaos so a big chain of blasts can't tank the frame rate
const MAX_DEBRIS = 40
const DEBRIS_PUSH = 160.0
const FADE_TIME = 0.25
const COLOR = Color(1, 0.6, 0.2, 0.5)

var fade = FADE_TIME


func detonate():
	_push_bodies()
	_break_tiles()


func _push_bodies():
	var tuning = Game.tuning
	var shape = CircleShape2D.new()
	shape.radius = tuning.blast_radius
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = PUSH_MASK
	var pushed = {}
	for result in get_world_2d().direct_space_state.intersect_shape(query, MAX_PUSHED):
		var body = result.collider
		if pushed.has(body):
			continue
		pushed[body] = true
		var offset = body.global_position - global_position
		var dist = offset.length()
		var dir = offset / dist if dist > 0.001 else Vector2.UP
		var push = dir * tuning.blast_strength * _falloff(dist)
		if body.has_method("apply_blast"):
			body.apply_blast(push)
		elif body is RigidBody2D:
			body.apply_central_impulse(push * body.mass * tuning.prop_push_scale)


func _falloff(dist):
	var t = clamp(dist / Game.tuning.blast_radius, 0.0, 1.0)
	var curve = Game.tuning.falloff
	return curve.sample(t) if curve else 1.0 - t


func _break_tiles():
	var radius = Game.tuning.break_radius
	for layer in get_tree().get_nodes_in_group("terrain"):
		var corner = Vector2(radius, radius)
		var from = layer.local_to_map(layer.to_local(global_position - corner))
		var to = layer.local_to_map(layer.to_local(global_position + corner))
		for x in range(from.x, to.x + 1):
			for y in range(from.y, to.y + 1):
				var cell = Vector2i(x, y)
				var data = layer.get_cell_tile_data(cell)
				if data == null or not data.get_custom_data("breakable"):
					continue
				var centre = layer.to_global(layer.map_to_local(cell))
				if centre.distance_to(global_position) > radius:
					continue
				layer.erase_cell(cell)
				_spawn_debris(centre)


func _spawn_debris(at):
	if get_tree().get_node_count_in_group("debris") >= MAX_DEBRIS:
		return
	var debris = DEBRIS_SCENE.instantiate()
	get_parent().add_child(debris)
	debris.global_position = at
	var dir = (at - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.UP
	debris.apply_central_impulse(dir * DEBRIS_PUSH * debris.mass)


func _process(delta):
	fade -= delta
	if fade <= 0:
		queue_free()
	queue_redraw()


# The fading circle is drawn at the full blast radius, which doubles as the radius debug view
func _draw():
	var color = COLOR
	color.a *= fade / FADE_TIME
	draw_circle(Vector2.ZERO, Game.tuning.blast_radius, color)
