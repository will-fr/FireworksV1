class_name Player  extends AnimatedSprite2D

var initial_x:float = 0


signal player_flipped(new_status: flip_status)
signal column_changed(new_column: int)
signal gravity_forced


# Player status enum
enum player_dic { P1, P2, CPU }
@export var player_type: player_dic = player_dic.P1

# CPU difficulty levels
enum cpu_difficulty { EASY, MEDIUM, HARD }
@export var cpu_difficulty_level: cpu_difficulty = cpu_difficulty.MEDIUM


enum flip_status { FRONT, BACK }
var player_status: flip_status = flip_status.FRONT  # Start in FRONT status
var player_is_active: bool = true
var current_column: int = 0  # Start in a center column (0-3 for 4 columns)
var cpu_player : CpuPlayer

@onready var player_timer: Timer = get_parent().get_node("PlayerTimer")
@onready var player_manager: PlayerManager = get_parent()

func _init() -> void:
	#initial_x = position.x
	initial_x = 8
	# Connect to animation finished signal to handle animation transitions
	pass

	
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

func _process(_delta: float) -> void:
	if player_type == player_dic.CPU:
		modulate = Color(1, 0.5, 0.5)  # Change color to indicate CPU player
	

# Handle input for column movement (keyboard and joystick)
func _input(event: InputEvent) -> void:
	if !player_is_active or player_type == player_dic.CPU:
		return	

	# Handle keyboard input
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT, KEY_A:
				move_left()
			KEY_RIGHT, KEY_D:
				move_right()
			KEY_UP, KEY_W:
				flip()
			KEY_DOWN, KEY_S:
				gravity_forced.emit()
				#print("Force gravity activated!")
	
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
				flip()
	
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
				flip()
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
		#print ("move from ", start_x, " to ", target_x)

		
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

		# Animate position over 0.25 seconds
		tween.tween_property(self, "position:x", target_x, 0.1)
		
		# Play the move_right_front animation
		if player_status == flip_status.FRONT:
			play("move_right_front")
		else:
			play("move_right_back")
		current_column += 1
		emit_signal("column_changed", current_column)


func flip():
	if player_status == flip_status.FRONT:
		player_status = flip_status.BACK
		player_flipped.emit(player_status)
		play("flip_f2b")
		#print("Player status switched to BACK")
	else:
		player_status = flip_status.FRONT
		player_flipped.emit(player_status)
		play("flip_b2f")
		#print("Player status switched to FRONT")


# Get the player's current column position
func get_column() -> int:
	return current_column

# Get the player's current status (FRONT or BACK)
func get_status() -> flip_status:
	return player_status

func get_shells() -> Array:
	return player_manager.shells_grid

# Handle animation finished events
func _on_animation_finished():
	# If the move_right_front animation just finished, return to previous animation
	if player_status == flip_status.FRONT:
		play("front")
	else:
		play("back")
