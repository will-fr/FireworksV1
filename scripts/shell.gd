class_name Shell
extends AnimatedSprite2D

enum status { WAITING, FALLING, DROPPED }
var shell_status: status
var shell_type: int

func initialize(column_arg:int,_shell_type_arg:int) -> void:
	shell_type = _shell_type_arg
	shell_status = status.WAITING
	animation = str(shell_type) +"_falling"
	print ("Shell initialized: ", shell_type, " with animation: ", animation)
	# Position the shell in the specified column
	position.x = Globals.LEFT_OFFSET + column_arg * Globals.BLOCK_SIZE  # Assuming 16 pixel spacing
	position.y = Globals.TOP_OFFSET  # Start at top

func get_status() -> status:
	return shell_status

func set_status(new_status: status):
	shell_status = new_status
	if (shell_status == status.DROPPED):
		play(str(shell_type) + "_dropped")

func get_shell_type() -> int:
	return shell_type

func get_shell_name() -> String:
	return Globals.SHELL_NAMES[shell_type]
