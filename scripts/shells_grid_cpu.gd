# # NORMALLY NOT NEEDED. 



# class_name ShellsGridCpu extends Node2D

# var shells_grid: Array = []


# # Initialize the 2D shells grid with empty cells
# func _init():
# 	init_grid()

# # this function initialize the shells grid with empty cells. 
# func init_grid():	
# 	shells_grid.clear()
# 	for column in Globals.NUM_COLUMNS:
# 		var column_array = []
# 		for row in Globals.NUM_ROWS:
# 			column_array.append(null)  # Initialize with null/empty cells
# 		shells_grid.append(column_array)

# func count_waiting_shells() -> int:
# 	var waiting_shells = 0
# 	for column in Globals.NUM_COLUMNS:
# 		for row in Globals.NUM_ROWS:
# 			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.WAITING:
# 				waiting_shells += 1
# 	return waiting_shells

# func count_falling_shells() -> int:
# 	var falling_shells = 0
# 	for column in Globals.NUM_COLUMNS:
# 		for row in Globals.NUM_ROWS:
# 			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.FALLING:
# 				falling_shells += 1
# 	return falling_shells

# func get_column_height(column:int) -> int:
# 	# Returns the height of the specified column (number of non-null shells)
# 	var height = 0
# 	for row in Globals.NUM_ROWS:
# 		if shells_grid[column][row] != null:
# 			if shells_grid[column][row].get_status() == Shell.status.DROPPED:
# 				height += 1
# 	return height

# # return the height of the lowest columns. 
# func get_lowest_column_height() -> int:
# 	var min_height = Globals.NUM_ROWS
# 	for column in Globals.NUM_COLUMNS:	
# 		var height = get_column_height(column)
# 		if height < min_height:
# 			min_height = height
# 	return min_height


# # this function returns a list of all falling shells
# func get_falling_shells() -> Array:
# 	var falling_shells = []
# 	# Initialize array with proper size
# 	for column in Globals.NUM_COLUMNS:
# 		falling_shells.append(null)
	
# 	for column in Globals.NUM_COLUMNS:
# 		for row in Globals.NUM_ROWS:
# 			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.FALLING:
# 				falling_shells[column] = shells_grid[column][row]
# 				break  # Only get the first (topmost) falling shell per column
# 	return falling_shells

# # this function returns a list of all waiting shells
# func get_waiting_shells() -> Array:
# 	var waiting_shells = []
# 	# Initialize array with proper size
# 	for column in Globals.NUM_COLUMNS:
# 		waiting_shells.append(null)

# 	for column in Globals.NUM_COLUMNS:
# 		for row in Globals.NUM_ROWS:
# 			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.WAITING:
# 				waiting_shells[column] = shells_grid[column][row]
# 				break  # Only get the first (topmost) waiting shell per column
# 	return waiting_shells

# func get_top_dropped_shells() -> Array:
# 	var top_dropped_shells = []
# 	# Initialize array with proper size
# 	for column in Globals.NUM_COLUMNS:
# 		top_dropped_shells.append(null)
		
# 	for column in Globals.NUM_COLUMNS:
# 		# Find the topmost dropped shell in each column (highest row index)
# 		for row in range(Globals.NUM_ROWS - 1, -1, -1):  # Start from top
# 			if shells_grid[column][row] != null and shells_grid[column][row].get_status() == Shell.status.DROPPED:
# 				top_dropped_shells[column] = shells_grid[column][row]
# 				break  # Only get the topmost dropped shell per column
# 	return top_dropped_shells
