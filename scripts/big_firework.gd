class_name BigFirework extends AnimatedSprite2D



func _init() -> void:
	animation_finished.connect(_on_animation_finished)


func _on_animation_finished() -> void:
	queue_free()  # Destroy this object