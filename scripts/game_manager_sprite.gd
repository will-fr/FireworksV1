class_name GameManagerSprite
extends Node2D




const POP_SCORE = 10  # Points awarded for popping fireworks
const FIREWORK_SCORE = [11, 222, 3333, 4444, 5555,66666,77777,8888888,9999999]  # Points for fireworks of different sizes

# Counter to track how many update loops have occurred
var nb_loops: int = 0  # Counter for update loops

# 2D array storing firework values: fireworks[column][row]
# null = empty cell, positive = active firework, negative = stuck firework
var fireworks: Array = []

# UI References for debugging display
var will_debug: RichTextLabel

# Reference to the player node for signal connections and position tracking
@onready var player : Player = get_node("Player")  # Adjust path as needed
@onready var game_timer: Timer = get_node("GameTimer")  # Timer for game updates

var score:int = 0  # Initialize score variable
var score_label: Label

func _ready() -> void:
	# Initialize the game state and set up all necessary components
	will_debug = get_node_or_null("WillDebug")
	score_label = get_node_or_null("Score")

	# Set up the game grid and display initial state
	initialize_fireworks_grid()
	update_will_debug()

	# Connect player signals to handle movement and status changes
	player.column_changed.connect(_on_player_column_changed)
	player.status_changed.connect(_on_player_status_changed)
	player.force_gravity.connect(_on_force_gravity)

# Handle player column movement events
func _on_player_column_changed(new_column: int):
	update_will_debug()

# Handle player status change events (FRONT/BACK switching)
func _on_player_status_changed(new_status: Player.flip_status):
	var player_column = player.get_column()
	switch_columns(player_column,player_column+1)  # Switch adjacent columns
	update_will_debug()

# Keep applying gravity until no more shells
func _on_force_gravity():
	var has_falling_shells = true

	while has_falling_shells:
		gravity_manager()
		# Check if there are still falling shells
		has_falling_shells = false
		for column in Globals.NUM_COLUMNS:
			for row in Globals.NUM_ROWS:
				if fireworks[column][row] != null and fireworks[column][row].get_status() == Shell.status.FALLING:
					has_falling_shells = true
					break
			if has_falling_shells:
				break

	nb_loops=0
	update_will_debug()

# Main game loop called every second by the update timer
func _on_game_timer_timeout() -> void:
	# Execute all game mechanics in order: physics, interactions, spawning, display
	#print("Update loop called at: ", Time.get_time_string_from_system())
	gravity_manager()  # Apply gravity to make fireworks fall
	if count_waiting_shells() == 0:
		add_new_fireworks()
	if count_falling_shells() ==0:
		drop_waiting_shells()
	#nb_loops %= Globals.NUM_ROWS  # Reset loop counter to avoid overflow
	update_will_debug()  # Refresh the visual display
	#print ("LOOP #", nb_loops)
	#nb_loops += 1  # Increment loop counter

func count_waiting_shells() -> int:
	var waiting_shells = 0
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if fireworks[column][row] != null and fireworks[column][row].get_status() == Shell.status.WAITING:
				waiting_shells += 1
	return waiting_shells

func count_falling_shells() -> int:
	var falling_shells = 0
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if fireworks[column][row] != null and fireworks[column][row].get_status() == Shell.status.FALLING:
				falling_shells += 1
	return falling_shells

func drop_waiting_shells() -> void:
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if fireworks[column][row] != null and fireworks[column][row].get_status() == Shell.status.WAITING:
				fireworks[column][row].set_status(Shell.status.FALLING)

func add_points(increment:int):
	# Increment the score by a specified amount
	score += increment
	if score_label:
		score_label.text = "Score: " + str(score)  # Update the score label in the UI

# Initialize the 2D fireworks grid with empty cells
func initialize_fireworks_grid():
	# Create a 2D array: fireworks[column][row] filled with null values
	fireworks.clear()
	for column in Globals.NUM_COLUMNS:
		var column_array = []
		for row in Globals.NUM_ROWS:
			column_array.append(null)  # Initialize with null/empty cells
		fireworks.append(column_array)
	print("Fireworks grid initialized: ", Globals.NUM_COLUMNS, " columns x ", Globals.NUM_ROWS, " rows")




# Update the debug display with current game state
func update_will_debug():
	# Create a visual representation of the fireworks grid and player position
	if will_debug != null:
		var display_text = "Fireworks Grid:\n"
		
		# Display the grid row by row from top to bottom (reversed for visual clarity)
		for row in range(Globals.NUM_ROWS - 1, -1, -1):
			var row_text = str(row)+ ":"
			for column in Globals.NUM_COLUMNS:
				var shell = fireworks[column][row]
				# Format different cell types with unique symbols
				if shell == null:
					row_text += "   "  # Empty cell
				elif shell.get_shell_type() == Globals.BOTTOM_SHELL:
					row_text +="[color=green]\\_/[/color]"  # Special firework type 1
				elif shell.get_shell_type() == Globals.TOP_SHELL:
					row_text +="[color=green]/*\\[/color]"  # Special firework type 9
				elif shell.get_status() == Shell.status.DROPPED:
					row_text += "[" + str(shell.get_shell_type()) + "]"  # Stuck firework (negative)
				else:
					row_text += " " + str(shell.get_shell_type()) + " "  # Normal firework
			display_text += row_text + "\n"
			if row == Globals.NUM_ROWS - 1:
				display_text += "-------------\n"  # Separator line

		# Display the current player position and status below the grid
		var current_player_column = player.get_column()
		var current_player_status = player.get_status()
		display_text += "  "
		for i in current_player_column:
			display_text += "   "  # Spacing to align with player column
		display_text+= "<-"
		display_text += "Fr" if current_player_status == Player.flip_status.FRONT else "Ba"  # F or B status
		display_text+= "->\n"

		will_debug.text = display_text

