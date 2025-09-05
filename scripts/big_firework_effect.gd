extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to the animation_finished signal to destroy the node when done
	animation_finished.connect(_on_animation_finished)

func initialize(color_tint: int = 0):
	if color_tint == 3:
		modulate = Color.GREEN
	elif color_tint == 4:
		modulate = Color.RED
	elif color_tint == 5:
		modulate = Color.BLUE
	elif color_tint == 6:
		modulate = Color.YELLOW

# Called when the animation finishes playing
func _on_animation_finished():
	queue_free()  # Destroy this node

