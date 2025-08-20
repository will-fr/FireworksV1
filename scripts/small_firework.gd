class_name SmallFirework extends AnimatedSprite2D



func _init() -> void:
	animation_finished.connect(_on_animation_finished)


func _on_animation_finished() -> void:
	queue_free()  # Destroy this object

func initialize(shell_type: int) -> void:
	if shell_type == Globals.BLUE:
		modulate = Color.BLUE
	elif shell_type == Globals.GREEN:
		modulate = Color.GREEN
	elif shell_type == Globals.RED:
		modulate = Color.RED
	elif shell_type == Globals.YELLOW:
		modulate = Color.YELLOW
