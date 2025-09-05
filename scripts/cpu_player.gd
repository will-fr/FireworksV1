class_name CpuPlayer extends Node

# FireworksV1 Game Rules
# Game Overview
# FireworksV1 is a Tetris-like puzzle game where players match colored shells to create firework explosions and earn points. The goal is to prevent your grid from filling up while creating spectacular firework displays.

# Game Grid & Setup
# Grid Size: 6 columns × 8 rows
# Players: 2 players (human vs human, human vs CPU, or CPU vs CPU)
# Block Size: 16×16 pixels per shell
# Shell Types
# The game features 6 different shell types:

# Bottom Shell (Type 1): Used to create big rockets
# Top Shell (Type 2): Used to create big rockets
# Green Shell (Type 3): Standard colored shell
# Red Shell (Type 4): Standard colored shell
# Blue Shell (Type 5): Standard colored shell
# Yellow Shell (Type 6): Standard colored shell
# Shell States
# Each shell has one of three states:

# WAITING: Just spawned, not yet falling
# FALLING: Currently dropping down the grid
# DROPPED: Settled at the bottom or on another shell
# Player Controls
# Move Left/Right: Navigate between columns 0-4 (player controls 2 adjacent columns)
# Flip: Exchange the contents of your current column with the adjacent column
# Force Gravity: Make all waiting shells start falling immediately

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
# you can get the column you're in by accessing the player.get_column(). It will return an int between 0 (you're on the left) and 4 (you're on the right)
# you can move left or right by calling player.move_left() or player.move_right().
# you can flip the columns by calling player.flip().
# if you need to access the shells controlled by the player, you can use player.get_shells().
# getting a continuous update of the shells grid will be important for the CPU's decision-making process.

# 5. Column Management
# Player controls 2 adjacent columns at once
# Flipping swaps the contents of these two columns
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
# so by flipping the columns, you will update the top_dropped_shells array as well.. 
# IMPORTANT: The match will only happen if the waiting shells and top dropped shells are aligned correctly, meaning their index
# in the array must correspond.


# Basic CPU Strategy Implementation:
# 1. identify all the series of 6 flips possibles.
# 2. Print how many possibilities you're evaluating.
# 3. for each of the possibility, evaluate the scoring of the resulting arrangement, given that: 
# - priority 1 is to make sure that falling shells are matched with the corresponding top_dropped_shells. 
# - priority 2 is to make sure that unmatched falling shells are dropped on one of the emptiest column. 
# - priority 3 is to put BOTTOM_SHELLS in empty columns when possible.
# - priority 4 is to ensure that TOP_SHELLS are matched with BOTTOM_SHELLS only when the rocket is 5 to 6 shells high.
# If you don't have moves or flip to perform, force gravity to speed up the game.


var player_manager: PlayerManager  # Reference to the player this CPU controls
var player: Player
var update_timer: Timer
var is_active: bool = true
var falling_shells: Array = []
var waiting_shells: Array = []
var top_dropped_shells: Array = []


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

# CPU Strategy Implementation based on the new approach
func update_strategy():		
	print("CPU : *****************************************************")
	
	# Get current game state
	falling_shells = player_manager.get_falling_shells()
	top_dropped_shells = player_manager.get_top_dropped_shells()
	print_shells_type(falling_shells, "FALLING")
	print_shells_type(top_dropped_shells, "TOP DROPPED")
	
	var current_column = player.get_column()
	print("CPU: Current player column: ", current_column, " (controls columns ", current_column, " and ", current_column + 1, ")")
	
	# Step 1: Identify all possible series of 6 flips
	var all_flip_possibilities = generate_all_flip_sequences(3)
	
	# Step 2: Print how many possibilities we're evaluating
	print("CPU: Evaluating ", all_flip_possibilities.size(), " flip sequence possibilities")
	
	# Step 3: Evaluate each possibility and find the best one
	var best_possibility = evaluate_all_possibilities(all_flip_possibilities)
	
	print("CPU: Best flip sequence: ", best_possibility.flip_sequence)
	print("CPU: Expected score: ", best_possibility.total_score)
	print("CPU: Shell matches: ", best_possibility.shell_matches, ", Unmatched on empty: ", best_possibility.unmatched_on_empty, ", Bottom shells in empty: ", best_possibility.bottom_shells_in_empty, ", Proper rockets: ", best_possibility.proper_rockets)
	
	# Check if we have no beneficial moves to perform
	if best_possibility.flip_sequence.is_empty() and best_possibility.total_score <= 0:
		print("CPU: No beneficial moves found - forcing gravity to speed up the game")
		player_manager._on_force_gravity()
	else:
		# Execute the best flip sequence
		execute_flip_sequence(best_possibility.flip_sequence, current_column)

