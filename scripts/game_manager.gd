class_name GameManager
extends Node2D

# Timer for the main game update loop that runs every second
var update_timer: Timer

const BOTTOM_SHELL = 1
const TOP_SHELL = 2

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
@onready var player : Player = get_node("%Player")  # Adjust path as needed

var score:int = 0  # Initialize score variable

var score_label: Label

func _ready() -> void:
	pass
	# Initialize the game state and set up all necessary components
	will_debug = get_node_or_null("%WillDebug")
	score_label = get_node_or_null("%Score")

	# Set up the game grid and display initial state
	initialize_fireworks_grid()
	update_will_debug()

	# Start the main game timer
	setup_update_timer()

	# Connect player signals to handle movement and status changes
	player.column_changed.connect(_on_player_column_changed)
	player.status_changed.connect(_on_player_status_changed)
	player.force_gravity.connect(_on_force_gravity)

# Handle player column movement events
func _on_player_column_changed(new_column: int):
	# Update tracking variables and refresh display when player moves
	print("Player moved to column ", new_column)
	update_will_debug()
	# Add your logic here (collision detection, scoring, etc.)


# Handle player status change events (FRONT/BACK switching)
func _on_player_status_changed(new_status: Player.flip_status):
	# Update player status and trigger column switching when status changes

	var player_column = player.get_column()
	print("Player status changed to: ", new_status, "column: ", player_column)
	switch_columns(player_column,player_column+1)  # Switch adjacent columns
	update_will_debug()


func _on_force_gravity():
	# Keep applying gravity until no more fireworks can fall
	print("Force gravity activated - processing until all fireworks settle...")
	
	var has_positive_fireworks = true
	var iteration_count = 0
	
	while has_positive_fireworks:
		iteration_count += 1
		print("Force gravity iteration: ", iteration_count)
		
		# Apply gravity once
		gravity_manager()
		
		# Check if there are still positive (falling) fireworks
		has_positive_fireworks = false
		for column in Globals.NUM_COLUMNS:
			for row in Globals.NUM_ROWS:
				if fireworks[column][row] != null and fireworks[column][row] > 0:
					has_positive_fireworks = true
					break
			if has_positive_fireworks:
				break
	
	print("Force gravity completed after ", iteration_count, " iterations")
	nb_loops = 0  # Reset the loop counter
	update_will_debug()


func add_points(increment:int):
	# Increment the score by a specified amount
	score += increment
	print("Score updated: ", score)
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

# Set up the main game update timer
func setup_update_timer():
	# Create and configure a timer that triggers the main game loop every second
	update_timer = Timer.new()
	update_timer.wait_time = 1.0  # 1 second intervals
	update_timer.autostart = true
	update_timer.timeout.connect(update_loop)
	add_child(update_timer)

# Main game loop called every second by the update timer
func update_loop():
	# Execute all game mechanics in order: physics, interactions, spawning, display
	#print("Update loop called at: ", Time.get_time_string_from_system())
	gravity_manager()  # Apply gravity to make fireworks fall
	if nb_loops % Globals.NUM_ROWS == 0:  # Add fireworks every 5 loops (every 5 seconds)
		add_new_fireworks()
	nb_loops %= Globals.NUM_ROWS  # Reset loop counter to avoid overflow
	update_will_debug()  # Refresh the visual display

	nb_loops += 1  # Increment loop counter

# Update the debug display with current game state
func update_will_debug():
	# Create a visual representation of the fireworks grid and player position
	if will_debug != null:
		var display_text = "Fireworks Grid:\n"
		
		# Display the grid row by row from top to bottom (reversed for visual clarity)
		for row in range(Globals.NUM_ROWS - 1, -1, -1):
			var row_text = str(row)+ ": "
			for column in Globals.NUM_COLUMNS:
				var cell_content = fireworks[column][row]
				# Format different cell types with unique symbols
				if cell_content == null:
					row_text += "    "  # Empty cell
				elif abs(cell_content) == BOTTOM_SHELL:
					row_text +="[color=green]\\_/[/color] "  # Special firework type 1
				elif abs(cell_content) == TOP_SHELL:
					row_text +="[color=green]/*\\[/color] "  # Special firework type 9
				elif cell_content < 0:
					row_text += "[" + str(-int(cell_content)) + "] "  # Stuck firework (negative)
				else:
					row_text += " " + str(cell_content) + "  "  # Normal firework
			display_text += row_text + "\n"
			if row == Globals.NUM_ROWS - 1:
				display_text += "------------------\n"  # Separator line

		# Display the current player position and status below the grid
		var current_player_column = player.get_column()
		var current_player_status = player.get_status()
		display_text += "   "
		for i in current_player_column:
			display_text += "    "  # Spacing to align with player column
		display_text+= "<< "
		display_text += "F" if current_player_status == Player.flip_status.FRONT else "B"  # F or B status
		display_text+= " >>\n"

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
	
	# Create random fireworks (values 1-4) in the selected columns
	for column in selected_columns:
		var random_value = randi() % 9 + 1  # Random integer from 1 to 4
		fireworks[column][last_row_index] = int(random_value)
	
	print("Fireworks added to columns: ", selected_columns)

