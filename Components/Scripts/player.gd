# Player.gd
extends CharacterBody2D

# Movement
const SPEED := 300
const JUMP_VELOCITY = -300

# Gravity
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Other
var air_jumps = 1
var current_air_jumps = 0

# Da Juice
var coyote_timer = 0.0
const COYOTE_TIME_THRESHOLD = 0.1

var jump_buffer_timer = 0.0
const JUMP_BUFFER_TIME_THRESHOLD = 0.1

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		if not is_on_floor():
			velocity.y += gravity * delta
	else:
		current_air_jumps = air_jumps
		coyote_timer = COYOTE_TIME_THRESHOLD
	
	# Update Timers
	if coyote_timer > 0:
		coyote_timer -= delta
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME_THRESHOLD
	
	if jump_buffer_timer > 0:
		if is_on_floor() or coyote_timer > 0: # Normal jump or coyote time jump
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0 # Consume buffer
			coyote_timer = 0 
		elif current_air_jumps > 0:
			velocity.y = JUMP_VELOCITY * 0.8
			current_air_jumps -= 1
			jump_buffer_timer = 0
	
	
		# Handle Horizontal Input
	var direction = Input.get_axis("move_left", "move_right") # "move_left" & "move_right"
	
	
# 	Movement Simple
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, SPEED * 2.0 * delta) # Accelerate
		# Flip the Spritre
		if $AnimatedSprite2D:
			$AnimatedSprite2D.flip_h = (direction < 0)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * 2.0 * delta) # Decelerate
		
		move_and_slide()
		
		# Update Animations
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