# Generate all possible flip sequences up to max_flips length
func generate_all_flip_sequences(max_flips: int) -> Array:
	var all_sequences = []
	
	# Add empty sequence (no flips)
	all_sequences.append([])
	
	# Generate sequences of increasing length
	for length in range(1, max_flips + 1):
		var sequences_of_length = generate_flip_sequences_of_length(length)
		all_sequences.append_array(sequences_of_length)
	
	return all_sequences

# Generate all flip sequences of a specific length
func generate_flip_sequences_of_length(length: int) -> Array:
	if length == 0:
		return [[]]
	
	var sequences = []
	var shorter_sequences = generate_flip_sequences_of_length(length - 1)
	
	for sequence in shorter_sequences:
		for flip_position in range(5):  # 0-4 are valid flip positions
			# Avoid immediate reversals (flip A then flip A again)
			if sequence.size() == 0 or sequence[-1] != flip_position:
				var new_sequence = sequence.duplicate()
				new_sequence.append(flip_position)
				sequences.append(new_sequence)
	
	return sequences

# Evaluate all flip possibilities and return the best one
func evaluate_all_possibilities(possibilities: Array) -> Dictionary:
	var best_possibility = {
		"flip_sequence": [],
		"total_score": -999,
		"shell_matches": 0,
		"unmatched_on_empty": 0,
		"bottom_shells_in_empty": 0,
		"proper_rockets": 0
	}
	
	# Current arrangement
	var current_arrangement = []
	for shell in top_dropped_shells:
		if shell != null:
			current_arrangement.append(shell.get_shell_type())
		else:
			current_arrangement.append(null)
	
	for flip_sequence in possibilities:
		# Simulate the arrangement after applying this flip sequence
		var resulting_arrangement = simulate_flip_sequence(current_arrangement, flip_sequence)
		
		# Evaluate this arrangement
		var evaluation = evaluate_arrangement(resulting_arrangement)
		
		# Calculate total score with new four priorities:
		# Priority 1: Shell matches (weight: 200) - Highest priority
		# Priority 2: Unmatched on empty columns (weight: 150)
		# Priority 3: Bottom shells in empty columns (weight: 100)
		# Priority 4: Proper rockets 5-6 shells high (weight: 80)
		var total_score = (evaluation.shell_matches * 200) + (evaluation.unmatched_on_empty * 150) + (evaluation.bottom_shells_in_empty * 100) + (evaluation.proper_rockets * 80)
		
		if total_score > best_possibility.total_score:
			best_possibility.flip_sequence = flip_sequence
			best_possibility.total_score = total_score
			best_possibility.shell_matches = evaluation.shell_matches
			best_possibility.unmatched_on_empty = evaluation.unmatched_on_empty
			best_possibility.bottom_shells_in_empty = evaluation.bottom_shells_in_empty
			best_possibility.proper_rockets = evaluation.proper_rockets
	
	return best_possibility

# Simulate applying a sequence of flips to an arrangement
func simulate_flip_sequence(arrangement: Array, flip_sequence: Array) -> Array:
	var result = arrangement.duplicate()
	
	for flip_position in flip_sequence:
		result = simulate_flip(result, flip_position)
	
	return result

