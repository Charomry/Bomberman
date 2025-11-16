extends RigidBody2D

@export var base_impulse_strength := -1.5
@export var random_impulse_variation: float = 0.1

@onready var timer: Timer = $Timer
@onready var area: Area2D = $Area2D  # Add an Area2D child in the scene with a CollisionShape2D matching the piece

var previous_cursor_shape: int = Input.CURSOR_ARROW

func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		
		var click_global = event.global_position # Direction
		var direction = (click_global - global_position).normalized()
		var strength = base_impulse_strength * (1.0 + randf_range(-random_impulse_variation, random_impulse_variation))
		
		var click_local = to_local(click_global)
		apply_impulse(direction * strength, click_local)
		

func _on_timer_timeout() -> void:
	queue_free()
