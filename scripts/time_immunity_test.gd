# scripts/time_immunity_test.gd

extends Node2D

@onready var label: Label = $Label

var test_value = 10.0
var max_value = 10.0
var regen_rate = 1.0

# This variable will be our target. 1.0 for normal, 0.0 for frozen.
var target_time_scale = 1.0

func _ready():
	# This is still correct. It makes this node's _process function run
	# even when the game is paused or time_scale is 0.
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta):
	# This gets the REAL time passed and is IMMUNE to Engine.time_scale.
	var real_delta = get_process_delta_time()

	# --- Input to Test ---
	# Press 'Down Arrow' to decrease the value.
	if Input.is_action_just_pressed("ui_down"):
		test_value -= 3.0
	
	# Press 'Q' to toggle the time freeze by changing our target.
	if Input.is_action_just_pressed("tactical_freeze"):
		if target_time_scale == 1.0:
			target_time_scale = 0.0
		else:
			target_time_scale = 1.0

	# --- Manual Animation for Time Scale ---
	# Every frame, we smoothly move the actual Engine.time_scale towards our target.
	# The '8.0' is a smoothness factor, you can make it higher for a faster transition.
	Engine.time_scale = lerp(Engine.time_scale, target_time_scale, real_delta * 8.0)

	# --- The Regeneration Logic ---
	# This logic is what we are testing. It uses our immune 'real_delta'.
	if test_value < max_value:
		test_value += regen_rate * real_delta
		if test_value > max_value:
			test_value = max_value
			
	# Update the label so we can see the values.
	var time_scale_text = "Time Scale: " + str(Engine.time_scale).pad_decimals(2)
	var value_text = "Value: " + str(test_value).pad_decimals(2)
	label.text = time_scale_text + "\n" + value_text
