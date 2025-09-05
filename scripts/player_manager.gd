class_name PlayerManager extends Node2D


var shells_grid: Array = [] # 2D array storing shell values: shells_grid[column][row]
var score:int = 0  # Initialize score variable
var even_loop = true
var nb_shells_per_batch:int = 2
var player_active: bool = false
var nb_junk:int = 0  # Amount of junk collected (due to other players' fireworks)

var nb_loops:int = 0

# signal
signal player_paused
signal player_resumed
signal player_game_over
signal points_added

# Reference to the player node for signal connections and position tracking
@onready var player : Player = get_node("Player")  # Adjust path as needed
@onready var player_timer: Timer = get_node("PlayerTimer")  # Timer for game updates
@onready var score_label: Label = get_node("Score")  # Adjust path as needed
@onready var junk_label: Label = get_node("Junk")  # Adjust path as needed
@onready var countdown: CountDown = get_node("CountDown")  # Adjust path as needed

func _ready() -> void:
	initialize_shells_grid()
	player.player_flipped.connect(_on_player_flip)
	player.gravity_forced.connect(_on_force_gravity)
	countdown.connect("countdown_finished", Callable(self, "_on_countdown_finished"))


	set_player_play()
	main_game_loop()
	set_player_pause()

func _on_countdown_finished():
	print("PlayerManager: Countdown finished, starting game.")
	set_player_play()

# Handle player status change events (FRONT/BACK switching)
func _on_player_flip(_new_status: Player.flip_status):
	var player_column = player.get_column()
	switch_columns(player_column,player_column+1)  # Switch adjacent columns

# When the player forces gravity (by pushing "down")
func _on_force_gravity():
	main_game_loop()

# Main game loop called every second by the update timer
func _on_player_timer_timeout() -> void:
	main_game_loop()

func set_player_pause():
	player_active = false
	player_timer.stop()
	emit_signal("player_paused")
	# Pause game logic here

func set_player_play():
	player_active = true
	player_timer.start()
	emit_signal("player_resumed")
	# Resume game logic here

func main_game_loop():
	# Execute all game mechanics in order: physics, interactions, spawning, display
	print("loop # ", nb_loops)
	if player_timer.is_stopped():
		print ("Timer stopped, return")
		return 
	if even_loop:
		print ("even loop")
		print ("count waiting shells: ", count_waiting_shells())
		if count_waiting_shells() == 0:
			print ("adding new shells")
			add_new_shells()
		move_falling_sprites()
	else:
		if count_falling_shells() ==0:
			drop_waiting_shells()
		gravity_manager() 	
		move_falling_sprites()	

	nb_loops += 1
	even_loop = !even_loop

# Initialize the 2D shells grid with empty cells
func initialize_shells_grid():
	shells_grid.clear()
	for column in Globals.NUM_COLUMNS:
		var column_array = []
		for row in Globals.NUM_ROWS:
			column_array.append(null)  # Initialize with null/empty cells
		shells_grid.append(column_array)

	initialize_bottom_row()


func initialize_bottom_row():
	# Fill the bottom row with shells, including exactly one BOTTOM_SHELL
	var load_scene_one = load("res://scenes/shell.tscn")
	var bottom_row_index = 0  # Bottom row is index 0
	
	# Choose a random column for the BOTTOM_SHELL
	var bottom_shell_column = randi() % Globals.NUM_COLUMNS
	# Fill each column in the bottom row
	for column in Globals.NUM_COLUMNS:
		var new_instance = load_scene_one.instantiate()
		add_child(new_instance)
		
		var shell_type: int
		if column == bottom_shell_column:
			shell_type = Globals.BOTTOM_SHELL  # Place the BOTTOM_SHELL
			print("PlayerManager: Placing BOTTOM_SHELL in column ", column)
		else:
			# Fill with random colored shells (GREEN=3, RED=4, BLUE=5, YELLOW=6)
			shell_type = randi() % Globals.TYPES_OF_BLOCK + Globals.GREEN
		
		new_instance.initialize(column, shell_type)
		new_instance.set_status(Shell.status.DROPPED)  # Set as dropped (stable)
		shells_grid[column][bottom_row_index] = new_instance
		shells_grid[column][bottom_row_index].position.y = Globals.NUM_ROWS * Globals.BLOCK_SIZE  # Position at bottom row
	
	print("PlayerManager: Bottom row initialized with BOTTOM_SHELL in column ", bottom_shell_column) 


func count_waiting_shells() -> int:
	var waiting_shells = 0
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.WAITING:
				waiting_shells += 1
	print ("nb of waiting shells : ", waiting_shells)
	return waiting_shells

func count_falling_shells() -> int:
	var falling_shells = 0
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.FALLING:
				falling_shells += 1
	return falling_shells

func drop_waiting_shells() -> void:
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.WAITING:
				shells_grid[column][row].set_status(Shell.status.FALLING)

