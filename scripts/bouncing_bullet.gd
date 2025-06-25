# scripts/bouncing_bullet.gd

extends RigidBody2D

# --- Properties ---
var bounces_remaining = 5
@export var trail_length = 30

# --- Nodes ---
@onready var line_trail: Line2D = $Line2D

# This function's only job is to draw the trail
func _physics_process(delta):
	line_trail.add_point(global_position)
	while line_trail.get_point_count() > trail_length:
		line_trail.remove_point(0)

# This function handles any collision
func _on_body_entered(body):
	# For now, we assume any collision is a bounce against a wall.
	bounces_remaining -= 1
	if bounces_remaining <= 0:
		queue_free() # Destroy the bullet if it's out of bounces.
