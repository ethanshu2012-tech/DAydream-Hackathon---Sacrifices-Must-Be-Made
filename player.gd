extends CharacterBody2D

# ---------------------------
# MOVEMENT
# ---------------------------
const SPEED := 500.0
const JUMP_VELOCITY := -700.0
var GRAVITY: float = 1200.0

# ---------------------------
# DOUBLE JUMP
# ---------------------------
const MAX_JUMPS := 2  # allows double jump
var jumps_left := MAX_JUMPS

# ---------------------------
# HEALTH
# ---------------------------
var max_health: int = 100
var current_health: int = 100
@onready var health_bar := $"Health Bar"

# ---------------------------
# MAP / RESPAWN
# ---------------------------
const FALL_DEATH_Y := 1000.0
var spawn_position: Vector2

# ---------------------------
# READY
# ---------------------------
func _ready() -> void:
	spawn_position = global_position

	var g = ProjectSettings.get_setting("physics/2d/default_gravity")
	match typeof(g):
		TYPE_FLOAT, TYPE_INT:
			GRAVITY = float(g)
		TYPE_VECTOR2:
			GRAVITY = abs(g.y)
		_:
			pass

	# Initialize health bar
	if health_bar:
		if "max_value" in health_bar:
			health_bar.max_value = max_health
		elif "max" in health_bar:
			health_bar.max = max_health
		health_bar.value = current_health

		var color := Color(0, 1, 0)
		if health_bar is ProgressBar:
			var style := StyleBoxFlat.new()
			style.bg_color = color
			health_bar.add_theme_stylebox_override("fill", style)
		elif health_bar is TextureProgressBar:
			health_bar.tint_progress = color

# ---------------------------
# PHYSICS PROCESS
# ---------------------------
func _physics_process(delta: float) -> void:
	# --- Gravity ---
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0
		jumps_left = MAX_JUMPS  # reset jumps when landing

	# --- Jump ---
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		velocity.y = JUMP_VELOCITY
		jumps_left -= 1

	# --- Horizontal movement ---
	var input_dir := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if abs(input_dir) < 0.01:
		input_dir = Input.get_action_strength("right") - Input.get_action_strength("left")

	if abs(input_dir) > 0.01:
		velocity.x = input_dir * SPEED
	else:
		velocity.x = 0

	# --- Move the character ---
	move_and_slide()

	# --- Check if player fell off map ---
	if global_position.y > FALL_DEATH_Y:
		die()

# ---------------------------
# HEALTH SYSTEM
# ---------------------------
func take_damage(amount: int) -> void:
	current_health = max(current_health - amount, 0)
	_update_health_bar()
	if current_health <= 0:
		die()

func heal(amount: int) -> void:
	current_health = min(current_health + amount, max_health)
	_update_health_bar()

func _update_health_bar() -> void:
	if health_bar:
		health_bar.value = current_health
		var health_ratio := float(current_health) / float(max_health)
		var color := Color(0, 1, 0)
		if health_ratio <= 0.25:
			color = Color(1, 0, 0)
		elif health_ratio <= 0.5:
			color = Color(1, 1, 0)

		if health_bar is ProgressBar:
			var style := StyleBoxFlat.new()
			style.bg_color = color
			health_bar.add_theme_stylebox_override("fill", style)
		elif health_bar is TextureProgressBar:
			health_bar.tint_progress = color

# ---------------------------
# DEATH & RESPAWN
# ---------------------------
func die() -> void:
	respawn()

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	current_health = max_health
	_update_health_bar()
	jumps_left = MAX_JUMPS  # reset double jump on respawn
