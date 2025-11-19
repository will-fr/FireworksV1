class_name Shell
extends AnimatedSprite2D

enum status { WAITING, FALLING, DROPPED }
var shell_status: status
var shell_type: int

func initialize(column_arg:int,_shell_type_arg:int) -> void:
	shell_type = _shell_type_arg
	shell_status = status.WAITING
	animation = str(shell_type) +"_falling"
	# set alpha to 0.5
	#modulate.a = 0.85
	print ("Shell initialized: ", shell_type, " with animation: ", animation)
	# Position the shell in the specified column
	position.x = column_arg * Globals.BLOCK_SIZE  # Assuming 16 pixel spacing
	position.y = 0

func get_status() -> status:
	return shell_status

func set_status(new_status: status):
	shell_status = new_status
	if (shell_status == status.DROPPED):
		play(str(shell_type) + "_dropped")
		modulate.a = 1.0  # Set alpha to fully opaque when dropped

func get_shell_type() -> int:
	return shell_type

func get_shell_name() -> String:
	return Globals.SHELL_NAMES[shell_type]
