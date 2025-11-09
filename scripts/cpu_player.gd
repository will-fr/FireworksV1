class_name CpuPlayer extends Node2D

# FireworksV1 Game Rules
# Game Overview
# FireworksV1 is a Tetris-like puzzle game wher


# Game Grid & Setup
# Grid Size: 7 columns × 8 rows
# Players: 2 players (human vs human, human vs CPU, or CPU vs CPU)
# Block Size: 16×16 pixels per shell

# SHELL TYPES : The game features 6 different shell types:
# - Bottom Shell (Type 1): Used to create big rockets
# - Top Shell (Type 2): Used to create big rockets
# - Green Shell (Type 3): Standard colored shell
# - Red Shell (Type 4): Standard colored shell
# - Blue Shell (Type 5): Standard colored shell
# - Yellow Shell (Type 6): Standard colored shell

# SHELL STATES: Each shell has one of three states:
# - WAITING: Just spawned, not yet falling
# - FALLING: Currently dropping down the grid
# - DROPPED: Settled at the bottom or on another shell

# PLAYER CONTROLS
# Move Left/Right: Navigate between columns 0-6
# lift: lift the content of the current column, with the idea to move it. All the dropped shells are moved up
# if the player moves left while lifting, his current column and the column directly to its left are swapped.
# if the player moves right while lifting, the current column and the column directly to its right are swapped.
# Force Gravity: accelerate the game loop, making all falling shells drop faster.

# Core Game Mechanics
# 1. Shell Spawning
# Every second, new shells spawn at random columns in the top row
# Shells start in WAITING state, then become FALLING
# Number of shells per batch can increase based on "junk" received
# 2. Gravity & Movement
# Shells fall down one row at a time until they hit something
# When a shell can't fall further, it becomes DROPPED

# 3. Matching & Popping
# Simple Match: When a falling shell lands on a dropped shell of the same type → Both shells pop → +10 points
# Big Rocket Creation: When a TOP_SHELL falls and finds a BOTTOM_SHELL below it → Creates a big firework → Higher points
# Single Pop: If a TOP_SHELL can't find a BOTTOM_SHELL → Pops alone → Basic points

# 4. Data access and player movement
# The Player class is responsible for managing the player's state, including their position, score, and the shells they control.
# The CPU player will need to access this data to make informed decisions.
# you can get the column you're in by accessing the player.get_column(). It will return an int between 0 (you're on the left) and 6 (you're on the right)
# you can move left or right by calling player.move_left() or player.move_right().
# to flip columns, you need to lift it first, then move to the left or to the right.  
# if you need to access the shells controlled by the player, you can use player_manager.get_shells_grid()
# getting a continuous update of the shells grid will be important for the CPU's decision-making process.
# you can flip the current column and the adjacent column by calling player.flip_left() or player.flip_right().


# 5. Column Management
# The combination of lifting and moving will be key to rearrange the dropped columns in the desired state. 
# Strategic positioning is key to creating matches
# Scoring System
# Simple Pop: 10 points (POP_SCORE)
# Big Fireworks: Variable points based on size (FIREWORK_SCORE array: 10, 50, 100, 200, 500, 1000)
# Bigger rockets = Higher scores
# Multiplayer Mechanics
# When a player creates fireworks, the opponent receives "junk"
# Junk increases the number of shells spawned in the opponent's next batch
# This creates competitive pressure and attack/defense dynamics
# Win/Lose Conditions
# Game Over: When shells reach the top row (row 7) of any column
# Winner: The last player standing (opponent's grid fills up first)
# Strategic Elements
# Defensive: Clear shells before grid fills up
# Offensive: Create big fireworks to send junk to opponent
# Positioning: Move to optimal columns for matches
# Timing: Use gravity forcing and flipping strategically
# Rocket Building: Combine TOP_SHELL + BOTTOM_SHELL for maximum impact


# the top_dropped_shells array is just the current top dropped shells for all columns, based on the cpu_shell_grids. 
# so by lifting and moving the columns, you will update the top_dropped_shells array as well.. 
# IMPORTANT: The match will only happen if the waiting shells and top dropped shells are aligned correctly, meaning their index
# in the array must correspond.


# Your priorities are in this order. 
# 1. Avoid losing the game (you lose the game when a shell reaches the top row). 
# 2. Maximize your scoring. 


# To perform the strategy, follow these steps : 
# 1. Identify all the arrangements that can be done for the 7 columns of the shells_grid. 
# 2. For each of the arrangement, perform a scoring function and only keep the best scoring option. 
# 3. Choose the best arrangement and execute the necessary actions to achieve it.


