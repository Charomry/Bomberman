extends Area2D

@onready var anim := $AnimationPlayer

func _ready() -> void:
	anim.play("explode")

func self_destruct():
	pass