# Evaluate an arrangement according to the four new priorities
func evaluate_arrangement(arrangement: Array) -> Dictionary:
	var shell_matches = 0
	var unmatched_on_empty = 0
	var bottom_shells_in_empty = 0
	var proper_rockets = 0
	
	# Get column heights and emptiness for evaluation
	var column_heights = get_column_heights()
	var column_emptiness = get_column_emptiness_scores()
	
	# Find emptiest columns
	var min_shells = column_emptiness.min() if column_emptiness.size() > 0 else 0
	
	# Evaluate each position
	for i in range(min(falling_shells.size(), arrangement.size())):
		var falling_shell = falling_shells[i]
		
		if falling_shell != null:
			var falling_shell_type = falling_shell.get_shell_type()
			var dropped_shell_type = arrangement[i]
			
			# Priority 1: Falling shells matched with corresponding top_dropped_shells
			var is_matched = (dropped_shell_type != null and falling_shell_type == dropped_shell_type)
			if is_matched:
				shell_matches += 1
			else:
				# Priority 2: Unmatched falling shells on emptiest columns
				if i < column_emptiness.size():
					var column_shell_count = column_emptiness[i]
					if column_shell_count == min_shells:  # Emptiest column
						unmatched_on_empty += 1
			
			# Priority 3: Put BOTTOM_SHELLS in empty columns when possible
			if falling_shell_type == 1:  # BOTTOM_SHELL
				if i < column_heights.size():
					var column_height = column_heights[i]
					if column_height == 0:  # Completely empty column
						bottom_shells_in_empty += 2  # Extra bonus for truly empty
					elif column_height <= 1:  # Nearly empty (0-1 shells)
						bottom_shells_in_empty += 1
			
			# Priority 4: TOP_SHELLS matched with BOTTOM_SHELLS only when rocket is 5-6 shells high
			if falling_shell_type == 2 and dropped_shell_type == 1:  # TOP_SHELL on BOTTOM_SHELL
				if i < column_heights.size():
					var column_height = column_heights[i]
					if column_height >= 5 and column_height <= 6:  # Optimal rocket height
						proper_rockets += 1
					else:
						# Penalty for firing rockets at wrong height
						proper_rockets -= 0.5
	
	return {
		"shell_matches": shell_matches,
		"unmatched_on_empty": unmatched_on_empty,
		"bottom_shells_in_empty": bottom_shells_in_empty,
		"proper_rockets": proper_rockets
	}

# Step 3: Count potential matches between falling shells and top dropped shells
func count_potential_matches() -> Dictionary:
	var falling_types = {}
	var dropped_types = {}
	var matches = []
	var total_matches = 0
	
	# Count shell types in falling shells array
	for shell in falling_shells:
		if shell != null:
			var shell_type = shell.get_shell_type()
			falling_types[shell_type] = falling_types.get(shell_type, 0) + 1
	
	# Count shell types in top dropped shells array
	for shell in top_dropped_shells:
		if shell != null:
			var shell_type = shell.get_shell_type()
			dropped_types[shell_type] = dropped_types.get(shell_type, 0) + 1
	
	#print("CPU: Falling shell types count: ", falling_types)
	#print("CPU: Dropped shell types count: ", dropped_types)
	
	# Find common shell types and count matches (each element can only be counted once)
	for shell_type in falling_types:
		if shell_type in dropped_types:
			var common_count = min(falling_types[shell_type], dropped_types[shell_type])
			total_matches += common_count
			
			# Record each match
			for i in range(common_count):
				matches.append({
					"shell_type": shell_type,
					"match_type": "common"
				})
			
			#print("CPU: Common shell type ", shell_type, " - ", common_count, " matches possible")
	
	return {
		"matches": matches,
		"total_matches": total_matches
	}

