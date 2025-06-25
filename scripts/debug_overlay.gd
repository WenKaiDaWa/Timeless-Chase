# scripts/debug_overlay.gd

extends CanvasLayer

# We have slots for the nodes we want to watch.
@export var player_node: CharacterBody2D
@export var stamina_bar: ProgressBar
@export var stamina_ghost_bar: ProgressBar

# A reference to our label child node.
@onready var text_label: Label = $Label

func _process(delta):
	# If any of our nodes haven't been plugged in via the Inspector, show a warning.
	if not is_instance_valid(player_node) or not is_instance_valid(stamina_bar):
		text_label.text = "Awaiting nodes to be assigned in the Inspector..."
		return

	# --- Build the debug text block ---
	var debug_text = ""
	debug_text += "--- PLAYER DATA ---\n"
	debug_text += "Stamina: %s / %s \n" % [str(player_node.current_stamina).pad_decimals(2), player_node.max_stamina]
	debug_text += "Ammo: %s / %s \n" % [player_node.current_ammo, player_node.max_ammo]
	debug_text += "\n--- COOLDOWNS ---\n"
	debug_text += "Can Fire Again In: %s \n" % str(player_node.fire_cooldown_countdown).pad_decimals(2)
	debug_text += "Stamina Regen Delay: %s" % str(player_node.regen_delay_countdown).pad_decimals(2)
	
	# Display the text on our label.
	text_label.text = debug_text
