class_name Player
extends AnimatedSprite2D

var initial_x:float = 0


# Custom signal emitted when player changes status
signal status_changed(new_status: flip_status)

# Custom signal emitted when player changes column
signal column_changed(new_column: int)

# Custom signal emitted when player forces gravity
signal force_gravity

# Player status enum
enum flip_status { FRONT, BACK }
var player_status: flip_status = flip_status.FRONT  # Start in FRONT status

# Player movement variables
var current_column: int = 0  # Start in a center column (0-3 for 4 columns)


func _init() -> void:
	initial_x = position.x
	# Connect to animation finished signal to handle animation transitions
	animation_finished.connect(_on_animation_finished)

# Handle input for column movement (keyboard and joystick)
func _input(event: InputEvent) -> void:
	# Handle keyboard input
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT, KEY_A:
				move_left()
			KEY_RIGHT, KEY_D:
				move_right()
			KEY_UP, KEY_W:
				flip_switch_status()
			KEY_DOWN, KEY_S:
				force_gravity.emit()
				print("Force gravity activated!")
	
	# Handle joystick/gamepad input
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				move_left()
			JOY_BUTTON_DPAD_RIGHT:
				move_right()
			JOY_BUTTON_DPAD_DOWN:
				force_gravity.emit()
				print("Force gravity activated!")
			JOY_BUTTON_X:  # A button (Xbox) / Cross (PlayStation)
				force_gravity.emit()
				print("Force gravity activated!")
			JOY_BUTTON_A:  # Y button (Xbox) / Triangle (PlayStation)
				flip_switch_status()
	
	# Handle analog stick input
	elif event is InputEventJoypadMotion:
		# Left analog stick horizontal movement
		if event.axis == JOY_AXIS_LEFT_X:
			if event.axis_value < -0.5:  # Left stick moved left
				move_left()
			elif event.axis_value > 0.5:  # Left stick moved right
				move_right()
		# Left analog stick vertical movement
		elif event.axis == JOY_AXIS_LEFT_Y:
			if event.axis_value < -0.5:  # Left stick moved up
				flip_switch_status()
			elif event.axis_value > 0.5:  # Left stick moved down
				force_gravity.emit()
				print("Force gravity activated!")

# Move player to the left column
func move_left():
	if current_column > 0:
		# Create a tween for smooth movement
		var tween = create_tween()
		var start_x = initial_x + (current_column * Globals.BLOCK_SIZE)
		var target_x = start_x - Globals.BLOCK_SIZE
		print ("move from ", start_x, " to ", target_x)

		
		# Animate position over 0.25 seconds
		tween.tween_property(self, "position:x", target_x, 0.1)
		
		# Play the move_left_front animation
		if player_status == flip_status.FRONT:
			play("move_left_front")
		else:
			play("move_left_back")


		current_column -= 1
		emit_signal("column_changed", current_column)
		

# Move player to the right column  
func move_right():
	# Use the global NUM_COLUMNS constant
	var max_column = Globals.NUM_COLUMNS - 2
	if current_column < max_column:
		# Create a tween for smooth movement
		var tween = create_tween()
		var start_x = initial_x + (current_column * Globals.BLOCK_SIZE)
		var target_x = start_x + Globals.BLOCK_SIZE
		print ("move from ", start_x, " to ", target_x)

		
		# Animate position over 0.25 seconds
		tween.tween_property(self, "position:x", target_x, 0.1)
		
		# Play the move_right_front animation
		if player_status == flip_status.FRONT:
			play("move_right_front")
		else:
			play("move_right_back")
		current_column += 1
		emit_signal("column_changed", current_column)


func flip_switch_status():
	if player_status == flip_status.FRONT:
		player_status = flip_status.BACK
		status_changed.emit(player_status)
		play("flip_f2b")
		print("Player status switched to BACK")
	else:
		player_status = flip_status.FRONT
		status_changed.emit(player_status)
		play("flip_b2f")
		print("Player status switched to FRONT")


# Get the player's current column position
func get_column() -> int:
	return current_column

# Get the player's current status (FRONT or BACK)
func get_status() -> flip_status:
	return player_status

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

# Handle animation finished events
func _on_animation_finished():
	# If the move_right_front animation just finished, return to previous animation
	if player_status == flip_status.FRONT:
		play("front")
	else:
		play("back")
