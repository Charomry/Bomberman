extends Area2D

@export var max_hits: int = 3
@export var piece_count: int = 16
@export var explosion_force: float = 300.0

var hits_taken: int = 0
var is_broken: bool = false
var previous_cursor_shape: int = Input.CURSOR_ARROW
var can_hit: bool = true

@onready var audio: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimationPlayer = $AnimationPlayer

var rock_rect: Rect2
var rock_piece_scene: PackedScene = preload("res://Components/Scene/rock_piece.tscn")
var cooldown_timer: Timer

func _ready() -> void:
	# Setup rock bounds (centered at 0)
	var tex_size = sprite.texture.get_size() * sprite.scale
	var half_size = tex_size / 2
	rock_rect = Rect2(-half_size, tex_size)
	
	# Setup cooldown timer
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = 1.0
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_end)
	add_child(cooldown_timer)
	
	# Connect animation finished
	anim.animation_finished.connect(_on_animation_finished)

func _on_mouse_entered() -> void:
	if is_broken: return
	previous_cursor_shape = Input.get_current_cursor_shape()
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	if is_broken: return
	Input.set_default_cursor_shape(previous_cursor_shape)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_broken or not can_hit: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		audio.play()
		can_hit = false
		cooldown_timer.start()
		hits_taken += 1
		var stage = hits_taken
		if stage > max_hits: 
			can_hit = true  # Reset immediately if over max
			return
		match stage:
			1:
				anim.play("crack1")
			2:
				anim.play("crack2")
			3:
				anim.play("crack3")
				is_broken = true
				collision_shape.disabled = true
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_cooldown_end() -> void:
	can_hit = true

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "crack3":
		anim.play("explode")
	elif anim_name == "explode":
		_shatter()

func _shatter() -> void:
	sprite.visible = false
	collision_shape.disabled = true
	
	# Spawn pieces
	var center = global_position
	for i in range(piece_count):
		var piece = rock_piece_scene.instantiate() as RigidBody2D
		get_parent().add_child(piece)
		var offset = Vector2(
			randf_range(-rock_rect.size.x / 2, rock_rect.size.x / 2),
			randf_range(-rock_rect.size.y / 2, rock_rect.size.y / 2)
		)
		piece.global_position = center + offset
		piece.rotation_degrees = randf_range(0, 360)
		piece.scale = Vector2.ONE * randf_range(0.8, 1.2)
		var force_dir = (piece.global_position - center).normalized()
		piece.linear_velocity = force_dir * randf_range(explosion_force * 0.5, explosion_force)
		piece.angular_velocity = randf_range(-200, 200)
	
	queue_free()