# Step 4: Find the optimal target arrangement by testing all possible flip combinations
func find_optimal_target_top_drop_shells(_match_analysis: Dictionary, _current_column: int) -> Dictionary:
	print("CPU: Finding optimal target arrangement through flip combinations...")
	
	# Current arrangement
	var current_arrangement = []
	for shell in top_dropped_shells:
		if shell != null:
			current_arrangement.append(shell.get_shell_type())
		else:
			current_arrangement.append(null)
	
	print("CPU: Current arrangement: ", current_arrangement)
	
	var best_target = {
		"arrangement": current_arrangement.duplicate(),
		"expected_matches": calculate_positional_matches(current_arrangement),
		"description": "current arrangement",
		"flip_sequence": []  # Array of flip positions needed to reach target
	}
	
	# Test all possible flip sequences to find the best arrangement
	var max_flips = 5  # Limit search depth to prevent excessive computation
	var arrangements_to_test = [
		{
			"arrangement": current_arrangement.duplicate(),
			"flips": [],
			"description": "current arrangement"
		}
	]
	
	# Generate all possible arrangements within max_flips
	for flip_depth in range(1, max_flips + 1):
		var new_arrangements = []
		
		for arrangement_data in arrangements_to_test:
			if arrangement_data.flips.size() < flip_depth:
				# Try flipping at each position
				for flip_position in range(5):
					var flipped_arrangement = simulate_flip(arrangement_data.arrangement, flip_position)
					var new_flips = arrangement_data.flips.duplicate()
					new_flips.append(flip_position)
					
					# Avoid immediate reversals (flip A then flip A again)
					var is_reversal = false
					if new_flips.size() >= 2 and new_flips[-1] == new_flips[-2]:
						is_reversal = true
					
					if not is_reversal:
						var description = arrangement_data.description
						if description == "current arrangement":
							description = ""
						else:
							description += " -> "
						description += "flip " + str(flip_position) + "-" + str(flip_position + 1)
						
						new_arrangements.append({
							"arrangement": flipped_arrangement,
							"flips": new_flips,
							"description": description
						})
		
		arrangements_to_test.append_array(new_arrangements)
	
	# Evaluate all arrangements and find the best one
	for arrangement_data in arrangements_to_test:
		var matches = calculate_positional_matches(arrangement_data.arrangement)
		
		if matches > best_target.expected_matches:
			best_target.arrangement = arrangement_data.arrangement
			best_target.expected_matches = matches
			best_target.description = arrangement_data.description
			best_target.flip_sequence = arrangement_data.flips
	
	print("CPU: Best target arrangement: ", best_target.arrangement)
	print("CPU: Expected matches: ", best_target.expected_matches, " (", best_target.description, ")")
	print("CPU: Flip sequence needed: ", best_target.flip_sequence)
	return best_target

# Simulate the result of flipping two adjacent columns
func simulate_flip(arrangement: Array, flip_position: int) -> Array:
	var flipped = arrangement.duplicate()
	
	if flip_position < flipped.size() - 1:
		# Swap adjacent columns
		var temp = flipped[flip_position]
		flipped[flip_position] = flipped[flip_position + 1]
		flipped[flip_position + 1] = temp
	
	return flipped

# Calculate positional matches between falling shells and an arrangement
func calculate_positional_matches(arrangement: Array) -> int:
	var matches = 0
	
	for i in range(min(falling_shells.size(), arrangement.size())):
		var falling_shell = falling_shells[i]
		var dropped_shell_type = arrangement[i]
		
		if falling_shell != null and dropped_shell_type != null:
			if falling_shell.get_shell_type() == dropped_shell_type:
				matches += 1
	
	return matches

# Step 5: Identify the flips necessary to go from current to target arrangement
func identify_necessary_flips(target_arrangement: Dictionary) -> Dictionary:
	# Current arrangement
	var current_arrangement = []
	for shell in top_dropped_shells:
		if shell != null:
			current_arrangement.append(shell.get_shell_type())
		else:
			current_arrangement.append(null)
	
	# Check if we need to flip to reach the target
	var target = target_arrangement.arrangement
	
	# Find which flip position would transform current to target
	for flip_position in range(5):
		var test_flip = simulate_flip(current_arrangement, flip_position)
		if arrays_equal(test_flip, target):
			return {
				"flip_needed": true,
				"flip_position": flip_position,
				"description": "flip columns " + str(flip_position) + " and " + str(flip_position + 1)
			}
	
	# No flip needed - already at target
	return {
		"flip_needed": false,
		"description": "already at target arrangement"
	}