# ================================
# CLASS VARIABLES
# ================================

var timer : Timer                    # Timer for periodic strategy updates
var player : Player                  # Reference to the player object for executing moves
var player_manager : PlayerManager   # Reference to player manager for accessing game state
var falling_shells : Array = []     # Array of currently falling shells (one per column)
var top_dropped_shells : Array = [] # Array of topmost dropped shells (one per column)
var rockets_sizes : Array = []      # Array of sizes of the biggest rocket possible (one per column)
var cpu_shells_grid : Array = []    # CPU's internal representation of the game grid
var current_column : int             # Current column position of the player
var update_timer : Timer             # Timer that triggers strategy updates every 1.0 seconds
var actions_needed :Array = []

# get the game timer from the scene tree
@onready var game_timer: GameTimer 
@onready var cpu_lag_timer : Timer 



# ================================
# INITIALIZATION FUNCTIONS
# ================================

## Constructor - Initialize the CPU player with a reference to the game player
## @param player_arg: The Player object this CPU will control
func _init(player_arg: Player):
	print("CPU: Initializing CpuPlayer...")
	player = player_arg                    # Store reference to the player we're controlling
	player_manager = player.get_parent()   # Get reference to the PlayerManager for game state access
	cpu_lag_timer = player_manager.get_node("CpuLagTimer")
	init_cpu_shell_grid()                  # Initialize our internal grid representation


## Sets up the strategy update timer that drives the CPU decision-making
func _ready():
	game_timer = get_tree().get_root().get_node("Game/Gui/GameTimer")
	if game_timer != null:
		game_timer.game_started.connect(Callable(self, "_launch_game"))
		print("CPU: Connected to GameTimer's game_started signal.")
	else:
		print("CPU: ERROR - GameTimer not found in scene tree.")
	





func _launch_game():
	cpu_lag_timer.timeout.connect(_on_cpu_lag_timer_timeout)

	
func _on_cpu_lag_timer_timeout():
	#if the player is not active, I do nothing. 
	if !player.player_is_active:
		return

	print("CPU: *****************************************************")
	print("CPU: Wait time of the cpu lag timer at time ", cpu_lag_timer.wait_time)
	
	# otherwise, I perform the actions needed, or update the strategy if there's nothing to do.
	if actions_needed.size()>0: 
		print("CPU: TimeOut: still " + str(actions_needed.size()) + " actions to execute, Executing action flipping column ", actions_needed[0])
		# get the first elements from the actions_needed array and execute it.
		var action = actions_needed[0]
		await execute_action(action)
	else:
		update_strategy()


## Initialize the CPU's internal grid representation
## Creates a 2D array structure matching the game grid (7 columns × 8 rows)
## All cells are initialized to null (empty)
func init_cpu_shell_grid():
	cpu_shells_grid.clear()                          # Clear any existing data
	for column in Globals.NUM_COLUMNS:               # For each of the 7 columns
		var column_array = []                        # Create array for this column
		for row in Globals.NUM_ROWS:                 # For each of the 8 rows
			column_array.append(null)                # Initialize cell as empty
		cpu_shells_grid.append(column_array)         # Add column to grid
	

## Update and return the CPU's internal representation of the game grid
## Converts the game's Shell objects into simple integer representations:
## - Positive numbers: DROPPED shells (stable, can be matched with)
## - Negative numbers: FALLING shells (still moving, will land somewhere)
## - null: Empty cells
## @return Array: 2D array representing the current game state
func get_cpu_shell_grid():
	var shells_grid = player_manager.get_shells_grid()  # Get current game state
	
	# Convert each shell to our simplified representation
	for i in range(Globals.NUM_COLUMNS):                # For each column (0-6)
		for j in range(Globals.NUM_ROWS):               # For each row (0-7)
			if shells_grid[i][j] != null:               # If there's a shell in this cell
				if shells_grid[i][j].get_status() == Shell.status.DROPPED:
					# Positive number = settled shell that can be matched
					cpu_shells_grid[i][j] = shells_grid[i][j].get_shell_type()
				elif shells_grid[i][j].get_status() == Shell.status.FALLING:
					# Negative number = falling shell (not yet settled)
					cpu_shells_grid[i][j] = -shells_grid[i][j].get_shell_type()
			else:
				cpu_shells_grid[i][j] = null            # Empty cell

	return cpu_shells_grid


