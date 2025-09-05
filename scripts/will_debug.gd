class_name WillDebug extends RichTextLabel

@onready var player_manager: PlayerManager = get_parent()


func _process(_delta: float) -> void:
	update_text(player_manager.shells_grid, player_manager.player, player_manager.even_loop)


# Update the debug display with current game state
func update_text(shells_grid: Array, player: Player, even_loop: bool):
	# Create a visual representation of the fireworks grid and player position

	var display_text = "Loop: "+ str(even_loop)+"\n"

	# Display the grid row by row from top to bottom (reversed for visual clarity)
	for row in range(Globals.NUM_ROWS - 1, -1, -1):
		var row_text = str(row)+ ":"
		for column in Globals.NUM_COLUMNS:
			var shell = shells_grid[column][row]
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

	text = display_text
