class_name ShellsGrid extends Node2D

var shells_grid: Array = []
var plates:Array = []
var nb_shells_per_batch:int = 2
var nb_junk:int = 0  # Amount of junk collected (due to other players' fireworks)
@export var player_id: int = 1


@onready var shell_pop_sound: AudioStreamPlayer2D = %ShellPop
@onready var shell_drop_sound: AudioStreamPlayer2D = %ShellDrop
@onready var column_lift_sound: AudioStreamPlayer2D = %ColumnLift
@onready var column_drop_sound: AudioStreamPlayer2D = %ColumnDrop
@onready var big_firework_launch_sound: AudioStreamPlayer2D = %BigFireworkLaunch

# Initialize the 2D shells grid with empty cells
func _ready():
	init_grid()
	create_plates()
	fill_bottom_shells()
	#super_fill_shells()

# this function initialize the shells grid with empty cells. 
func init_grid():	
	shells_grid.clear()
	for column in Globals.NUM_COLUMNS:
		var column_array = []
		for row in Globals.NUM_ROWS:
			column_array.append(null)  # Initialize with null/empty cells
		shells_grid.append(column_array)

# this function fills the bottom row with plates. 
func create_plates():
	var plate_scene = load("res://scenes/plate.tscn")
	for column in Globals.NUM_COLUMNS:
		var new_plate = plate_scene.instantiate()
		add_child(new_plate)
		new_plate.position = Vector2(column * Globals.BLOCK_SIZE + 8, 142)
		plates.append(new_plate)
		# tint the plates
		if player_id == 1:
			new_plate.modulate = Color(0.2, 0.2, 1.0)  # Set a blue tint
		else:
			new_plate.modulate = Color(1.0, 0.2, 0.2)  # Set a red tint

# this function fills the bottom row with shells, including exactly one BOTTOM_SHELL
func fill_bottom_shells():
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
		else:
			# Fill with random colored shells (GREEN=3, RED=4, BLUE=5, YELLOW=6)
			shell_type = randi() % Globals.TYPES_OF_BLOCK + Globals.GREEN
		new_instance.initialize(column, shell_type)
		new_instance.set_status(Shell.status.DROPPED)  # Set as dropped (stable)
		new_instance.z_index = 1
		shells_grid[column][bottom_row_index] = new_instance
		shells_grid[column][bottom_row_index].position.y = Globals.NUM_ROWS * Globals.BLOCK_SIZE  # Position at bottom row

func count_waiting_shells() -> int:
	var waiting_shells = 0
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.WAITING:
				waiting_shells += 1
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

func lift_column(column: int):
	for row in Globals.NUM_ROWS:
		if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.DROPPED:
			shells_grid[column][row].position.y -= 2
	plates[column].position.y -= 2
	column_lift_sound.play()

func drop_column(column: int):
	for row in Globals.NUM_ROWS:
		if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.DROPPED:
			shells_grid[column][row].position.y += 2
	plates[column].position.y += 2
	column_drop_sound.play()

	# Spawn new shells at random columns every x seconds
func add_new_shells():
	# Add random shells to the top row of selected columns. 
	var last_row_index = Globals.NUM_ROWS - 1  # Last row (top of the grid)

	# we identify how many pieces will be added
	var nb_additional_shells_in_this_batch : int = min (nb_junk , Globals.NUM_COLUMNS - nb_shells_per_batch) 
	decrease_junk(nb_additional_shells_in_this_batch)
	var nb_shells_in_this_batch = nb_shells_per_batch + nb_additional_shells_in_this_batch
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
		new_instance.z_index = 100
		shells_grid[column][last_row_index] = new_instance


