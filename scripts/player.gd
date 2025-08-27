class_name Player
extends AnimatedSprite2D

var initial_x:float = 0


signal flip(new_status: flip_status)
signal column_changed(new_column: int)
signal force_gravity


# Player status enum
enum player_dic { P1, P2, CPU }
@export var player_type: player_dic = player_dic.P1

# CPU difficulty levels
enum cpu_difficulty { EASY, MEDIUM, HARD }
@export var cpu_difficulty_level: cpu_difficulty = cpu_difficulty.MEDIUM


enum flip_status { FRONT, BACK }
var player_status: flip_status = flip_status.FRONT  # Start in FRONT status
var is_playing: bool = true
var current_column: int = 0  # Start in a center column (0-3 for 4 columns)


@onready var game_timer: Timer = get_parent().get_node("GameTimer")
@onready var game_manager: GameManagerSprite = get_parent()

func _init() -> void:
	initial_x = position.x
	# Connect to animation finished signal to handle animation transitions
	
func _ready() -> void:
	animation_finished.connect(_on_animation_finished)
	game_manager.player_paused.connect(_on_player_paused)
	game_manager.player_resumed.connect(_on_player_resumed)
	
	# Set up CPU player timer if this is a CPU player
	if player_type == player_dic.CPU:
		_setup_cpu_timer()

# Set up the CPU player timer for intelligent moves
func _setup_cpu_timer():
	var cpu_timer = Timer.new()
	add_child(cpu_timer)
	cpu_timer.wait_time = 0.2  # CPU makes a move every 0.2 seconds
	cpu_timer.timeout.connect(_cpu_make_move)
	cpu_timer.start()

# CPU makes a move based on difficulty level
func _cpu_make_move():
	if not is_playing:
		return
	
	match cpu_difficulty_level:
		cpu_difficulty.EASY:
			# 70% random, 30% strategic
			if randf() < 0.7:
				_cpu_make_random_move()
			else:
				_cpu_make_basic_move()
		
		cpu_difficulty.MEDIUM:
			# 40% random, 60% strategic
			if randf() < 0.4:
				_cpu_make_random_move()
			else:
				_cpu_make_strategic_move()
		
		cpu_difficulty.HARD:
			# Always strategic with advanced planning
			_cpu_make_strategic_move()

# CPU makes a completely random move
func _cpu_make_random_move():
	var random_action = randi() % 4
	match random_action:
		0:
			move_left()
		1:
			move_right()
		2:
			flip_switch_status()
		3:
			force_gravity.emit()

# CPU makes basic strategic decisions
func _cpu_make_basic_move():
	# Basic strategy: avoid dangerous columns
	var current_shells = _count_shells_in_current_column()
	
	# If current column is getting full, try to move
	if current_shells >= Globals.NUM_ROWS - 2:
		if current_column > 0:
			move_left()
		elif current_column < Globals.NUM_COLUMNS - 1:
			move_right()
		else:
			force_gravity.emit()  # Force gravity if no safe move
	else:
		# Safe position, random move
		_cpu_make_random_move()

# CPU makes strategic decisions with planning
func _cpu_make_strategic_move():
	# Check for immediate threats
	if _is_in_immediate_danger():
		_escape_danger()
		return
	
	# Move to optimal position
	var best_column = _find_safest_column()
	if best_column != current_column:
		if best_column < current_column:
			move_left()
		else:
			move_right()
	else:
		# Consider flipping or forcing gravity
		if randf() < 0.3:  # 30% chance to flip
			flip_switch_status()
		else:
			force_gravity.emit()

# Helper functions for AI decision making
func _count_shells_in_current_column() -> int:
	# Simplified shell counting (you may need to adjust based on your game manager)
	return 0  # Placeholder - implement based on your game_manager structure

func _is_in_immediate_danger() -> bool:
	var shells_count = _count_shells_in_current_column()
	return shells_count >= Globals.NUM_ROWS - 1

func _escape_danger():
	var can_move_left = current_column > 0
	var can_move_right = current_column < Globals.NUM_COLUMNS - 1
	
	if can_move_left and can_move_right:
		if randf() < 0.5:
			move_left()
		else:
			move_right()
	elif can_move_left:
		move_left()
	elif can_move_right:
		move_right()
	else:
		force_gravity.emit()

func _find_safest_column() -> int:
	# Simple implementation: return current column or adjacent ones
	# You can enhance this by checking actual shell counts
	var safe_columns = []
	for col in range(max(0, current_column - 1), min(Globals.NUM_COLUMNS, current_column + 2)):
		safe_columns.append(col)
	
	if safe_columns.size() > 0:
		return safe_columns[randi() % safe_columns.size()]
	return current_column


func _on_player_paused() -> void:
	# Pause player animations and logic
	is_playing = false
	print("Player paused")

func _on_player_resumed() -> void:
	# Resume player animations and logic
	is_playing = true
	print("Player resumed")


func _process(_delta: float) -> void:
	if player_type == player_dic.CPU:
		modulate = Color(1, 0.5, 0.5)  # Change color to indicate CPU player
	


# Handle input for column movement (keyboard and joystick)
func _input(event: InputEvent) -> void:
	if !is_playing or player_type == player_dic.CPU:
		return	

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
				#print("Force gravity activated!")
	
	# Handle joystick/gamepad input
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT:
				move_left()
			JOY_BUTTON_DPAD_RIGHT:
				move_right()
			JOY_BUTTON_DPAD_DOWN:
				force_gravity.emit()
				#print("Force gravity activated!")
			JOY_BUTTON_X:  # A button (Xbox) / Cross (PlayStation)
				force_gravity.emit()
				#print("Force gravity activated!")
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
				#print("Force gravity activated!")

# Move player to the left column
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
		#print ("move from ", start_x, " to ", target_x)

		
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
		flip.emit(player_status)
		play("flip_f2b")
		#print("Player status switched to BACK")
	else:
		player_status = flip_status.FRONT
		flip.emit(player_status)
		play("flip_b2f")
		#print("Player status switched to FRONT")


# Get the player's current column position
func get_column() -> int:
	return current_column

# Get the player's current status (FRONT or BACK)
func get_status() -> flip_status:
	return player_status


# Handle animation finished events
func _on_animation_finished():
	# If the move_right_front animation just finished, return to previous animation
	if player_status == flip_status.FRONT:
		play("front")
	else:
		play("back")
