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

	# --- Initial Setup ---
	var mouse_pos = get_global_mouse_position()
	var current_direction = (mouse_pos - global_position).normalized()
	var current_position = global_position + current_direction * 20
	var bounces_left = MAX_BOUNCES
	
	# We start the line from the player's muzzle
	trajectory_line.add_point(to_local(current_position))
	
	var all_bullets = get_tree().get_nodes_in_group("bullets")
	var space_state = get_world_2d().direct_space_state

	# --- Simulation Parameters ---
	# time_step: How far into the future we check each segment. Smaller is more accurate but more expensive.
	const time_step = 0.03 
	# num_segments: How many steps we simulate. This determines the max length of the line.
	const num_segments = 100 

	for i in range(num_segments):
		var move_vector = current_direction * 600 * time_step # 600 is your bullet speed

		# --- 1. Check for WALL collisions first ---
		var wall_query = PhysicsRayQueryParameters2D.create(current_position, current_position + move_vector)
		wall_query.exclude = [self] + all_bullets # Ignore player and bullets for wall check
		var wall_result = space_state.intersect_ray(wall_query)
		
		if wall_result:
			# Hit a wall. Add the point, calculate bounce, and continue simulation.
			trajectory_line.add_point(to_local(wall_result.position))
			current_direction = current_direction.bounce(wall_result.normal)
			current_position = wall_result.position + current_direction * 0.1
			bounces_left -= 1
			if bounces_left < 0:
				break # Stop if we're out of bounces
			continue # Go to next loop iteration with new bounce direction

		# --- 2. If no wall, check for BULLET collisions ---
		var hit_a_bullet = false
		for bullet in all_bullets:
			# Predict the future position of this existing bullet
			var bullet_future_pos = bullet.global_position + bullet.linear_velocity * time_step * (i + 1)
			# Predict the future position of our new bullet
			var our_future_pos = current_position + move_vector
			
			# Check if our path segment intersects the bullet's future position
			# We treat the bullet as a small circle (radius ~10)
			if Geometry2D.segment_intersects_circle(current_position, our_future_pos, bullet_future_pos, 10.0) != -1:
				# A collision is predicted!
				trajectory_line.add_point(to_local(our_future_pos))
				
				# For simplicity, we'll just stop the line here.
				# Predicting bounces between two moving objects is extremely complex.
				hit_a_bullet = true
				break
		
		if hit_a_bullet:
			break # Exit the main simulation loop if we predicted a bullet collision

		# --- 3. If nothing was hit, just extend the line ---
		current_position += move_vector
		trajectory_line.add_point(to_local(current_position))


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