# Apply gravity physics to make fireworks fall down
func gravity_manager():
	# Process each column and row to simulate falling fireworks
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			#print ("Checking fireworks[", column, "][", row, "] = ", fireworks[column][row])
			# Only process cells with positive firework values (active fireworks)
			if fireworks[column][row] != null and fireworks[column][row] > 0:
				# Check if firework can fall down (cell below is empty and within bounds)
				if row > 0 and fireworks[column][row - 1] == null:
					# Move the firework down one row
					#print ("Moving firework from [", column, "][", row, "] to [", column, "][", row - 1, "]")
					fireworks[column][row - 1] = fireworks[column][row]
					fireworks[column][row] = null
				else:
					# Firework is stuck (blocked by another firework or at bottom)
					stack_firework(column,row)


func stack_firework(column: int, row: int):
	# first case: we drop on the same kind of FW, so we pop. 
	if fireworks[column][row-1] != null and abs(fireworks[column][row-1]) == fireworks[column][row]:
		print("Popping firework at [", column, "][", row, "]")
		fireworks[column][row] = null  # Remove the current firework
		fireworks[column][row-1] = null  # Remove the matching firework below
		add_points(POP_SCORE)  # Add points for popping fireworks
		return
	if fireworks[column][row] == TOP_SHELL:
		# we check if there's a BOTTOM_SHELL below to pop the whole column
		for row_check in range(row - 1, -1, -1):
			# If we find a BOTTOM_SHELL, we pop the firework.
			if abs(fireworks[column][row_check]) == BOTTOM_SHELL:
				for r in range(row, row_check - 1, -1):
					fireworks[column][r] = null  
				print ("TOP ROW popped at ",row)
				print ("BOTTOM_SHELL popped at ",row_check)
				add_points(FIREWORK_SCORE[row-row_check-1])
				return  # Exit after popping the whole column
			# If we find a TOP_SHELL, we pop the firework.
			if abs(fireworks[column][row_check]) == TOP_SHELL:
				for r in range(row, row_check - 1, -1):
					fireworks[column][r] = null  # Clear the entire column
				return  # Exit after popping the whole column

		# if not found, we just pop the TOP_SHELL alone.
		print("Popping TOP_SHELL firework at [", column, "][", row, "]")
		fireworks[column][row] = null  # Remove the TOP_SHELL firework
		return  # Already stuck, do nothing
	# If the firework is not already stuck, mark it as stuck
	print("Sticking firework at [", column, "][", row, "]")
	fireworks[column][row] = -fireworks[column][row]  # Mark as stuck by negating the value
	if row == Globals.NUM_ROWS - 1:
		game_over()
	return

func game_over():
	# Handle game over logic (e.g., display message, reset game state)
	print("Game Over! Final Score: ", score)
	#stop the update_loop
	update_timer.stop()
	will_debug.add_theme_color_override("font_color", Color(1, 0, 0))  # Set text color to red

	# You can add more logic here to reset the game or show a game over screen



# Switch fireworks between two adjacent columns (used when player changes status)
func switch_columns(left_column: int, right_column: int):
	# Swap stuck fireworks (negative values) between the specified columns
	for row in range(Globals.NUM_ROWS - 1):
		# Only switch if at least one column has a stuck firework (negative value)
		if (fireworks[left_column][row] != null && fireworks[left_column][row] < 0) or (fireworks[right_column][row] != null && fireworks[right_column][row] < 0):
			print("Switching fireworks between columns ", left_column, " and ", right_column, " at row ", row)
			# Swap the fireworks between the two columns
			var temp = fireworks[left_column][row]
			fireworks[left_column][row] = fireworks[right_column][row]
			fireworks[right_column][row] = temp
