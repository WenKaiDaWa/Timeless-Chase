# scripts/player.gd

extends CharacterBody2D

# --- Player Properties ---
@export var speed = 250.0
@export var roll_speed = 750.0
@export var roll_duration = 0.25
@export var fire_cooldown_duration = 0.25

# --- Ammo & Revolver Properties ---
@export var max_ammo = 6
var current_ammo: int
var fire_cooldown_countdown = 0.0

# --- Stamina Properties ---
@export var max_stamina = 10.0
@export var roll_cost = 3.0
@export var stamina_regen_rate = 1.5
@export var regen_delay_duration = 0.75
var current_stamina: float
var regen_delay_countdown = 0.0

# --- Time Control Properties ---
@export var slowdown_factor = 0.05
var target_time_scale = 1.0

# --- State Tracking ---
var is_rolling = false
var roll_timer = 0.0
var roll_start_position: Vector2
var roll_target_position: Vector2

# --- Manual Clock Variable ---
var last_frame_ticks = 0

# --- Node References & Preloads ---
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
const BouncingBullet = preload("res://scenes/bouncing_bullet.tscn")
@onready var trajectory_line: Line2D = $TrajectoryLine
const MAX_BOUNCES = 5


func _ready():
	current_stamina = max_stamina
	current_ammo = max_ammo
	process_mode = Node.PROCESS_MODE_ALWAYS
	last_frame_ticks = Time.get_ticks_usec()
	trajectory_line.visible = false

func _physics_process(delta):
	if is_rolling: return
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_direction != Vector2.ZERO:
		velocity = input_direction.normalized() * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	move_and_slide()

func _process(delta):
	var manual_delta = (Time.get_ticks_usec() - last_frame_ticks) / 1000000.0
	last_frame_ticks = Time.get_ticks_usec()

	Engine.time_scale = lerp(Engine.time_scale, target_time_scale, manual_delta * 8.0)
	handle_inputs()
	if is_rolling:
		_process_roll(manual_delta)
		return

	regen_delay_countdown = max(0, regen_delay_countdown - manual_delta)
	fire_cooldown_countdown = max(0, fire_cooldown_countdown - manual_delta)
	if regen_delay_countdown <= 0:
		current_stamina = move_toward(current_stamina, max_stamina, stamina_regen_rate * manual_delta)

	if target_time_scale != 1.0 and not is_rolling:
		_update_trajectory()

func handle_inputs():
	if Input.is_action_just_pressed("fire") and not is_rolling and current_ammo > 0 and fire_cooldown_countdown <= 0:
		fire_bullet()
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if Input.is_action_just_pressed("tactical_freeze"):
		if target_time_scale == 1.0:
			target_time_scale = slowdown_factor
			trajectory_line.visible = true
		else:
			target_time_scale = 1.0
			trajectory_line.visible = false

	if Input.is_action_just_pressed("roll") and not is_rolling and current_stamina >= roll_cost and input_direction != Vector2.ZERO:
		perform_roll(input_direction)
	if Input.is_action_just_pressed("reload"):
		reload()

func _update_trajectory():
	trajectory_line.clear_points()

	# These calculations perfectly mirror your fire_bullet() function for accuracy
	var mouse_position = get_global_mouse_position()
	var fire_direction = (mouse_position - global_position).normalized()
	var start_pos = global_position + fire_direction * 20
	
	var remaining_bounces = MAX_BOUNCES
	var space_state = get_world_2d().direct_space_state
	
	# Add the very first point of the line
	trajectory_line.add_point(to_local(start_pos))

	while remaining_bounces >= 0:
		var query = PhysicsRayQueryParameters2D.create(start_pos, start_pos + fire_direction * 4000)
		query.exclude = [self] # Exclude the player itself from the raycast
		
		var result = space_state.intersect_ray(query)
		
		if result:
			trajectory_line.add_point(to_local(result.position))
			fire_direction = fire_direction.bounce(result.normal)
			start_pos = result.position + fire_direction * 0.1
			remaining_bounces -= 1
		else:
			trajectory_line.add_point(to_local(start_pos + fire_direction * 4000))
			break # Stop if the ray flies off into space

func fire_bullet():
	current_ammo -= 1
	regen_delay_countdown = regen_delay_duration
	fire_cooldown_countdown = fire_cooldown_duration
	var bullet_instance = BouncingBullet.instantiate()
	var mouse_position = get_global_mouse_position()
	var fire_direction = (mouse_position - global_position).normalized()
	bullet_instance.global_position = global_position + fire_direction * 20
	bullet_instance.linear_velocity = fire_direction * 600
	get_tree().root.add_child(bullet_instance)

func reload():
	print("Reloading!")
	current_ammo = max_ammo
	
func perform_roll(direction: Vector2):
	is_rolling = true; current_stamina -= roll_cost; regen_delay_countdown = regen_delay_duration; roll_timer = roll_duration; roll_start_position = global_position; roll_target_position = global_position + direction.normalized() * roll_speed * roll_duration; collision_shape.disabled = true
	trajectory_line.visible = false
	
func _process_roll(manual_delta: float):
	roll_timer -= manual_delta
	if roll_timer > 0:
		var progress = 1.0 - (roll_timer / roll_duration); global_position = roll_start_position.lerp(roll_target_position, progress)
	else:
		global_position = roll_target_position; is_rolling = false; collision_shape.disabled = false; velocity = Vector2.ZERO
