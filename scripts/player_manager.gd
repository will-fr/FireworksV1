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
@onready var junk_manager : JunkManager = get_node("JunkManager")
@onready var score_label: Label = get_node("Score")  
#@onready var junk_label: Label = get_node("Junk")  
@onready var countdown: CountDown = get_node("CountDown")  
@onready var shells_grid: ShellsGrid = get_node("ShellsGrid")
@export var skin:String = "girl"
#todo : leverage this to indicate if left or right player
@export var is_left_player: bool = true

func _ready() -> void:
	# connect the signals. 
	player.player_flipped.connect(_on_player_flip)
	player.gravity_forced.connect(_on_player_forced_gravity)
	player.player_lifted.connect(_on_player_lifted)
	player.player_dropped.connect(_on_player_dropped)
	countdown.connect("countdown_finished", Callable(self, "_on_countdown_finished"))

	# setup the elements depending on the skin. 
	player.set_skin(skin)
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
	if shells_grid == null:
		print("PlayerManager: Error - shells_grid is null!")
		return []
	if shells_grid.shells_grid == null:
		print("PlayerManager: Error - shells_grid.shells_grid is null!")
		return []
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

func add_points(increment:int,firework_global_position:Vector2) -> void:
	# Increment the score by a specified amount
	score += increment
	if score_label:
		score_label.text = "%05d" % score  # Format score as 5-digit string with leading zeros

	var points_scene = load("res://scenes/points.tscn")
	var new_instance = points_scene.instantiate()
	add_child(new_instance)
	new_instance.initialize(increment, firework_global_position)

	# Emit the points_added signal with the new points
	points_added.emit(increment, firework_global_position)

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

func game_over(column_arg=0,row_arg=0):
	print("Game Over! Final Score: ", score)
	set_player_pause()

	# emit the game over signal
	emit_signal("player_game_over")

	# fade out the main background music in 2 seconds.
	var background_music : AudioStreamPlayer2D = %BackgroundMusic
	# create a tween to fade out the music
	var music_tween = create_tween()
	music_tween.tween_property(background_music, "volume_db", -80, 2.0)

	# Immediately turn the triggering shell gray and play sound
	shells_grid.shells_grid[column_arg][row_arg].modulate = Color.GRAY
	var block_to_gray_sound : AudioStreamPlayer2D = %BlockToGray
	block_to_gray_sound.play()
	
	# Start sequential row graying animation
	start_row_graying_animation()
	
func start_row_graying_animation():
	# Create a sequential tween for each row
	var main_tween = create_tween()
	
	# Process each row from top to bottom (NUM_ROWS-1 down to 0)
	for i in range(Globals.NUM_ROWS):
		var row = Globals.NUM_ROWS - 1 - i  # Start from top row (7) down to bottom row (0)
		
		# Add 0.2 second delay before processing this row
		if i > 0:  # No delay for the first row
			main_tween.tween_interval(0.2)
		
		# Turn all shells in this row gray and play sound
		main_tween.tween_callback(func(): turn_row_gray(row))

func turn_row_gray(row: int):
	var has_shells_in_row = false
	
	# Turn all shells in this row gray
	for column in range(Globals.NUM_COLUMNS):
		if shells_grid.shells_grid[column][row] != null:
			shells_grid.shells_grid[column][row].modulate = Color.DARK_GOLDENROD
			has_shells_in_row = true
	
	# Play sound only if there were shells in this row
	if has_shells_in_row:
		var block_to_gray_sound : AudioStreamPlayer2D = %BlockToGray
		if block_to_gray_sound:
			block_to_gray_sound.play()
