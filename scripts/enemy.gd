# scripts/enemy.gd

extends CharacterBody2D

@export var health = 3

func take_damage(amount):
	health -= amount
	print("Enemy took damage! Health is now: ", health) # A debug print
	if health <= 0:
		queue_free() # If health is zero, destroy the enemy.

func _on_hitbox_body_entered(body):
	# This function will be connected to our Hitbox's signal.
	# It checks if the thing that entered the hitbox is a bullet.
	if body.is_in_group("bullets"):
		take_damage(1) # Apply 1 damage
		body.queue_free() # Destroy the bullet on impact