# this function returns a list of all falling shells
func get_falling_shells() -> Array:
	var falling_shells = []
	# Initialize array with proper size
	for column in Globals.NUM_COLUMNS:
		falling_shells.append(null)
	
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.FALLING:
				falling_shells[column] = shells_grid[column][row]
				break  # Only get the first (topmost) falling shell per column
	return falling_shells

# this function returns a list of all waiting shells
func get_waiting_shells() -> Array:
	var waiting_shells = []
	# Initialize array with proper size
	for column in Globals.NUM_COLUMNS:
		waiting_shells.append(null)

	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.WAITING:
				waiting_shells[column] = shells_grid[column][row]
				break  # Only get the first (topmost) waiting shell per column
	return waiting_shells


func get_top_dropped_shells() -> Array:
	var top_dropped_shells = []
	# Initialize array with proper size
	for column in Globals.NUM_COLUMNS:
		top_dropped_shells.append(null)
		
	for column in Globals.NUM_COLUMNS:
		# Find the topmost dropped shell in each column (highest row index)
		for row in range(Globals.NUM_ROWS - 1, -1, -1):  # Start from top
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.DROPPED:
				top_dropped_shells[column] = shells_grid[column][row]
				break  # Only get the topmost dropped shell per column
	return top_dropped_shells


func add_points(increment:int,pos_x:float=100.0,pos_y:float=100.0):
	# Increment the score by a specified amount
	score += increment
	if score_label:
		score_label.text = "%05d" % score  # Format score as 5-digit string with leading zeros

	var points_scene = load("res://scenes/points.tscn")
	var new_instance = points_scene.instantiate()
	add_child(new_instance)
	new_instance.initialize(increment, pos_x, pos_y)

	# Emit the points_added signal with the new points
	points_added.emit(increment,pos_x,pos_y)


# Spawn new shells at random columns every x seconds
func add_new_shells():
	# Add random shells to the top row of selected columns. 
	var last_row_index = Globals.NUM_ROWS - 1  # Last row (top of the grid)

	# we identify how many pieces will be added
	var nb_additional_shells_in_this_batch : int = min (nb_junk , Globals.NUM_COLUMNS - nb_shells_per_batch) 
	decrease_junk(nb_additional_shells_in_this_batch)
	var nb_shells_in_this_batch = nb_shells_per_batch + nb_additional_shells_in_this_batch
	print("adding "+str(nb_shells_in_this_batch)+" shells in this batch")
	# Select 2 unique random columns to spawn shells
	var selected_columns = []
	while selected_columns.size() < nb_shells_in_this_batch:

		var random_column = randi() % Globals.NUM_COLUMNS
		if not selected_columns.has(random_column):
			selected_columns.append(random_column)
	
	# Create random shells in the selected columns
	var load_scene_one = load("res://scenes/shell.tscn")
	for column in selected_columns:
		var new_instance = load_scene_one.instantiate()
		add_child(new_instance) 
		var shell_type = randi() % (Globals.TYPES_OF_BLOCK + 2) + 1  
		new_instance.initialize(column, shell_type)
		shells_grid[column][last_row_index] = new_instance


func move_falling_sprites():
	# Move all falling sprites down by half a block
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.FALLING:
				shells_grid[column][row].position.y += float(Globals.BLOCK_SIZE) / 2

# Apply gravity physics to make fireworks fall down
func gravity_manager():
	# Process each column and row to simulate falling fireworks
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			# We process the "falling fireworks".
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.FALLING:
				if row > 0 and shells_grid[column][row - 1] == null:
					shells_grid[column][row - 1] = shells_grid[column][row]
					shells_grid[column][row] = null
				else:
					# Firework is stuck (blocked by another firework or at bottom)
					drop_shell(column,row)

