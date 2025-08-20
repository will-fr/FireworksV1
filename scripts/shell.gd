class_name Shell
extends AnimatedSprite2D


const TOP_OFFSET:int = 16  # Offset for the top shell
const LEFT_OFFSET:int = 32  # Offset for the left shell

enum status { WAITING, FALLING, DROPPED }
var shell_status: status

var shell_type: int

func initialize(column_arg:int,_shell_type_arg:int) -> void:
	shell_type = _shell_type_arg
	shell_status = status.WAITING
	animation = str(shell_type) +"_falling"

	# Position the shell in the specified column
	position.x = LEFT_OFFSET + column_arg * Globals.BLOCK_SIZE  # Assuming 16 pixel spacing
	position.y = TOP_OFFSET  # Start at top

func get_status() -> status:
	return shell_status

func set_status(new_status: status):
	shell_status = new_status
	if (shell_status == status.DROPPED):
		play(str(shell_type) + "_dropped")

func get_shell_type() -> int:
	return shell_type
