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