func drop_shell(column: int, row: int):
	# IF I STACK ON THE SAME SHELL THAN ME, I POP.  
	if row > 0 and shells_grid[column][row-1] != null and shells_grid[column][row-1].get_shell_type() == shells_grid[column][row].get_shell_type():
		#var pos_x :float = float(shells_grid[column][row].position.x) + float(Globals.BLOCK_SIZE) / 2.0
		#var pos_y :int = int(shells_grid[column][row-1].position.y)
		get_parent().create_small_firework(shells_grid[column][row].global_position.x + float(Globals.BLOCK_SIZE) / 2.0, shells_grid[column][row-1].global_position.y, shells_grid[column][row].get_shell_type())
		get_parent().add_points(Globals.POP_SCORE, shells_grid[column][row].global_position)  # Add points for popping fireworks
		remove_shell(column,row)  # Remove the current firework
		remove_shell(column,row-1)  # Remove the matching firework below
		shell_pop_sound.play()
		return
	# IF I'M A TOP SHELL, I LOOK FOR A BOTTOM SHELL, OTHERWISE I POP ALONE.
	if shells_grid[column][row].get_shell_type() == Globals.TOP_SHELL:
		# we check if there's a BOTTOM_SHELL below to pop the whole column
		for row_check in range(row - 1, -1, -1):
			# If we find a BOTTOM_SHELL, we pop the big firework.
			if shells_grid[column][row_check].get_shell_type() == Globals.BOTTOM_SHELL:
				get_parent().create_big_firework(column,row,row_check)
				big_firework_launch_sound.play()
				return  # Exit after popping the whole column
		# if not found, we just pop the TOP_SHELL alone.
		get_parent().create_small_firework(shells_grid[column][row].position.x + float(Globals.BLOCK_SIZE) / 2.0, shells_grid[column][row].position.y + float(Globals.BLOCK_SIZE) / 2.0, Globals.TOP_SHELL)
		remove_shell(column,row)
		shell_drop_sound.play()
		return  
	# DEFAULT CASE: If the shell is not already dropped, mark it as dropped.
	shells_grid[column][row].set_status(Shell.status.DROPPED)  # Mark as stuck
	shell_drop_sound.play()
	if row == Globals.NUM_ROWS - 1:
		get_parent().game_over(column,row)
	return


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

	switch_plates(left_column,right_column)


# switch the plates between the 2 columns and create a movement tween
func switch_plates(left_column: int, right_column: int):
	var initial_x = Globals.LEFT_OFFSET + left_column * Globals.BLOCK_SIZE
	var tween = create_tween()
	tween.tween_property(plates[left_column], "position:x", initial_x + Globals.BLOCK_SIZE, 0.1)

	# i move the right block to the left.
	initial_x = Globals.LEFT_OFFSET + right_column * Globals.BLOCK_SIZE
	tween = create_tween()
	tween.tween_property(plates[right_column], "position:x", initial_x - Globals.BLOCK_SIZE, 0.1)

	# i save my left shell in a temp_shell
	var temp_plate = plates[left_column]
	plates[left_column] = plates[right_column]
	plates[right_column] = temp_plate

# this function is created when the player collects junk (due to other players' fireworks)
func increase_junk(amount:int) -> void:
	# Add junk to the player's inventory
	nb_junk += amount
	get_parent().get_node("Junk").text = "Junk: " + str(nb_junk)

func decrease_junk(amount:int) -> void:
	# Subtract junk from the player's inventory
	nb_junk -= amount
	get_parent().get_node("Junk").text = "Junk: " + str(nb_junk)
	get_parent().get_node("JunkManager").decrease_junk_visuals(amount)


func get_total_junk() -> int:
	return nb_junk

# Fill the entire shells grid without BOTTOM_SHELL and TOP_SHELL, no vertical duplicates
func super_fill_shells():
	var load_scene_one = load("res://scenes/shell.tscn")
	
	# Available shell types (excluding BOTTOM_SHELL and TOP_SHELL)
	# Only colored shells: GREEN=3, RED=4, BLUE=5, YELLOW=6
	var available_types = [Globals.GREEN, Globals.GREEN + 1, Globals.GREEN + 2, Globals.GREEN + 3]
	
	# Clear existing shells first
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid[column][row] != null:
				shells_grid[column][row].queue_free()
				shells_grid[column][row] = null
	
	# Fill each column from bottom to top
	for column in Globals.NUM_COLUMNS:
		var previous_shell_type = -1  # Track previous shell type to avoid duplicates
		
		for row in Globals.NUM_ROWS -2:
			var new_instance = load_scene_one.instantiate()
			add_child(new_instance)
			
			# Choose a shell type that's different from the one below it
			var valid_types = available_types.duplicate()
			if previous_shell_type != -1:
				valid_types.erase(previous_shell_type)  # Remove previous type to avoid stacking
			
			# Select random type from remaining valid types
			var shell_type = valid_types[randi() % valid_types.size()]
			previous_shell_type = shell_type
			
			# Initialize and position the shell
			new_instance.initialize(column, shell_type)
			new_instance.set_status(Shell.status.DROPPED)  # Set as stable/dropped
			new_instance.z_index = 1	
			
			# Position calculation: bottom row is at highest y value
			var y_position = (Globals.NUM_ROWS - row) * Globals.BLOCK_SIZE
			new_instance.position.y = y_position
			
			# Store in grid
			shells_grid[column][row] = new_instance
	
	print("Super fill completed - grid completely filled with only colored shells (no BOTTOM_SHELL or TOP_SHELL) and no vertical duplicates")