# ================================
# MAIN STRATEGY FUNCTION
# ================================

## Main CPU strategy function - called every 0.5 seconds by the timer
## Implements a three-step strategy:
## 1. Identify possible column arrangements (what moves are available)
## 2. Evaluate each arrangement (score the potential outcomes)
## 3. Execute the best arrangement (perform the necessary column swaps)
func update_strategy():		
	
	print("CPU : Updating strategy.... Time is ", Time.get_ticks_msec())
	
	# ===== STEP 0: Update Current Game State =====
	cpu_shells_grid = get_cpu_shell_grid()        # Get full grid state with shell types
	falling_shells = get_falling_shells()         # Get currently falling shells per column
	print ("CPU: Falling shells: ", falling_shells)
	rockets_sizes = get_rocket_sizes()			   # Get size of the biggest rocket possible
	print ("CPU: Rocket sizes: ", rockets_sizes)
	top_dropped_shells = get_top_dropped_shells() # Get topmost settled shells per column
	current_column = player.get_column()          # Get player's current position

	var possible_arrangements
		
	possible_arrangements = identify_possible_arrangements(Globals.NUM_COLUMNS)
		
	# ===== STEP 2: Evaluate Each Arrangement =====
	# Score each possible arrangement based on match potential and game safety
	var best_arrangement = null
	
	# Start with the current arrangement [0,1,2,3,4,5,6] as baseline
	var current_arrangement = []
	for i in range(Globals.NUM_COLUMNS):
		current_arrangement.append(i)
	var best_score = evaluate_arrangement(current_arrangement)
	print ("CPU: Current arrangement score: ", best_score)
	# Test each possible arrangement and keep track of the best one
	
	for arrangement in possible_arrangements:
		var score = evaluate_arrangement(arrangement)
		print ("ARRANGEMENT TESTED: ",arrangement, " scored ",score)
		if score > best_score:
			best_score = score
			best_arrangement = arrangement
			
	
	print("CPU: Best arrangement score: ", best_score)
	print("CPU: Best arrangement: ", best_arrangement)

	# ===== STEP 3: Execute the Best Strategy =====
	if best_arrangement != null:
		# Calculate the sequence of column swaps needed to achieve the best arrangement
		actions_needed = calculate_actions_to_achieve_arrangement(best_arrangement)
		print("CPU: Executing ", actions_needed.size(), " actions to achieve best arrangement")

	else :
		# If no better arrangement is found, just force gravity to speed up the game
		print("CPU: No better arrangement found, forcing gravity")
		player.force_gravity()
		#await get_tree().create_timer(cpu_lag).timeout


	
# ================================
# HELPER FUNCTIONS - Game State Analysis
# ================================

## Calculate the height of a specific column (number of settled shells)
## Only counts DROPPED shells (positive values), ignoring FALLING shells
## @param column: Column index (0-6)
## @return int: Number of settled shells in the column
func get_column_height(column:int) -> int:
	var height = 0
	for row in Globals.NUM_ROWS:
		# Only count settled (DROPPED) shells, not falling ones
		if cpu_shells_grid[column][row] != null and cpu_shells_grid[column][row] > 0:
			height += 1
	return height

## Find the height of the shortest column in the grid
## Used for strategic placement - we prefer to keep columns balanced
## @return int: Height of the column with the fewest settled shells
func get_lowest_column_height() -> int:
	var min_height = Globals.NUM_ROWS              # Start with maximum possible height
	for column in Globals.NUM_COLUMNS:	
		var height = get_column_height(column)     # Get height of this column
		if height < min_height:
			min_height = height                    # Update minimum if this is shorter
	return min_height


## Extract all currently falling shells from the grid
## Returns an array where each index represents a column (0-6)
## Each value is either the shell type (negative number) or null if no falling shell
## @return Array: List of falling shells, one per column (null if no falling shell)
func get_falling_shells() -> Array:
	var falling_shells_list = []
	
	# Initialize array with null values for all columns
	for column in Globals.NUM_COLUMNS:
		falling_shells_list.append(null)
	
	# Search each column for falling shells (negative values in our representation)
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if cpu_shells_grid[column][row] != null and cpu_shells_grid[column][row] < 0:
				falling_shells_list[column] = cpu_shells_grid[column][row]
				break  # Only get the first (topmost) falling shell per column
	return falling_shells_list


