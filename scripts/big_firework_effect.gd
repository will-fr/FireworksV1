extends AnimatedSprite2D


@onready var firework_sound: AudioStreamPlayer2D = $FireworkSound

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to the animation_finished signal to destroy the node when done
	animation_finished.connect(_on_animation_finished)

	# Launch the firework sound once (with null check)
	if firework_sound != null:
		firework_sound.play()
	else:
		print("Warning: FireworkSound node not found!")


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
