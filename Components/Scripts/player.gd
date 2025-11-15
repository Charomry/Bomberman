# Player.gd
extends CharacterBody2D

# Movement
const SPEED := 50
const JUMP_VELOCITY = -75

# Gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Other
var air_jumps = 1
var current_air_jumps = 0

# Da Juice
var coyote_timer = 0.0
const COYOTE_TIME_THRESHOLD = 0.3

var jump_buffer_timer = 0.0
const JUMP_BUFFER_TIME_THRESHOLD = 0.2

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Reset air jumps and coyote time when on the floor
		current_air_jumps = air_jumps
		coyote_timer = COYOTE_TIME_THRESHOLD # Reload coyote time

	# Update timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# Handle Jump input (with buffer and coyote time)
	if Input.is_action_just_pressed("jump"): # "jump" is an action defined in InputMap
		jump_buffer_timer = JUMP_BUFFER_TIME_THRESHOLD

	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_timer > 0: # Normal jump or coyote time jump
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0 # Consume buffer
			coyote_timer = 0 # Consume coyote time if used
		elif current_air_jumps > 0: # Air jump (double jump, etc.)
			velocity.y = JUMP_VELOCITY * 0.8 # Perhaps a bit weaker
			current_air_jumps -= 1
			jump_buffer_timer = 0 # Consume buffer

	# Handle Horizontal input
	var direction = Input.get_axis("move_left", "move_right") # "move_left" & "move_right" from InputMap

	# Movement with simple acceleration/deceleration (you can make this more complex)
	if direction:
		# We use move_toward for basic acceleration/deceleration
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 2.0 * delta) # Last value is acceleration
		# Flip the sprite
		if $AnimatedSprite2D: # Ensure the node exists
			$AnimatedSprite2D.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 2.0 * delta) # Decelerate to a stop

	move_and_slide()

	# Update animations (simplified)
	update_animations()

func update_animations():
	if not $AnimatedSprite2D: return
	
	if not is_on_floor():
		if velocity.y < 0:
			$AnimatedSprite2D.play("idle")
		else:
			$AnimatedSprite2D.play("idle")
	else:
		if abs(velocity.x) > 5:
			$AnimatedSprite2D.play("run")
		else:
			$AnimatedSprite2D.play("idle")