## Extract the topmost settled shell from each column
## These are the shells that falling shells will land on and potentially match with
## Returns an array where each index represents a column (0-6)
## @return Array: List of topmost settled shells, one per column (null if column is empty)
func get_top_dropped_shells() -> Array:
	var top_dropped_shells_list = []
	
	# Initialize array with null values for all columns
	for column in Globals.NUM_COLUMNS:
		top_dropped_shells_list.append(null)
		
	for column in Globals.NUM_COLUMNS:
		# Search from top to bottom to find the highest settled shell
		for row in range(Globals.NUM_ROWS - 1, -1, -1):  # Start from top (row 7)
			if cpu_shells_grid[column][row] != null and cpu_shells_grid[column][row] > 0:
				top_dropped_shells_list[column] = cpu_shells_grid[column][row]
				break  # Only get the topmost dropped shell per column
	return top_dropped_shells_list

## Determine the size of the largest possible rocket that can be built
## A rocket requires a TOP_SHELL (2) above a BOTTOM_SHELL (1)
## This function scans the grid to find the tallest valid rocket configuration
## @return int: Size of the largest rocket (number of shells), or 0 if none possible
func get_rocket_sizes() -> Array:
	var rockets_sizes_list = []

	# Initialize array with null values for all columns
	for column in Globals.NUM_COLUMNS:
		rockets_sizes_list.append(null)

	# Check each column for potential rocket configurations
	for column in Globals.NUM_COLUMNS:
		var bottom_shell_row = null

		# Find the bottom shell (1) and top shell (2) in this column
		for row in Globals.NUM_ROWS:
			if cpu_shells_grid[column][row] == Globals.BOTTOM_SHELL:
				bottom_shell_row = row
				break
		
		if bottom_shell_row != null:
			rockets_sizes_list[column] = get_column_height(column) - bottom_shell_row
		else :
			rockets_sizes_list[column] = 0

	return rockets_sizes_list


## Debug function to print a visual representation of an arrangement
## Shows what the top row would look like after applying the arrangement
## @param print_txt: Prefix text for the debug output
## @param arrangement: Array representing the column arrangement to visualize
func print_arrangement(print_txt:String, arrangement: Array = []):
	if arrangement == null:
		return

	# Build visual representation of the arrangement
	for i in arrangement.size():
		var target_column = arrangement[i]
		if top_dropped_shells[target_column] != null:
			print_txt += "< " + str(top_dropped_shells[target_column]) + ">"
		else:
			print_txt += " <***> "  # Empty column indicator
	print ("CPU: Arrangement : " + print_txt)


# ================================
# ARRANGEMENT GENERATION - Step 1 of Strategy
# ================================

## Generate all possible column arrangements the CPU can achieve
## An arrangement is represented as an array of column indices [0,1,2,3,4,5,6]
## where each position represents which original column goes in that position.
##
## Example arrangements:
## - [0,1,2,3,4,5,6]: No change (current state)
## - [1,0,2,3,4,5,6]: Swap columns 0 and 1
## - [0,2,1,3,4,5,6]: Swap columns 1 and 2
##
## OPTIMIZED GENERATION: Generates strategic arrangements only
## Instead of 5040 permutations, focus on meaningful moves:
## 1. Current state (do nothing)
## 2. Adjacent swaps (immediate moves)
## 3. Match-focused arrangements (only when matches are possible)
## @param nb_columns: Number of columns in the grid (should be 7)
## @return Array: List of strategic arrangements, each as an array of column indices
func identify_possible_arrangements(nb_columns: int) -> Array:
	var arrangements = []
	
	# Create base arrangement representing current state [0,1,2,3,4,5,6]
	var base_arrangement = []
	for i in range(nb_columns):
		base_arrangement.append(i)
	
	# Always include current arrangement (do nothing option)
	arrangements.append(base_arrangement.duplicate())
	
	# Add adjacent swaps (most practical moves)
	for i in range(nb_columns - 1):
		var swap_arrangement = base_arrangement.duplicate()
		var temp = swap_arrangement[i]
		swap_arrangement[i] = swap_arrangement[i + 1]
		swap_arrangement[i + 1] = temp
		arrangements.append(swap_arrangement)
	
	# OPTIMIZATION: Only add complex arrangements if matches are available
	if has_potential_matches():
		add_match_focused_arrangements(arrangements, base_arrangement)
	
	print("CPU: Generated ", arrangements.size(), " strategic arrangements (optimized from 5040)")
	return arrangements

