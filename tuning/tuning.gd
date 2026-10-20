class_name Tuning
extends Resource

# Every number that decides how a rocket jump feels. The values live in tuning.tres (edit it in the
# inspector between play sessions); one shared instance is loaded on Game.tuning.

@export_group("Movement")
@export_range(0, 400) var run_speed = 140.0
@export_range(0, 4000) var ground_accel = 1400.0
@export_range(0, 4000) var ground_decel = 1800.0
@export_range(0, 4000) var air_accel = 700.0
# How fast blast momentum above run speed bleeds off in the air
@export_range(0, 2000) var air_drag = 150.0
# Tiny on purpose: enough for a curb, not a platform. Height comes from rockets.
@export_range(0, 500) var hop_velocity = 200.0
@export_range(0, 3000) var gravity = 900.0
@export_range(0, 1500) var max_fall_speed = 500.0
# Hard cap on total speed so stacked blasts can't fling Ronnie through walls
@export_range(100, 3000) var max_speed = 900.0
# Grace windows: hop just after leaving a ledge, or just before landing
@export_range(0, 0.3) var coyote_time = 0.08
@export_range(0, 0.3) var hop_buffer_time = 0.1

@export_group("Rockets")
@export_range(1, 10, 1) var rocket_count = 2
@export_range(50, 1500) var rocket_speed = 350.0
@export_range(0, 1) var rocket_cooldown = 0.15
# A click this soon before the cooldown ends still fires when it does
@export_range(0, 0.3) var fire_buffer_time = 0.1
# Firing in the air kicks Ronnie the opposite way from where she aims
@export_range(0, 1500) var air_recoil = 350.0

@export_group("Health")
@export_range(1, 500, 1) var max_health = 100

@export_group("Blast")
@export_range(8, 200) var blast_radius = 40.0
@export_range(0, 1500) var blast_strength = 520.0
# Push multiplier by distance: x is 0 at the blast centre and 1 at the edge of the radius
@export var falloff: Curve
# Remove the part of Ronnie's velocity that points against the blast before adding the push,
# so a blast while falling launches as high as one while standing
@export var cancel_opposing_velocity = true
@export_range(0, 120) var break_radius = 30.0
@export_range(0, 5) var prop_push_scale = 1.0
