class_name PlayerManager extends Node2D

var score:int = 0  # Initialize score variable
var even_loop = true
var player_active: bool = false


# signals
signal player_paused
signal player_resumed
signal player_game_over
signal points_added

# Reference to the player node for signal connections and position tracking
@onready var player : Player = get_node("Player")  
@onready var player_timer: Timer = get_node("PlayerTimer")  
@onready var score_label: Label = get_node("Score")  
@onready var junk_label: Label = get_node("Junk")  
@onready var countdown: CountDown = get_node("CountDown")  
@onready var shells_grid: ShellsGrid = get_node("ShellsGrid") 


func _ready() -> void:
	# connect the signals. 
	player.player_flipped.connect(_on_player_flip)
	player.gravity_forced.connect(_on_player_forced_gravity)
	player.player_lifted.connect(_on_player_lifted)
	player.player_dropped.connect(_on_player_dropped)
	countdown.connect("countdown_finished", Callable(self, "_on_countdown_finished"))

	set_player_play()
	main_game_loop()
	set_player_pause()

func _on_countdown_finished():
	print("PlayerManager: Countdown finished, starting game.")
	set_player_play()

# Handle player status change events (FRONT/BACK switching)
func _on_player_flip():
	var player_column = player.get_column()
	if player.is_lifting:
		shells_grid.switch_columns(player_column,player_column+1)  # Switch adjacent columns
	elif player_column > 0:
		shells_grid.switch_columns(player_column,player_column-1)  # Switch adjacent columns

# When the player forces gravity (by pushing "down")
func _on_player_forced_gravity():
	main_game_loop()

# Main game loop called every second by the update timer
func _on_player_timer_timeout() -> void:
	main_game_loop()

func _on_player_lifted():
	var current_column = player.get_column()
	shells_grid.lift_column(current_column)

func _on_player_dropped():
	var current_column = player.get_column()
	shells_grid.drop_column(current_column)


func get_shells_grid() -> Array:
	return shells_grid.shells_grid

func set_player_pause():
	player_active = false
	player_timer.stop()
	emit_signal("player_paused")
	# Pause game logic here


func set_player_play():
	player_active = true
	player_timer.start()
	player_timer.is_stopped()
	emit_signal("player_resumed")
	# Resume game logic here

func main_game_loop():
	# Execute all game mechanics in order: physics, interactions, spawning, display
	if player_timer.is_stopped():
		return 
	if even_loop:
		if shells_grid.count_waiting_shells() == 0:
			shells_grid.add_new_shells()
		shells_grid.move_falling_sprites()
	else:
		if shells_grid.count_falling_shells() ==0:
			shells_grid.drop_waiting_shells()
		shells_grid.gravity_manager() 	
		shells_grid.move_falling_sprites()

	even_loop = !even_loop

func add_points(increment:int,pos_x:float=100.0,pos_y:float=100.0):
	# Increment the score by a specified amount
	score += increment
	if score_label:
		score_label.text = "%05d" % score  # Format score as 5-digit string with leading zeros

	var points_scene = load("res://scenes/points.tscn")
	var new_instance = points_scene.instantiate()
	add_child(new_instance)
	new_instance.initialize(increment, pos_x, pos_y)

	# Emit the points_added signal with the new points
	points_added.emit(increment,pos_x,pos_y)

func create_small_firework(x_arg,y_arg,shell_type_arg):
	print ("  -- Creating firework at [", x_arg, "][", y_arg, "]")
	var load_scene_one = load("res://scenes/small_firework.tscn")
	var new_instance = load_scene_one.instantiate()
	new_instance.position = Vector2(x_arg, y_arg)  # Set initial position
	add_child(new_instance) 
	new_instance.initialize(shell_type_arg)

func create_big_firework(column,top_row,bottom_row):
	# we create a dedicated array with the shells corresponding the fireworks. 
	var firework_shells = []
	for row in range(top_row, bottom_row - 1, -1):
		firework_shells.append(shells_grid.shells_grid[column][row])
		shells_grid.shells_grid[column][row] = null

	var new_big_firework = BigFirework.new(firework_shells)
	new_big_firework.connect("points_to_add", Callable(self, "add_points"))

	add_child(new_big_firework)

func game_over(column_arg,row_arg):
	print("Game Over! Final Score: ", score)
	set_player_pause()
	shells_grid.shells_grid[column_arg][row_arg].modulate = Color.GRAY # Tint the last shell gray
	for column in Globals.NUM_COLUMNS:
		for row in Globals.NUM_ROWS:
			if shells_grid.shells_grid[column][row] != null:
				var tween = create_tween()
				tween.tween_property(shells_grid.shells_grid[column][row], "modulate", Color.DARK_VIOLET, 0.3 * (Globals.NUM_ROWS - row))
	emit_signal("player_game_over")
