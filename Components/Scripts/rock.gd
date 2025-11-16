extends Area2D

var is_hovering: bool = false
var previous_cursor_shape: int = Input.CURSOR_ARROW
var is_broken: bool = false  # Prevent multiple breaks
@export var max_hits: int = 3  # Clicks needed to break (tweak in Inspector)
var hits_taken: int = 0


@onready var audio := $AudioStreamPlayer2D
@onready var sprite: Sprite2D = $Sprite2D  # Reference to your Sprite2D child
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
var rock_rect: Rect2  # For spawning pieces inside bounds

@export var crack_count: int = 8  # Number of crack lines
@export var piece_count: int = 16  # Number of shatter pieces
@export var crack_delay: float = 0.3  # Time between crack waves (for progressive feel)
@export var shatter_delay: float = 1.5  # Total time before full break
@export var explosion_force: float = 300.0  # Scatter speed

var rock_piece_scene: PackedScene = preload("res://Components/Scene/rock_piece.tscn")
var crack_timer: Timer
var shatter_timer: Timer

func _ready() -> void:
	
	# Setup timers
	crack_timer = Timer.new()
	crack_timer.wait_time = crack_delay
	crack_timer.timeout.connect(_add_crack_wave)
	add_child(crack_timer)
	
	shatter_timer = Timer.new()
	shatter_timer.wait_time = shatter_delay
	shatter_timer.one_shot = true
	shatter_timer.timeout.connect(_shatter)
	add_child(shatter_timer)
	
	# Get rock bounds for piece spawning
	rock_rect = Rect2(position, sprite.texture.get_size() * sprite.scale)
	var tex_size = sprite.texture.get_size() * sprite.scale
	var half_size = tex_size / 2
	rock_rect = Rect2(-half_size, tex_size)

func _on_mouse_entered() -> void:
	if is_broken: return
	is_hovering = true
	previous_cursor_shape = Input.get_current_cursor_shape()
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	if is_broken: return
	is_hovering = false
	Input.set_default_cursor_shape(previous_cursor_shape)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_broken: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		audio.playing = true
		var click_local = to_local(event.position)
		hits_taken += 1
		print("Hit ", hits_taken, "/", max_hits)  # Debug log (remove later)
		
		_add_crack_from_click(click_local)
		
		if hits_taken >= max_hits:
			_start_final_crack_sequence(click_local)

func _add_crack_from_click(click_pos_local: Vector2) -> void:
	# Add immediate cracks from this click (scaled by hits for density)
	var this_wave_count = int(crack_count * (hits_taken / float(max_hits)))  # More cracks on later hits
	for i in range(this_wave_count):
		var crack = Line2D.new()
		crack.width = 2.0 + (hits_taken * 0.5)  # Thicker on later hits
		crack.default_color = Color(0.1, 0.1, 0.1, 1.0)
		add_child(crack)
		
		# Start from click
		var start_pos = click_pos_local
		start_pos = rock_rect.position + (start_pos - rock_rect.position).clamp(Vector2.ZERO, rock_rect.size)
		
		# Random direction (slight radial bias from rock center)
		var from_center_dir = (start_pos - Vector2.ZERO).normalized()
		var direction = from_center_dir.rotated(randf_range(-PI/3, PI/3)).normalized()  # Narrower fan for focused cracks
		
		# End point
		var crack_length = randf_range(rock_rect.size.x * 0.2, rock_rect.size.y * 0.4)
		var end_pos = start_pos + direction * crack_length
		end_pos = rock_rect.position + (end_pos - rock_rect.position).clamp(Vector2.ZERO, rock_rect.size)
		
		crack.add_point(start_pos)
		crack.add_point(end_pos)

func _start_final_crack_sequence(click_pos_local: Vector2) -> void:
	is_broken = true  # Now lock only on final sequence
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	collision_shape.disabled = true
	
	# Final progressive waves (from last click or center)
	_add_crack_wave(click_pos_local)
	crack_timer.start()  # Adds more waves every crack_delay
	
	# Schedule shatter
	shatter_timer.start()

func _start_cracking(click_pos: Vector2) -> void:
	is_broken = true  # Lock interactions
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)  # Reset cursor
	collision_shape.disabled = true  # Disable further input
	
	# First crack wave at click point
	_add_crack_wave(click_pos)
	
	# Progressive waves
	crack_timer.start()
	
	# Schedule shatter
	shatter_timer.start()

func _add_crack_wave(click_pos_local: Vector2 = Vector2.ZERO) -> void:
	# Use half count per wave for progression
	@warning_ignore("integer_division")
	var waves_per_call = crack_count
	for i in range(waves_per_call):
		var crack = Line2D.new()
		crack.width = 2.0
		crack.default_color = Color(0.1, 0.1, 0.1, 1.0)  # Slightly gray for subtlety
		add_child(crack)
		
		# Start from click or center (both already local)
		var start_pos = click_pos_local if click_pos_local != Vector2.ZERO else Vector2.ZERO
		
		# Random direction from start (or radial from center)
		var from_center_dir = (start_pos - Vector2.ZERO).normalized() if start_pos.length() > 0 else Vector2.RIGHT
		var direction = from_center_dir.rotated(randf_range(-PI/2, PI/2)).normalized()  # ±90° fan for more radial feel
		
		# End point: extend from start
		var crack_length = randf_range(rock_rect.size.x * 0.1, rock_rect.size.y * 0.2)  # Varied length
		var end_pos = start_pos + direction * crack_length
		
		# Clamp to rock bounds (now correctly centered)
		end_pos = rock_rect.position + (end_pos - rock_rect.position).clamp(Vector2.ZERO, rock_rect.size)
		start_pos = rock_rect.position + (start_pos - rock_rect.position).clamp(Vector2.ZERO, rock_rect.size)  # Clamp start too, for edge clicks
		
		crack.add_point(start_pos)
		crack.add_point(end_pos)
		
		# Optional: Fade out cracks
		var tween = create_tween()
		tween.tween_property(crack, "modulate:a", 0.0, 0.8).set_delay(0.4)

func _shatter() -> void:
	crack_timer.stop()
	
	# Hide original rock
	sprite.visible = false
	collision_shape.disabled = true
	
	# Optional: Play break sound or emit particles
	# $AudioStreamPlayer2D.play()
	# $GPUParticles2D.emitting = true
	
	# Spawn pieces
	var center = global_position
	for i in range(piece_count):
		var piece = rock_piece_scene.instantiate() as RigidBody2D
		get_parent().add_child(piece)
		
		# Random position inside rock bounds
		var offset = Vector2(
			randf_range(-rock_rect.size.x / 2, rock_rect.size.x / 2),
			randf_range(-rock_rect.size.y / 2, rock_rect.size.y / 2)
		)
		piece.global_position = center + offset
		
		# Random rotation and scale variation
		piece.rotation_degrees = randf_range(0, 360)
		piece.scale = Vector2.ONE * randf_range(0.8, 1.2)
		
		# Explosive force
		var force_dir = (piece.global_position - center).normalized()
		piece.linear_velocity = force_dir * randf_range(explosion_force * 0.5, explosion_force)
		piece.angular_velocity = randf_range(-200, 200)  # Spin
		
		# Auto-destroy after lifetime (if Timer in RockPiece.tscn)
		# Or add here: var timer = Timer.new(); ... timeout.connect(queue_free)
	
	# Clean up
	queue_free()
