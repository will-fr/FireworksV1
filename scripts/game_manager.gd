# GameManager - Main controller for game state and player interactions
# Handles game over conditions, scoring, victory effects, and scene management
class_name GameManager  extends Node2D

# References to the two player managers that control each player's game state
@onready var player_manager_1 = get_parent().get_node("PlayerManager1")
@onready var player_manager_2 = get_parent().get_node("PlayerManager2")

# UI labels for displaying game results
@onready var win_label = get_parent().get_node("Gui").get_node("WinLabel")
@onready var lose_label = get_parent().get_node("Gui").get_node("LoseLabel")


# Sounds & Music

@onready var background_music: AudioStreamPlayer2D = %BackgroundMusic
@onready var victory_music: AudioStreamPlayer2D = %VictoryMusic
@onready var defeat_music: AudioStreamPlayer2D = %DefeatMusic

# Initialize the game manager and connect to player events
func _ready() -> void:
	# Connect to player game over signals to detect when someone loses
	player_manager_1.connect("player_game_over", Callable(self, "_on_player1_game_over"))
	player_manager_2.connect("player_game_over", Callable(self, "_on_player2_game_over"))
	
	# Connect to scoring signals to handle junk sending between players
	player_manager_1.connect("points_added", Callable(self, "_on_player1_points_added"))
	player_manager_2.connect("points_added", Callable(self, "_on_player2_points_added"))

	# Wait for the next frame to ensure all @onready variables are initialized
	await get_tree().process_frame
	
	# set difficulty settings after all nodes are ready
	set_difficulty_settings()

	# debug: wait 5 seconds and then trigger a win for player 1
	# if (Globals.difficulty_level == Globals.EASY_LEVEL):
	# 	await get_tree().create_timer(5.0).timeout
	# 	player_manager_2.game_over()

func set_difficulty_settings() -> void:
	# Safety check to ensure player_manager_2 and its player are valid
	if player_manager_2 == null:
		print("GameManager: ERROR - player_manager_2 is null")
		return
	
	if player_manager_2.player == null:
		print("GameManager: ERROR - player_manager_2.player is null")
		return
	
	print("GameManager: Setting difficulty level: ", Globals.difficulty_level)
	
	match Globals.difficulty_level:
		Globals.EASY_LEVEL:
			player_manager_1.get_node("PlayerTimer").wait_time = 0.5
			player_manager_2.get_node("CpuLagTimer").wait_time = 1.0
			print("GameManager: Set EASY difficulty - CPU lag: 1.0")
		Globals.HARD_LEVEL:
			player_manager_1.get_node("PlayerTimer").wait_time = 0.4
			player_manager_2.get_node("CpuLagTimer").wait_time = 0.4
			print("GameManager: Set HARD difficulty - CPU lag: 0.4")
		Globals.LEGENDARY_LEVEL:
			player_manager_1.get_node("PlayerTimer").wait_time = 0.3
			player_manager_2.get_node("CpuLagTimer").wait_time = 0.1
			print("GameManager: Set LEGENDARY difficulty - CPU lag: 0.1")
		Globals.IMPOSSIBLE_LEVEL:
			player_manager_1.get_node("PlayerTimer").wait_time = 0.05
			player_manager_2.get_node("CpuLagTimer").wait_time = 0.05
			print("GameManager: Set IMPOSSIBLE difficulty - CPU lag: 0.05")

# Handle when Player 1 loses - Player 2 wins
func _on_player1_game_over():
	display_winner(2)

# Handle when Player 2 loses - Player 1 wins  
func _on_player2_game_over():
	display_winner(1)

# When Player 1 scores, send junk to Player 2's board
func _on_player1_points_added(points:int, firework_global_position:Vector2) -> void:
	player_manager_2.junk_manager.increase_junk(points, firework_global_position)

# When Player 2 scores, send junk to Player 1's board
func _on_player2_points_added(points:int, firework_global_position:Vector2) -> void:
	player_manager_1.junk_manager.increase_junk(points, firework_global_position)

# Display the winner and handle end-game sequence
func display_winner(winner: int) -> void:
	# Pause both players to stop gameplay
	player_manager_1.set_player_pause()
	player_manager_2.set_player_pause()
	
	# Wait 1.5 seconds to let final effects play out
	await get_tree().create_timer(1.5).timeout

	# Position labels and play animations based on who won
	if winner == 1:
		# Player 1 wins - show "You Win" on left, "You Lose" on right
		win_label.position.x = 34
		lose_label.position.x = 220
		player_manager_1.player.skin_sprite.play("victory")
		player_manager_2.player.skin_sprite.play("defeat")
		victory_music.play()
		victory_music.finished.connect(_show_game_over_modal.bind(winner), CONNECT_ONE_SHOT)
		
	elif winner == 2:
		# Player 2 wins - show "You Win" on right, "You Lose" on left
		win_label.position.x = 226
		lose_label.position.x = 25
		player_manager_2.player.skin_sprite.z_index = 100
		player_manager_1.player.skin_sprite.z_index = 100
		player_manager_2.player.skin_sprite.play("victory")
		player_manager_1.player.skin_sprite.play("defeat")
		defeat_music.play()
		defeat_music.finished.connect(_show_game_over_modal.bind(winner), CONNECT_ONE_SHOT)

	# Animate the labels moving to center screen
	_animate_labels_to_center()

	# after a short delay, we reset the game.

# Animate both win and lose labels to move down to the center of the screen
func _animate_labels_to_center():
	# Calculate the vertical center of the screen
	var screen_center_y = get_viewport().get_visible_rect().size.y / 2
	
	# Create tween animation for the win label moving to center
	var win_tween = create_tween()
	win_tween.tween_property(win_label, "position:y", 72, 5.0)
	# When animation completes, reload the scene to restart the game

	# Create tween animation for the lose label moving to center
	var lose_tween = create_tween()
	lose_tween.tween_property(lose_label, "position:y", 72, 5.0)

# Create a big firework effect to celebrate victory
func create_victory_firework(color_tint: int, fw_x: float, fw_y: float):
	# Load the big firework effect scene
	var effect_scene = load("res://scenes/big_firework/big_firework_effect.tscn")
	var effect_instance = effect_scene.instantiate()
	
	# Initialize with specified color (2=green, 3=blue, etc.)
	effect_instance.initialize(color_tint)
	
	# Position the firework at the specified coordinates
	effect_instance.position = Vector2(fw_x, fw_y)
	
	# Add to the scene tree to display the effect
	add_child(effect_instance)

func _show_game_over_modal(winner:int):
	print("GameManager: Showing game over modal for winner: ", winner)
	var modal_scene = load("res://scenes/modal_empress.tscn")
	var modal_instance = modal_scene.instantiate()
	modal_instance.set_text(winner)
	
	# Initialize the modal with the winner information
	#modal_instance.initialize(winner)
	
	# Add the modal to the scene tree
	get_parent().add_child(modal_instance)
