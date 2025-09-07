class_name CpuPlayer extends Node

# FireworksV1 Game Rules
# Game Overview
# FireworksV1 is a Tetris-like puzzle game where players match colored shells to create firework explosions and earn points. The goal is to prevent your grid from filling up while creating spectacular firework displays.

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


# the top_dropped_shells array is just the current top dropped shells for all columns, based on the shell_grids. 
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


var player_manager : PlayerManager
var timer : Timer
var player  # player object for executing moves

# OPTIMIZATION: Cache for arrangement evaluations to avoid recalculating
var arrangement_cache = {}

# Strategy variables
var falling_shells
var top_dropped_shells
var shells_grid
var current_column
var update_timer


func _init(player_arg: Player):
	print("CPU: Initializing CpuPlayer...")
	player = player_arg
	player_manager = player.get_parent()

func _ready():
	# Set up timer for updating strategy every 0.1 seconds
	update_timer = Timer.new()
	update_timer.wait_time = 0.5
	update_timer.timeout.connect(update_strategy)
	add_child(update_timer)
	update_timer.start()
	print("CPU: Timer started")

# Basic CPU Strategy Implementation following updated comments
func update_strategy():		
	print("CPU : *****************************************************")
	
	# Get current game state
	falling_shells = player_manager.shells_grid.get_falling_shells()
	top_dropped_shells = player_manager.shells_grid.get_top_dropped_shells()
	shells_grid = player_manager.get_shells_grid()
	current_column = player.get_column()

	# OPTIMIZATION: Clear cache periodically to prevent memory bloat
	if arrangement_cache.size() > 100:  # Limit cache size
		arrangement_cache.clear()
		print("CPU: OPTIMIZATION - Cache cleared to prevent memory bloat")

	
	# Step 1: Identify all possible arrangements for the 7 columns
	var possible_arrangements = identify_possible_arrangements(Globals.NUM_COLUMNS)
	print ("CPU : Possible Arrangements : ", possible_arrangements.size())

	# Step 2: For each arrangement, evaluate its potential to create matches and avoid losing the game
	var best_arrangement = null
	
	# Initialize best_score with the score of the current arrangement [0,1,2,3,4,5,6]
	var current_arrangement = []
	for i in range(Globals.NUM_COLUMNS):
		current_arrangement.append(i)
	var best_score = evaluate_arrangement(current_arrangement)
	
	# OPTIMIZATION: Early exit if we find a perfect match
	var perfect_score_threshold = 300  # Adjust based on game balance
	
	for arrangement in possible_arrangements:
		var score = evaluate_arrangement(arrangement)
		if score > best_score:
			best_score = score
			best_arrangement = arrangement
			
			# OPTIMIZATION: Early exit for excellent scores
			if score >= perfect_score_threshold:
				print("CPU: OPTIMIZATION - Found excellent score ", score, ", stopping search early")
				break
	
	print("CPU: Current arrangement ",current_arrangement)
	print_arrangement("CPU : current arrangement ",current_arrangement)
	# Print the falling shells_name
	var falling_shell_names = []
	for shell in falling_shells:
		if shell != null:
			falling_shell_names.append(shell.get_shell_name())
		else:
			falling_shell_names.append(null)
	print("CPU : Falling Shells : ", falling_shell_names)

	print("CPU: Best arrangement score: ", best_score)
	print("CPU: Best arrangement ",best_arrangement)
	if best_arrangement != null:
		print_arrangement("CPU : Best Arrangement : ", best_arrangement)
	
	
	# Step 3: Choose the best arrangement and execute the necessary actions to achieve it
	if best_arrangement != null:
		var actions_needed = calculate_actions_to_achieve_arrangement(best_arrangement)
		print("CPU: Executing ", actions_needed.size(), " actions to achieve best arrangement")
		for action in actions_needed:
			execute_action(action)
			print("CPU ** Doing action: ", action)
	else :
		# force gravity
		player.force_gravity()


func print_arrangement(print_txt:String,arrangement: Array = []):
	if arrangement == null:
		return

	for i in arrangement.size():
		var target_column = arrangement[i]
		if top_dropped_shells[target_column] != null:
			print_txt += "< " + top_dropped_shells[target_column].get_shell_name() + ">"
		else:
			print_txt += " <***> "
	print (print_txt)


# Step 1: Identify all possible arrangements for the 7 columns
# This function will return a set of possible arrangements for the columns as an array of integers. 
# Doing nothing will return the current arrangement [0,1,2,3,4,5,6]
# Doing a switch between the first and second columns will return [1,0,2,3,4,5,6]
func identify_possible_arrangements(nb_columns: int) -> Array:
	var arrangements = []
	
	# OPTIMIZATION: Only generate simple arrangements instead of all 5040 permutations
	# This reduces computation from O(n!) to O(n)
	
	# Start with current arrangement [0,1,2,3,4,5,6]
	var base_arrangement = []
	for i in range(nb_columns):
		base_arrangement.append(i)
	
	# Add current arrangement (no action)
	arrangements.append(base_arrangement.duplicate())
	
	# Add only single adjacent swaps (much more practical)
	for i in range(nb_columns - 1):
		var swap_arrangement = base_arrangement.duplicate()
		# Swap adjacent columns i and i+1
		var temp = swap_arrangement[i]
		swap_arrangement[i] = swap_arrangement[i + 1]
		swap_arrangement[i + 1] = temp
		arrangements.append(swap_arrangement)
	
	print("CPU: OPTIMIZED - Generated only ", arrangements.size(), " practical arrangements instead of ", factorial(nb_columns))
	
	return arrangements

