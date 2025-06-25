# scripts/ui.gd

extends Control

@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var stamina_ghost_bar: ProgressBar = $StaminaGhostBar
@onready var cylinder_ui = $CylinderUI

var player_node: CharacterBody2D

func _ready():
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
	update_stamina_bar(delta)
	update_ammo_display()

func update_stamina_bar(delta: float):
	stamina_bar.value = player_node.current_stamina
	if stamina_ghost_bar.value > stamina_bar.value:
		stamina_ghost_bar.value = move_toward(stamina_ghost_bar.value, stamina_bar.value, (delta * 5.0))
	else:
		stamina_ghost_bar.value = stamina_bar.value

func update_ammo_display():
	cylinder_ui.update_display(player_node.current_ammo)