## Check if there are potential matches available that justify complex arrangements
## @return bool: True if there are falling shells that could match with dropped shells
func has_potential_matches() -> bool:
	for i in range(Globals.NUM_COLUMNS):
		if falling_shells[i] != null:
			# Look for matching dropped shells in other columns
			for j in range(Globals.NUM_COLUMNS):
				if top_dropped_shells[j] != null:
					if abs(falling_shells[i]) == top_dropped_shells[j]:
						return true
	return false

## Add strategic arrangements focused on creating matches
## Only generates arrangements that could lead to shell matches
## @param arrangements: Array to add new arrangements to
## @param base_arrangement: The base [0,1,2,3,4,5,6] arrangement
func add_match_focused_arrangements(arrangements: Array, base_arrangement: Array):
	var added_count = 0
	var max_additional = 20  # Limit to prevent lag
	
	# For each falling shell, find columns where it could match
	for falling_col in range(Globals.NUM_COLUMNS):
		if falling_shells[falling_col] != null and added_count < max_additional:
			for target_col in range(Globals.NUM_COLUMNS):
				if top_dropped_shells[target_col] != null:
					if abs(falling_shells[falling_col]) == top_dropped_shells[target_col]:
						# Create arrangement that moves this falling shell to target
						if falling_col != target_col:
							var match_arrangement = base_arrangement.duplicate()
							match_arrangement[falling_col] = target_col
							match_arrangement[target_col] = falling_col
							arrangements.append(match_arrangement)
							added_count += 1
							break

## Recursive helper function to generate all permutations of an array
## Uses Heap's algorithm with backtracking to generate all possible arrangements
## This creates every possible way to arrange the column indices
## @param arr: Array to permute (modified in-place during recursion)
## @param start_index: Current position in the recursion (0 to start)
## @param result: Array to store all generated permutations
func generate_permutations(arr: Array, start_index: int, result: Array):
	# Base case: if we've arranged all positions, save this permutation
	if start_index == arr.size():
		result.append(arr.duplicate())  # Must duplicate to avoid reference issues
		return
	
	# Try each remaining element in the current position
	for i in range(start_index, arr.size()):
		# Swap current element to the start_index position
		var temp = arr[start_index]
		arr[start_index] = arr[i]
		arr[i] = temp
		
		# Recursively generate permutations for remaining positions
		generate_permutations(arr, start_index + 1, result)
		
		# Backtrack: restore original order for next iteration
		temp = arr[start_index]
		arr[start_index] = arr[i]
		arr[i] = temp

# ================================
# ARRANGEMENT EVALUATION - Step 2 of Strategy
# ================================

## Evaluate the potential score of a specific arrangement
## This is the core scoring function that determines how good an arrangement would be
## Higher scores indicate better arrangements (more matches, better safety)
## @param arrangement: Array representing which original column goes in each position
## @return int: Total score for this arrangement (higher = better)
func evaluate_arrangement(arrangement: Array) -> int:
	
	var score = 0
	
	# Evaluate each column position in the arrangement
	# arrangement[i] tells us which original column would end up in position i
	for i in range(arrangement.size()):
		score += evaluate_column(i, arrangement[i])
	
	return score

## Evaluate the score for placing a specific falling shell in a target column
## This function implements the core game strategy rules:
## 1. Match falling shells with dropped shells of the same type (high priority)
## 2. Place bottom shells on the shortest columns for stability
## 3. Prefer shorter columns when no matches are available
##
## @param original_column_index: Which column the falling shell is currently in
## @param target_column_index: Which column we're considering moving it to
## @return int: Score for this shell placement (higher = better strategy)
func evaluate_column (original_column_index : int, target_column_index : int) -> int:
	var score = 0

	# Get current game state information
	var column_height = get_column_height(target_column_index)    # How tall is the target column
	var lowest_height = get_lowest_column_height()               # Height of shortest column
	var has_match = false                                        # Will this create a match?

	# STRATEGY RULE 1: Bottom Shell Placement
	# Bottom shells should go on the shortest columns for better rocket building
	if falling_shells[original_column_index] != null:
		if falling_shells[original_column_index] == -Globals.BOTTOM_SHELL:
			if column_height == lowest_height:
				score += 200  # High bonus for optimal bottom shell placement

	# STRATEGY RULE 2: Type Matching (Most Important)
	# If falling shell matches the top dropped shell, we get points and clear space
	if top_dropped_shells[target_column_index] != null and falling_shells[original_column_index] != null:
		if top_dropped_shells[target_column_index] == -falling_shells[original_column_index] && falling_shells[original_column_index] != -Globals.BOTTOM_SHELL:
			has_match = true
			# Higher columns get bigger bonuses because matches clear more space
			score += 1000 * column_height

	# STRATEGY RULE 3: Height Management
	# If no match is possible, prefer the shortest column to keep grid balanced
	if !has_match:
		score = -300 * column_height

	if !has_match and rockets_sizes[target_column_index] > 0:
		score += 100 * rockets_sizes[target_column_index]

	# STRATEGY RULE 4: IF PIECE IS A TOP SHELL, PLACE IT ON THE BIGGEST ROCKET
	if top_dropped_shells[target_column_index] != null and falling_shells[original_column_index] != null:
		if falling_shells[original_column_index] == -Globals.TOP_SHELL:
			score += 40 * rockets_sizes[target_column_index]

	# strategy RULE 5: AVOID PLACING SHELLS IN FULL COLUMNS

	return score


