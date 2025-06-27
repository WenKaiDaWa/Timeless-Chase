# scripts/ui.gd

extends Control

const GHOST_BAR_SPEED = 5.0 # Speed in stamina units per second.

@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var stamina_ghost_bar: ProgressBar = $StaminaGhostBar
@onready var cylinder_ui = $CylinderUI

var player_node: CharacterBody2D
var previous_ticks: int = 0

func _ready():
	previous_ticks = Time.get_ticks_usec()
	
	await get_tree().process_frame
	if get_tree().root.has_node("TestGym/Player"):
		player_node = get_tree().root.get_node("TestGym/Player")
		if player_node != null:
			stamina_bar.max_value = player_node.max_stamina
			stamina_bar.value = player_node.max_stamina
			stamina_ghost_bar.max_value = player_node.max_stamina
			stamina_ghost_bar.value = player_node.max_stamina

func _process(delta):
	if player_node == null: return

	# Calculate our own delta that is immune to Engine.time_scale
	var manual_delta = (Time.get_ticks_usec() - previous_ticks) / 1000000.0
	previous_ticks = Time.get_ticks_usec()

	# Pass our new manual_delta to the update function
	update_stamina_bar(manual_delta)
	update_ammo_display()

func update_stamina_bar(manual_delta: float):
	stamina_bar.value = player_node.current_stamina
	
	# This will now work correctly even when time is slowed down.
	if stamina_ghost_bar.value != stamina_bar.value:
		stamina_ghost_bar.value = move_toward(stamina_ghost_bar.value, stamina_bar.value, GHOST_BAR_SPEED * manual_delta)


# It tells the cylinder_ui node to update its visuals based on the player's ammo.
func update_ammo_display():
	if cylinder_ui != null:
		cylinder_ui.update_display(player_node.current_ammo)
