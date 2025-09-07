class_name Player  extends AnimatedSprite2D

var initial_x:float = 0
var is_lifting: bool = false


signal player_flipped()
signal gravity_forced
signal player_lifted()
signal player_dropped()

# Player status enum
enum player_dic { P1, P2, CPU }
@export var player_type: player_dic = player_dic.P1

var player_is_active: bool = true
var current_column: int = 0  # Start in a center column (0-3 for 4 columns)
var cpu_player : CpuPlayer

@onready var player_timer: Timer = get_parent().get_node("PlayerTimer")
@onready var player_manager: PlayerManager = get_parent()

func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	player_manager.player_paused.connect(_on_player_paused)
	player_manager.player_resumed.connect(_on_player_resumed)
	
	# Set up CPU behavior only for CPU players
	if player_type == player_dic.CPU:
		cpu_player = CpuPlayer.new(self)
		add_child(cpu_player)  # Add CPU as child to ensure proper scene tree integration
		print("CPU player initialized and added as child for ", name)


func _on_player_paused() -> void:
	# Pause player animations and logic
	player_is_active = false
	print("Player paused")

func _on_player_resumed() -> void:
	# Resume player animations and logic
	player_is_active = true
	print("Player resumed")


# Handle input for column movement (keyboard and joystick)
func _input(event: InputEvent) -> void:
	if !player_is_active or player_type == player_dic.CPU:
		return	

	# Handle keyboard input
	if event is InputEventKey:
		match event.keycode:
			KEY_LEFT, KEY_A:
				if event.pressed:
					move_left()
			KEY_RIGHT, KEY_D:
				if event.pressed:
					move_right()
			KEY_DOWN, KEY_S:
				if event.pressed:
					gravity_forced.emit()
					#print("Force gravity activated!")
			KEY_SPACE:
				# Call lift_and_drop only on press OR release (not while held)
				if not event.echo:
					lift_and_drop()
	
	# Handle joystick/gamepad input
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				move_left()
			JOY_BUTTON_DPAD_RIGHT:
				move_right()
			JOY_BUTTON_DPAD_DOWN:
				gravity_forced.emit()
				#print("Force gravity activated!")
			JOY_BUTTON_X:  # A button (Xbox) / Cross (PlayStation)
				gravity_forced.emit()
				#print("Force gravity activated!")
			JOY_BUTTON_A:  # Y button (Xbox) / Triangle (PlayStation)
				player_flipped.emit()

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
				player_flipped.emit()
			elif event.axis_value > 0.5:  # Left stick moved down
				gravity_forced.emit()
				#print("Force gravity activated!")

# Move player to the left if possible. 
func move_left():
	if current_column > 0:
		# Create a tween for smooth movement
		var tween = create_tween()
		var start_x = initial_x + (current_column * Globals.BLOCK_SIZE)
		var target_x = start_x - Globals.BLOCK_SIZE
		tween.tween_property(self, "position:x", target_x, 0.1)
		
		# Play the correct animation and emit lift signal if necessary.
		flip_h = true
		current_column -= 1
		if is_lifting:
			play("lift")
			player_flipped.emit()
		else:
			play("move")

func force_gravity():
	gravity_forced.emit()
	
# Move player to the right column if possible.
func move_right():
	var max_column = Globals.NUM_COLUMNS - 1
	if current_column < max_column:
		# Create a tween for smooth movement
		var tween = create_tween()
		var start_x = initial_x + (current_column * Globals.BLOCK_SIZE)
		var target_x = start_x + Globals.BLOCK_SIZE
		tween.tween_property(self, "position:x", target_x, 0.1)
		
		# Play the move_left_front animation
		flip_h = false
		if is_lifting:
			play("lift")
			player_flipped.emit()
		else:
			play("move")
		
		current_column += 1

func flip_right():
	if !is_lifting:
		lift_and_drop()
	move_right()
	lift_and_drop()

func flip_left():
	if !is_lifting:
		lift_and_drop()
	move_left()
	lift_and_drop()

func flip_columns(left_column_index,right_column_index):
	if right_column_index != left_column_index +1:
		print ("CPU : Error, only flipping between adjacent columns")
		return
	
	move_to_column(left_column_index)
	flip_right()

func move_to_column(target_column: int):
	var current_pos = current_column
	
	while current_pos < target_column:
		move_right()
		current_pos = current_column
	
	while current_pos > target_column:
		move_left()
		current_pos = current_column

func lift_and_drop():
	is_lifting = !is_lifting

	if (is_lifting):
		play("idle_lift")
		emit_signal("player_lifted")
	else:
		play("idle")
		emit_signal("player_dropped")

# Get the player's current column position
func get_column() -> int:
	return current_column

func get_shells() -> Array:
	return player_manager.shells_grid.shells_grid

# Handle animation finished events
func _on_animation_finished():
	# If the move_right_front animation just finished, return to previous animation
	if is_lifting:
		play("idle_lift")
	else:
		play("idle")