# Helper function to compare two arrays
func arrays_equal(arr1: Array, arr2: Array) -> bool:
	if arr1.size() != arr2.size():
		return false
		
	for i in range(arr1.size()):
		if arr1[i] != arr2[i]:
			return false
	
	return true

# Step 6: Execute the flip sequence to reach target arrangement
func execute_flip_sequence(flip_sequence: Array, current_column: int):
	if flip_sequence.is_empty():
		print("CPU: No flips needed - already at optimal arrangement")
		return
	
	# Execute flips one at a time - get the next flip position to execute
	var next_flip_position = flip_sequence[0]
	var required_player_position = next_flip_position
	
	print("CPU: Need to flip at position ", next_flip_position, " (remaining flips: ", flip_sequence, ")")
	print("CPU: Current player position: ", current_column)
	
	# Move to the required position if not already there
	if current_column != required_player_position:
		if current_column < required_player_position:
			print("CPU: Moving right to reach flip position")
			player.move_right()
		else:
			print("CPU: Moving left to reach flip position")
			player.move_left()
		return  # Move one step at a time
	
	# Execute the flip when in correct position
	print("CPU: Executing flip at position ", next_flip_position, " (columns ", next_flip_position, " and ", next_flip_position + 1, ")")
	player.flip()
	
	# Remove the completed flip from the sequence (for next update cycle)
	flip_sequence.pop_front()# Evaluate how good a specific position would be for creating matches
func evaluate_position_for_matches(position: int, with_flip: bool) -> int:
	var controlled_left = position
	var controlled_right = position + 1
	var score = 0
	
	# Check if this position allows us to control useful shells
	if controlled_left < waiting_shells.size() and waiting_shells[controlled_left] != null:
		var left_shell_type = waiting_shells[controlled_left].get_shell_type()
		
		# Check if this waiting shell type has matches in dropped shells
		for dropped_shell in top_dropped_shells:
			if dropped_shell != null and dropped_shell.get_shell_type() == left_shell_type:
				score += 1
				break  # Found at least one match for this shell type
	
	if controlled_right < waiting_shells.size() and waiting_shells[controlled_right] != null:
		var right_shell_type = waiting_shells[controlled_right].get_shell_type()
		
		# Check if this waiting shell type has matches in dropped shells  
		for dropped_shell in top_dropped_shells:
			if dropped_shell != null and dropped_shell.get_shell_type() == right_shell_type:
				score += 1
				break  # Found at least one match for this shell type
	
	# Add bonus for controlling shells that could be swapped beneficially with flip
	if with_flip and controlled_left < waiting_shells.size() and controlled_right < waiting_shells.size():
		if waiting_shells[controlled_left] != null and waiting_shells[controlled_right] != null:
			# Flipping might create better arrangements
			score += 1
	
	# Add bonus for moving to emptier areas when no matches are possible
	if score == 0:
		var emptiest_col = find_emptiest_column()
		var distance_to_empty = min(abs(controlled_left - emptiest_col), abs(controlled_right - emptiest_col))
		score = max(0, 5 - distance_to_empty)  # Closer to empty = higher score
	
	return score

# Calculate the sequence of moves needed to reach target position
func calculate_moves_to_position(current_pos: int, target_pos: int) -> Array:
	var moves = []
	var distance = target_pos - current_pos
	
	if distance < 0:
		# Need to move left
		for i in range(abs(distance)):
			moves.append("left")
	elif distance > 0:
		# Need to move right
		for i in range(distance):
			moves.append("right")
	
	return moves

