extends Label

func initialize(increment:int, pos_x:int, pos_y:int ) -> void:
	self.text = str(increment)
	self.position = Vector2(pos_x, pos_y)
	z_index = 100  # Ensure it's on top
	# Start the animation immediately after initialization
	animate_and_destroy()
	print("Player points incremented")

func animate_and_destroy():
	# Create tween for the animation
	var tween = create_tween()
	
	# Set up parallel tweens for movement and fade
	tween.set_parallel(true)
	
	# Move up 10px over 0.8 seconds
	var start_y = position.y
	var end_y = start_y - 10
	tween.tween_property(self, "position:y", end_y, 0.8)
	
	# Fade away over 0.5 seconds
	tween.tween_property(self, "modulate:a", 0.2, 0.5)
	
	# Wait for both parallel tweens to complete, then destroy
	tween.set_parallel(false)  # Disable parallel mode for the callback
	tween.tween_callback(destroy_node)

# Function to destroy this node after animation
func destroy_node():
	print("Points: Animation complete, destroying node")
	queue_free()

