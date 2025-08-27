class_name GameManagerSprite extends Node2D

const POP_SCORE = 10  # Points awarded for popping shells
const FIREWORK_SCORE = [11, 222, 3333, 4444, 5555,66666,77777,8888888,9999999]  # Points for shells of different sizes
var shells_grid: Array = [] # 2D array storing shell values: shells_grid[column][row]
var score:int = 0  # Initialize score variable
var even_loop = true
var nb_shells_per_batch:int = 1
var player_active: bool = true

# signal
signal player_paused
signal player_resumed

# Reference to the player node for signal connections and position tracking
@onready var player : Player = get_node("Player")  # Adjust path as needed
@onready var game_timer: Timer = get_node("GameTimer")  # Timer for game updates
@onready var score_label: Label = get_node("Score")  # Adjust path as needed

func _ready() -> void:
	initialize_shells_grid()
	player.flip.connect(_on_player_flip)
	player.force_gravity.connect(_on_force_gravity)

# Handle player status change events (FRONT/BACK switching)
func _on_player_flip(_new_status: Player.flip_status):
	var player_column = player.get_column()
	switch_columns(player_column,player_column+1)  # Switch adjacent columns

# When the player forces gravity (by pushing "down")
func _on_force_gravity():
	main_game_loop()

# Main game loop called every second by the update timer
func _on_game_timer_timeout() -> void:
	main_game_loop()

func set_player_pause():
	player_active = false
	game_timer.stop()
	emit_signal("player_paused")
	# Pause game logic here

func set_player_play():
	player_active = true
	game_timer.start()
	emit_signal("player_resumed")
	# Resume game logic here

func main_game_loop():
	# Execute all game mechanics in order: physics, interactions, spawning, display
	if game_timer.is_stopped():
		return 

	if even_loop:
		if count_waiting_shells() == 0:
			add_new_shells()
		move_falling_sprites()
	else:
		if count_falling_shells() ==0:
			drop_waiting_shells()
		gravity_manager() 	
		move_falling_sprites()	
	even_loop = !even_loop


# Initialize the 2D shells grid with empty cells
func initialize_shells_grid():
	shells_grid.clear()
	for column in Globals.NUM_COLUMNS:
		var column_array = []
		for row in Globals.NUM_ROWS:
			column_array.append(null)  # Initialize with null/empty cells
		shells_grid.append(column_array)

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

func add_points(increment:int):
	# Increment the score by a specified amount
	score += increment
	if score_label:
		score_label.text = "Score: " + str(score)  # Update the score label in the UI

# Spawn new shells at random columns every 5 seconds
func add_new_shells():
	# Add random shells to the top row of 2 randomly selected columns
	var last_row_index = Globals.NUM_ROWS - 1  # Last row (top of the grid)

	# Select 2 unique random columns to spawn shells
	var selected_columns = []
	while selected_columns.size() < nb_shells_per_batch:
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
		print("  -- POPPING ON THE SAME THAN ME AT [", column, "][", row, "]")
		print("  -- I AM a ", shells_grid[column][row].get_shell_type())
		print("  -- I AM ABOVE a ", shells_grid[column][row-1].get_shell_type())
		create_small_firework(shells_grid[column][row].position.x+int(Globals.BLOCK_SIZE/2), shells_grid[column][row-1].position.y, shells_grid[column][row].get_shell_type())
		remove_shell(column,row)  # Remove the current firework
		remove_shell(column,row-1)  # Remove the matching firework below
		add_points(POP_SCORE)  # Add points for popping fireworks	
		return
	# IF I'M A TOP SHELL, I LOOK FOR A BOTTOM SHELL, OTHERWISE I POP ALONE.
	if shells_grid[column][row].get_shell_type() == Globals.TOP_SHELL:
		# we check if there's a BOTTOM_SHELL below to pop the whole column
		for row_check in range(row - 1, -1, -1):
			# If we find a BOTTOM_SHELL, we pop the firework.
			if shells_grid[column][row_check].get_shell_type() == Globals.BOTTOM_SHELL:
				create_big_firework(column,row,row_check)
				
				return  # Exit after popping the whole column
		# if not found, we just pop the TOP_SHELL alone.
		print ("  -- POPPING TOP SHELL ALONE AT [", column, "][", row, "]")
		create_small_firework(shells_grid[column][row].position.x+int(Globals.BLOCK_SIZE/2), shells_grid[column][row].position.y+int(Globals.BLOCK_SIZE/2),Globals.TOP_SHELL)
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
	set_player_pause()
	print ("  -- Creating big firework at column ", column, " from row ", top_row, " to row ", bottom_row)
	shells_grid[column][top_row].set_status(Shell.status.DROPPED)
	shells_grid[column][bottom_row].play("1_light")
	shells_grid[column][bottom_row].animation_finished.connect(_on_big_rocket_assembled.bind(column, top_row, bottom_row))


# Event called when a shell finishes converging
func _on_big_rocket_assembled(column: int, top_row: int, bottom_row: int):
	print ("  -- Rocket assembled on column ", column, " from row ", top_row, " to row ", bottom_row)
	shells_grid[column][bottom_row].play("1_fly")
	for row in range(top_row, bottom_row - 1 , -1):
		shells_grid[column][row].z_index = 100  # Bring to front
		var tween = create_tween()
		tween.tween_property(shells_grid[column][row], "position:y", -200, 0.5)
		if (row == bottom_row):
			tween.finished.connect(_on_big_rocket_launched.bind(column, top_row, bottom_row))


func _on_big_rocket_launched(column: int, top_row: int, bottom_row: int):
	print ("  -- Rocket launched on column ", column, " from row ", top_row, " to row ", bottom_row)
	var fireworks_colors = []
	for r in range(top_row , bottom_row - 1, -1):
		if shells_grid[column][r].get_shell_type()!=Globals.TOP_SHELL and shells_grid[column][r].get_shell_type()!=Globals.BOTTOM_SHELL:
			fireworks_colors.append(shells_grid[column][r].get_shell_type())
		remove_shell(column,r)
	add_points(FIREWORK_SCORE[top_row-bottom_row-1])
	set_player_play()
	launch_big_firework(fireworks_colors)

func launch_big_firework(fireworks_colors: Array):
	# Create an instance of the big_firework scene
	print ("  -- Launching big firework with colors: ", fireworks_colors)
	var load_scene_one = load("res://scenes/big_firework.tscn")
	var new_firework = load_scene_one.instantiate()
	add_child(new_firework)
	var side_fw:String
	if player.player_type == Player.player_dic.P1:
		side_fw = "left"
	else:
		side_fw = "right"
	new_firework.initialize(fireworks_colors, side_fw)

	# var load_scene_one = load("res://scenes/big_firework.tscn")
	# var new_instance = load_scene_one.instantiate()
	# new_instance.position = Vector2(x_arg+Globals.BLOCK_SIZE/2, y_arg+Globals.BLOCK_SIZE/2)  # Set initial position
	# add_child(new_instance) 


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
		var initial_x = 32 + left_column * Globals.BLOCK_SIZE
		var tween = create_tween()
		tween.tween_property(shells_grid[left_column][row], "position:x", initial_x + Globals.BLOCK_SIZE, 0.1)

	# i move the right block to the left.
	if shells_grid[right_column][row] != null:
		var initial_x = 32 + right_column * Globals.BLOCK_SIZE
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