# Step 5: Execute the optimal permutation
func execute_optimal_permutation(permutation: Dictionary, current_column: int):
	if permutation.moves.is_empty():
		print("CPU: No moves needed - staying in position")
		return
	
	# Execute moves one at a time (only execute the first move per update cycle)
	var next_move = permutation.moves[0]
	
	match next_move:
		"left":
			if current_column > 0:
				print("CPU: Moving left")
				player.move_left()
			else:
				print("CPU: Cannot move left - at leftmost position")
		"right":
			if current_column < 4:
				print("CPU: Moving right") 
				player.move_right()
			else:
				print("CPU: Cannot move right - at rightmost position")
		"flip":
			print("CPU: Flipping columns")
			player.flip()

# Find the column with the fewest dropped shells (fallback when no matches are possible)
func find_emptiest_column() -> int:
	var shells_grid = player_manager.shells_grid
	var min_shells = 999
	var best_column = 0
	
	for column in range(6):
		var shell_count = 0
		for row in range(shells_grid[column].size()):
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.DROPPED:
				shell_count += 1
		
		if shell_count < min_shells:
			min_shells = shell_count
			best_column = column
	
	print("CPU: Emptiest column: ", best_column, " with ", min_shells, " shells")
	return best_column

# Step 7: Handle unmatched falling shells by dropping them in emptiest columns
func handle_unmatched_falling_shells(current_column: int):
	print("CPU: Step 7 - Handle unmatched falling shells by finding flip sequence to emptiest columns")
	
	# Check if we have any falling shells at all
	var has_falling_shells = false
	for shell in falling_shells:
		if shell != null:
			has_falling_shells = true
			break
	
	if not has_falling_shells:
		print("CPU: No falling shells - staying in position")
		return
	
	# Find target arrangement that would drop unmatched shells in emptiest columns
	var target_arrangement = find_target_arrangement_for_unmatched_shells()
	print("CPU: Target arrangement for unmatched shells: ", target_arrangement.arrangement)
	print("CPU: Expected emptiest drops: ", target_arrangement.expected_emptiest_drops)
	print("CPU: Flip sequence needed: ", target_arrangement.flip_sequence)
	
	# Execute the flip sequence to reach target arrangement
	execute_flip_sequence(target_arrangement.flip_sequence, current_column)

# Find target arrangement that maximizes falling shells landing on emptiest columns
func find_target_arrangement_for_unmatched_shells() -> Dictionary:
	print("CPU: Finding target arrangement to drop unmatched shells on emptiest columns...")
	
	# Get column emptiness scores (lower = emptier)
	var column_emptiness = get_column_emptiness_scores()
	print("CPU: Column emptiness scores: ", column_emptiness)
	
	# Current arrangement of top dropped shells
	var current_arrangement = []
	for shell in top_dropped_shells:
		if shell != null:
			current_arrangement.append(shell.get_shell_type())
		else:
			current_arrangement.append(null)
	
	print("CPU: Current top dropped arrangement: ", current_arrangement)
	
	var best_target = {
		"arrangement": current_arrangement.duplicate(),
		"expected_emptiest_drops": calculate_emptiest_drops(current_arrangement, column_emptiness),
		"description": "current arrangement",
		"flip_sequence": []
	}
	
	# Test all possible flip sequences to find arrangement that maximizes emptiest drops
	var max_flips = 5
	var arrangements_to_test = [
		{
			"arrangement": current_arrangement.duplicate(),
			"flips": [],
			"description": "current arrangement"
		}
	]
	
	# Generate all possible arrangements within max_flips
	for flip_depth in range(1, max_flips + 1):
		var new_arrangements = []
		
		for arrangement_data in arrangements_to_test:
			if arrangement_data.flips.size() < flip_depth:
				# Try flipping at each position
				for flip_position in range(5):
					var flipped_arrangement = simulate_flip(arrangement_data.arrangement, flip_position)
					var new_flips = arrangement_data.flips.duplicate()
					new_flips.append(flip_position)
					
					# Avoid immediate reversals
					var is_reversal = false
					if new_flips.size() >= 2 and new_flips[-1] == new_flips[-2]:
						is_reversal = true
					
					if not is_reversal:
						var description = arrangement_data.description
						if description == "current arrangement":
							description = ""
						else:
							description += " -> "
						description += "flip " + str(flip_position) + "-" + str(flip_position + 1)
						
						new_arrangements.append({
							"arrangement": flipped_arrangement,
							"flips": new_flips,
							"description": description
						})
		
		arrangements_to_test.append_array(new_arrangements)
	
	# Evaluate all arrangements and find the one that maximizes emptiest drops
	for arrangement_data in arrangements_to_test:
		var emptiest_drops = calculate_emptiest_drops(arrangement_data.arrangement, column_emptiness)
		
		if emptiest_drops > best_target.expected_emptiest_drops:
			best_target.arrangement = arrangement_data.arrangement
			best_target.expected_emptiest_drops = emptiest_drops
			best_target.description = arrangement_data.description
			best_target.flip_sequence = arrangement_data.flips
	
	print("CPU: Best target arrangement for emptiest drops: ", best_target.arrangement)
	print("CPU: Expected emptiest drops: ", best_target.expected_emptiest_drops, " (", best_target.description, ")")
	return best_target