# Spawn new fireworks at random columns every 5 seconds
func add_new_fireworks():
	# Add random fireworks to the top row of 2 randomly selected columns
	var last_row_index = Globals.NUM_ROWS - 1  # Last row (bottom of the grid)
	
	# Select 2 unique random columns to spawn fireworks
	var selected_columns = []
	while selected_columns.size() < 2:
		var random_column = randi() % Globals.NUM_COLUMNS
		if not selected_columns.has(random_column):
			selected_columns.append(random_column)
	
	# Create random fireworks (values 1-5) in the selected columns
	var load_scene_one = load("res://scenes/shell.tscn")
	for column in selected_columns:
		var new_instance = load_scene_one.instantiate()
		add_child(new_instance) 
		var shell_type = randi() % 5 + 1  
		new_instance.initialize(column, shell_type)
		fireworks[column][last_row_index] = new_instance
		

	
# Apply gravity physics to make fireworks fall down
func gravity_manager():
	# Process each column and row to simulate falling fireworks
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			# We process the "falling fireworks".
			if fireworks[column][row] != null and fireworks[column][row].get_status() == Shell.status.FALLING:
				if row > 0 and fireworks[column][row - 1] == null:
					fireworks[column][row].position.y += Globals.BLOCK_SIZE
					fireworks[column][row - 1] = fireworks[column][row]
					fireworks[column][row] = null
				else:
					# Firework is stuck (blocked by another firework or at bottom)
					stack_firework(column,row)

func stack_firework(column: int, row: int):
	# first case: we drop on the same kind of FW, so we pop. 
	if fireworks[column][row-1] != null and fireworks[column][row-1].get_shell_type() == fireworks[column][row].get_shell_type():
		print("Popping firework at [", column, "][", row, "]")
		create_firework(fireworks[column][row].position.x+Globals.BLOCK_SIZE/2, fireworks[column][row-1].position.y, fireworks[column][row].get_shell_type())
		remove_shell(column,row)  # Remove the current firework
		remove_shell(column,row-1)  # Remove the matching firework below
		add_points(POP_SCORE)  # Add points for popping fireworks
		
		return
	if fireworks[column][row].get_shell_type() == Globals.TOP_SHELL:
		# we check if there's a BOTTOM_SHELL below to pop the whole column
		for row_check in range(row - 1, -1, -1):
			# If we find a BOTTOM_SHELL, we pop the firework.
			if fireworks[column][row_check].get_shell_type() == Globals.BOTTOM_SHELL:
				for r in range(row, row_check - 1, -1):
					remove_shell(column,r)
				add_points(FIREWORK_SCORE[row-row_check-1])
				return  # Exit after popping the whole column
			# If we find a TOP_SHELL, we pop the firework (shouldn't occur)
			# if fireworks[column][row_check].get_shell_type() == TOP_SHELL:
			# 	for r in range(row, row_check - 1, -1):
			# 		fireworks[column][r] = null  # Clear the entire column
			# 	return  # Exit after popping the whole column

		# if not found, we just pop the TOP_SHELL alone.
		remove_shell(column,row)
		return  
	# If the firework is not already stuck, mark it as stuck
	fireworks[column][row].set_status(Shell.status.DROPPED)  # Mark as stuck
	if row == Globals.NUM_ROWS - 1:
		game_over()
	return

func create_firework(x_arg,y_arg,shell_type_arg):
	print ("Creating firework at [", x_arg, "][", y_arg, "]")
	var load_scene_one = load("res://scenes/small_firework.tscn")
	var new_instance = load_scene_one.instantiate()
	new_instance.position = Vector2(x_arg, y_arg)  # Set initial position
	add_child(new_instance) 
	new_instance.initialize(shell_type_arg)

func remove_shell(column,row):
	if fireworks[column][row] != null:
		fireworks[column][row].queue_free()  # Remove the firework from the scene
		fireworks[column][row] = null  # Clear the reference

func game_over():
	# Handle game over logic (e.g., display message, reset game state)
	print("Game Over! Final Score: ", score)
	
	# Stop the game timer
	game_timer.stop()
	
	# Set debug text color to red
	will_debug.add_theme_color_override("font_color", Color(1, 0, 0))  # Set text color to red
	
func switch_columns(left_column: int, right_column: int):
	# Swap stuck fireworks (negative values) between the specified columns
	for row in range(Globals.NUM_ROWS - 1):
		# Only switch if at least one column has a stuck firework (negative value)
		if (fireworks[left_column][row] != null && fireworks[left_column][row].get_status() == Shell.status.DROPPED) or (fireworks[right_column][row] != null && fireworks[right_column][row].get_status() == Shell.status.DROPPED):
			print("Switching fireworks between columns ", left_column, " and ", right_column, " at row ", row)
			# Swap the fireworks between the two columns
			var temp = fireworks[left_column][row]
			fireworks[left_column][row] = fireworks[right_column][row]
			if fireworks[left_column][row] != null:
				fireworks[left_column][row].position.x -= Globals.BLOCK_SIZE

			fireworks[right_column][row] = temp
			if fireworks[right_column][row] != null:
				fireworks[right_column][row].position.x += Globals.BLOCK_SIZE