# ================================
# ACTION CALCULATION - Step 3 of Strategy
# ================================

## Calculate the sequence of column swaps needed to achieve a target arrangement
## Uses bubble sort algorithm to determine the minimal number of adjacent swaps
## The algorithm works backwards: sorts target arrangement to [0,1,2,3,4,5,6], 
## then reverses the sequence to get the forward transformation
## @param target_arrangement: The desired final arrangement of columns
## @return Array: Sequence of column indices to swap with their right neighbors
func calculate_actions_to_achieve_arrangement(target_arrangement: Array) -> Array:
	var actions = []
	
	# Create the current arrangement (always starts as [0,1,2,3,4,5,6])
	var current_arrangement = []
	for i in range(Globals.NUM_COLUMNS):
		current_arrangement.append(i)
	
	# If we're already at the target arrangement, no actions needed
	if arrays_equal(target_arrangement, current_arrangement):
		print("CPU: Already at target arrangement, no actions needed")
		return actions
	
	# Use bubble sort to find the sequence of swaps
	# We sort the target_arrangement back to [0,1,2,3,4,5,6] and record each swap
	var working_arrangement = target_arrangement.duplicate()
	var forward_actions = []
	
	# Bubble sort algorithm - each swap moves larger numbers toward the right
	var n = working_arrangement.size()
	for i in range(n):
		for j in range(0, n - i - 1):
			if working_arrangement[j] > working_arrangement[j + 1]:				
				# Swap adjacent elements that are out of order
				var temp = working_arrangement[j]
				working_arrangement[j] = working_arrangement[j + 1]
				working_arrangement[j + 1] = temp
				
				# Record this swap (j is the left column index)
				forward_actions.append(j)
	
	# Reverse the actions to get the sequence from [0,1,2,3,4,5,6] to target
	# This gives us the actual steps the CPU needs to perform
	forward_actions.reverse()
	actions = forward_actions
	
	print("CPU: Column swaps needed (left column of each pair): ", actions)
	
	return actions

## Helper function to check if two arrays contain identical elements in the same order
## Used to determine if we're already at the target arrangement
## @param arr1: First array to compare
## @param arr2: Second array to compare  
## @return bool: True if arrays are identical, false otherwise
func arrays_equal(arr1: Array, arr2: Array) -> bool:
	# Quick check: if sizes differ, arrays can't be equal
	if arr1.size() != arr2.size():
		return false
	
	# Compare each element at the same position
	for i in range(arr1.size()):
		if arr1[i] != arr2[i]:
			return false
	return true

# ================================
# ACTION EXECUTION
# ================================

## Execute a single column swap action
## Takes a column index and swaps that column with its right neighbor
## This is the actual interface to the game's player controls
## @param action: Integer representing the left column of the pair to swap (0-5)
func execute_action(action):
	if typeof(action) != TYPE_INT:
		print("CPU: ERROR - Action must be an integer column index, got: ", action)
		return

	if action < 0 or action > Globals.NUM_COLUMNS - 1:
		print("CPU: ERROR - Action out of range: ", action)
		return

	if player.get_column() < action:
		print("CPU: Moving right from column ", player.get_column(), " to column ", action)
		player.move_right()
		return
	
	if player.get_column() > action:
		print("CPU: Moving left from column ", player.get_column(), " to column ", action)
		player.move_left()
		return
	
	if player.get_column() == action:
		print ("CPU: Flipping column ", action, " with column ", action + 1)
		player.flip_right()
		# remove the executed action from the list
		actions_needed.remove_at(0)
		return