# Get emptiness scores for all columns (lower score = emptier column)
func get_column_emptiness_scores() -> Array:
	var shells_grid = player_manager.shells_grid
	var emptiness_scores = []
	
	for column in range(6):
		var shell_count = 0
		for row in range(shells_grid[column].size()):
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.DROPPED:
				shell_count += 1
		emptiness_scores.append(shell_count)
	
	return emptiness_scores

# Get the height (number of dropped shells) for each column
func get_column_heights() -> Array:
	var shells_grid = player_manager.shells_grid
	var column_heights = []
	
	for column in range(6):
		var height = 0
		for row in range(shells_grid[column].size()):
			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.DROPPED:
				height += 1
		column_heights.append(height)
	
	return column_heights

# Calculate how many unmatched falling shells would land on emptier columns with this arrangement
func calculate_emptiest_drops(arrangement: Array, column_emptiness: Array) -> int:
	var emptiest_drops_score = 0
	
	# Find the minimum shell count (emptiest columns)
	var min_shells = column_emptiness.min() if column_emptiness.size() > 0 else 0
	
	# Check each falling shell position
	for i in range(min(falling_shells.size(), arrangement.size(), column_emptiness.size())):
		var falling_shell = falling_shells[i]
		
		if falling_shell != null:
			var falling_shell_type = falling_shell.get_shell_type()
			var dropped_shell_type = arrangement[i]
			var column_shell_count = column_emptiness[i]
			
			# Check if this falling shell would match with the dropped shell at this position
			var would_match = (dropped_shell_type != null and falling_shell_type == dropped_shell_type)
			
			if not would_match:
				# This is an unmatched falling shell - score based on column emptiness
				# Give higher score for dropping on emptier columns
				var emptiness_bonus = (column_emptiness.max() - column_shell_count) if column_emptiness.size() > 0 else 0
				emptiest_drops_score += emptiness_bonus
				
				# Extra bonus for dropping on the absolute emptiest columns
				if column_shell_count == min_shells:
					emptiest_drops_score += 10
				
				print("CPU: Unmatched falling shell type ", falling_shell_type, " at column ", i, 
					  " (shells: ", column_shell_count, ", bonus: ", emptiness_bonus, ")")
	
	return emptiest_drops_score

# print the shell_types of an array of shells. 
func print_shells_type(shells_array: Array,type_of_shells:String="Unknown"):
	var shell_types = []
	for shell in shells_array:
		if shell != null:
			shell_types.append(shell.get_shell_type())
		else:
			shell_types.append(null)
	print("CPU shells: " + type_of_shells + " shells types: ", shell_types)
