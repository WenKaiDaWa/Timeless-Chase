# scripts/cylinder_ui.gd

extends Control

@onready var bullet_container = $BulletContainer

var bullet_icons = [] # This will hold our Slot1, Slot2, etc. sprites.

# The _ready function will find our slots for us.
func _ready():
	# Get all the "Slot" sprites that are children of the BulletContainer.
	bullet_icons = bullet_container.get_children()

func update_display(current_ammo):
	# This function updates the color of the slots you placed.
	for i in range(bullet_icons.size()):
		var icon_slot = bullet_icons[i]
		if i < current_ammo:
			# This is a "full" chamber.
			icon_slot.modulate = Color.WHITE
		else:
			# This is an "empty" chamber.
			icon_slot.modulate = Color(0.6, 0.6, 0.6, 0.8)