# Helper function to calculate factorial for comparison
func factorial(n: int) -> int:
	if n <= 1:
		return 1
	return n * factorial(n - 1)

# Helper function to generate all permutations of an array
func generate_permutations(arr: Array, start_index: int, result: Array):
	if start_index == arr.size():
		result.append(arr.duplicate())
		return
	
	for i in range(start_index, arr.size()):
		# Swap elements
		var temp = arr[start_index]
		arr[start_index] = arr[i]
		arr[i] = temp
		
		# Recurse
		generate_permutations(arr, start_index + 1, result)
		
		# Backtrack
		temp = arr[start_index]
		arr[start_index] = arr[i]
		arr[i] = temp

# Step 2: Evaluate an arrangement's potential
func evaluate_arrangement(arrangement: Array) -> int:
	# OPTIMIZATION: Check cache first
	var cache_key = str(arrangement)
	if arrangement_cache.has(cache_key):
		return arrangement_cache[cache_key]
	
	var score = 0
	
	# for each column of the arrangement, evaluate the column score and sum it as the total score. 
	for i in range(arrangement.size()):
		score += evaluate_column(i, arrangement[i])

	# OPTIMIZATION: Store in cache before returning
	arrangement_cache[cache_key] = score
	return score

# we evaluate the score as if the column in the index original_column was positionned in the index target_column_index
# implement the following rules 
# Rule 1 : if the shell types match, we give a bonus of 100 points. 
func evaluate_column (original_column_index : int, target_column_index : int) -> int:
	var score = 0

	# the height of the column
	var column_height = player_manager.shells_grid.get_column_height(target_column_index)
	var lowest_height = player_manager.shells_grid.get_lowest_column_height()
	var has_match = false

	# if it's a bottom_shell, we try to put it on the shortest column. 
	if falling_shells[original_column_index] != null:
		if falling_shells[original_column_index].get_shell_type() == Globals.BOTTOM_SHELL:
			if column_height == lowest_height:
				score += 200

	# if the shell types match, we give a bonus of 100 points. 
	if top_dropped_shells[target_column_index] != null and falling_shells[original_column_index] != null:
		if top_dropped_shells[target_column_index].get_shell_type() == falling_shells[original_column_index].get_shell_type():
			has_match = true
			score += 100 * column_height

	# if a match can't be done, try to put the falling_shell in the lowest 
	if !has_match and column_height == lowest_height:
		score += 50 * column_height

	return score


# Step 3: Calculate actions needed to achieve a target arrangement
func calculate_actions_to_achieve_arrangement(target_arrangement: Array) -> Array:
	var actions = []
	
	
	# Start with current arrangement [0,1,2,3,4,5,6]
	var current_arrangement = []
	for i in range(Globals.NUM_COLUMNS):
		current_arrangement.append(i)
	
	# If already at target, no actions needed
	if arrays_equal(target_arrangement, current_arrangement):

		return actions
	
	# Bubble sort the target_arrangement to get back to [0,1,2,3,4,5,6]
	# Record all the swaps, then reverse them
	var working_arrangement = target_arrangement.duplicate()
	var forward_actions = []

	
	# Bubble sort to transform target_arrangement to [0,1,2,3,4,5,6]
	var n = working_arrangement.size()
	for i in range(n):
		for j in range(0, n - i - 1):
			if working_arrangement[j] > working_arrangement[j + 1]:				
				# Swap elements
				var temp = working_arrangement[j]
				working_arrangement[j] = working_arrangement[j + 1]
				working_arrangement[j + 1] = temp
				
				# Record the swap
				forward_actions.append(j)

	
	
	# Reverse the actions to get the sequence from [0,1,2,3,4,5,6] to target
	forward_actions.reverse()
	actions = forward_actions
	
	print("CPU: Column indexes to swap with right neighbor (reversed): ", actions)
	
	return actions

# Helper function to check if two arrays are equal
func arrays_equal(arr1: Array, arr2: Array) -> bool:
	if arr1.size() != arr2.size():
		return false
	
	for i in range(arr1.size()):
		if arr1[i] != arr2[i]:
			return false
	
	return true



# Execute a single action
func execute_action(action):
	if typeof(action) == TYPE_INT:
		# Action is a column index - swap this column with its right neighbor
		var left_col = action
		var right_col = action + 1
		print("CPU: Executing swap of columns ", left_col, " and ", right_col)
		player.flip_columns(left_col, right_col)
	else:
		print("CPU: Invalid action type: ", typeof(action), " - ", action)
	