func drop_shell(column: int, row: int):
	print ("DROPPING SHELL AT POSITION [", column, "][", row, "]")
	# IF I STACK ON THE SAME SHELL THAN ME, I POP.  
	if row > 0 and shells_grid[column][row-1] != null and shells_grid[column][row-1].get_shell_type() == shells_grid[column][row].get_shell_type():
		var pos_x :float = float(shells_grid[column][row].position.x) + float(Globals.BLOCK_SIZE) / 2.0
		var pos_y :int = int(shells_grid[column][row-1].position.y)
		create_small_firework(pos_x, pos_y, shells_grid[column][row].get_shell_type())
		remove_shell(column,row)  # Remove the current firework
		remove_shell(column,row-1)  # Remove the matching firework below
		add_points(Globals.POP_SCORE, pos_x,pos_y )  # Add points for popping fireworks	
		return
	# IF I'M A TOP SHELL, I LOOK FOR A BOTTOM SHELL, OTHERWISE I POP ALONE.
	if shells_grid[column][row].get_shell_type() == Globals.TOP_SHELL:
		# we check if there's a BOTTOM_SHELL below to pop the whole column
		for row_check in range(row - 1, -1, -1):
			# If we find a BOTTOM_SHELL, we pop the big firework.
			if shells_grid[column][row_check].get_shell_type() == Globals.BOTTOM_SHELL:
				create_big_firework(column,row,row_check)
				return  # Exit after popping the whole column
		# if not found, we just pop the TOP_SHELL alone.
		print ("  -- POPPING TOP SHELL ALONE AT [", column, "][", row, "]")
		create_small_firework(shells_grid[column][row].position.x + float(Globals.BLOCK_SIZE) / 2.0, shells_grid[column][row].position.y + float(Globals.BLOCK_SIZE) / 2.0, Globals.TOP_SHELL)
		remove_shell(column,row)
		return  
	# DEFAULT CASE: If the shell is not already dropped, mark it as dropped.
	shells_grid[column][row].set_status(Shell.status.DROPPED)  # Mark as stuck
	if row == Globals.NUM_ROWS - 1:
		game_over(column,row)
	return

func create_small_firework(x_arg,y_arg,shell_type_arg):
	print ("  -- Creating firework at [", x_arg, "][", y_arg, "]")
	var load_scene_one = load("res://scenes/small_firework.tscn")
	var new_instance = load_scene_one.instantiate()
	new_instance.position = Vector2(x_arg, y_arg)  # Set initial position
	add_child(new_instance) 
	new_instance.initialize(shell_type_arg)

func create_big_firework(column,top_row,bottom_row):
	# we create a dedicated array with the shells corresponding the fireworks. 
	var firework_shells = []
	for row in range(top_row, bottom_row - 1, -1):
		firework_shells.append(shells_grid[column][row])
		shells_grid[column][row] = null

	var new_big_firework = BigFirework.new(firework_shells)
	new_big_firework.connect("points_to_add", Callable(self, "add_points"))

	add_child(new_big_firework)

func remove_shell(column,row):
	if shells_grid[column][row] != null:
		shells_grid[column][row].queue_free()  # Remove the shell from the scene
		shells_grid[column][row] = null  # Clear the reference

func switch_columns(left_column: int, right_column: int):
	# Swap stuck fireworks (negative values) between the specified columns
	for row in range(Globals.NUM_ROWS - 1):
		# Only switch if at least one column has a stuck firework (negative value)
		if is_shell_dropped(left_column,row) or is_shell_dropped(right_column,row):
			switch_cells(left_column,right_column,row)
			
func is_shell_dropped(column: int,row: int) -> bool:
	if shells_grid[column][row] == null:
		return false
	if shells_grid[column][row].get_status() == Shell.status.DROPPED:
		return true
	return false

func switch_cells(left_column: int, right_column: int, row: int):
	print("Switching shells between columns ", left_column, " and ", right_column, " at row ", row)
	
	# i move the left one to the right
	if shells_grid[left_column][row] != null:
		var initial_x = Globals.LEFT_OFFSET + left_column * Globals.BLOCK_SIZE
		var tween = create_tween()
		tween.tween_property(shells_grid[left_column][row], "position:x", initial_x + Globals.BLOCK_SIZE, 0.1)

	# i move the right block to the left.
	if shells_grid[right_column][row] != null:
		var initial_x = Globals.LEFT_OFFSET + right_column * Globals.BLOCK_SIZE
		var tween = create_tween()
		tween.tween_property(shells_grid[right_column][row], "position:x", initial_x - Globals.BLOCK_SIZE, 0.1)
	
	# i save my left shell in a temp_shell
	var temp_shell = shells_grid[left_column][row]
	shells_grid[left_column][row] = shells_grid[right_column][row]	
	shells_grid[right_column][row] = temp_shell

func game_over(column_arg,row_arg):
	print("Game Over! Final Score: ", score)
	set_player_pause()
	shells_grid[column_arg][row_arg].modulate = Color.GRAY # Tint the last shell gray
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid[column][row] != null:
				var tween = create_tween()
				tween.tween_property(shells_grid[column][row], "modulate", Color.DARK_VIOLET, 0.3 * (Globals.NUM_ROWS - row))
	emit_signal("player_game_over")

# this function is created when the player collects junk (due to other players' fireworks)
func increase_junk(amount:int,_pos_x:int,_pos_y:int) -> void:
	# Add junk to the player's inventory
	nb_junk += amount
	junk_label.text = "Junk: " + str(nb_junk)

	# create a piece of junk at the specified position
	#var junk_piece = JunkPiece.new()
	#junk_piece.position = Vector2(pos_x, pos_y)
	#add_child(junk_piece)

func decrease_junk(amount:int) -> void:
	# Subtract junk from the player's inventory
	nb_junk -= amount
	junk_label.text = "Junk: " + str(nb_junk)
