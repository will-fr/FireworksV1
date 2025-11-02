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

# Handle when Player 1 loses - Player 2 wins
func _on_player1_game_over():
	display_winner(2)

# Handle when Player 2 loses - Player 1 wins  
func _on_player2_game_over():
	display_winner(1)

# When Player 1 scores, send junk to Player 2's board
func _on_player1_points_added(_points:int, pos_x:int, pos_y:int) -> void:
	player_manager_2.shells_grid.increase_junk(1, pos_x, pos_y)

# When Player 2 scores, send junk to Player 1's board
func _on_player2_points_added(_points:int, pos_x:int, pos_y:int) -> void:
	player_manager_1.shells_grid.increase_junk(1, pos_x, pos_y)

# Display the winner and handle end-game sequence
func display_winner(winner: int) -> void:
	# Pause both players to stop gameplay
	player_manager_1.set_player_pause()
	player_manager_2.set_player_pause()

	# Fade out background music smoothly
	background_music.stop()
	defeat_music.play()

	# Wait 1.5 seconds to let final effects play out
	await get_tree().create_timer(1.5).timeout

	# Position labels and play animations based on who won
	if winner == 1:
		# Player 1 wins - show "You Win" on left, "You Lose" on right
		win_label.position.x = 28
		lose_label.position.x = 210
		player_manager_1.player.skin_sprite.play("victory")
		player_manager_2.player.skin_sprite.play("defeat")
		
	elif winner == 2:
		# Player 2 wins - show "You Win" on right, "You Lose" on left
		win_label.position.x = 216
		lose_label.position.x = 8 
		# multiply both sprite size by 4 and put them in the front.
		player_manager_2.player.skin_sprite.scale = Vector2(2, 2)
		player_manager_1.player.skin_sprite.scale = Vector2(2, 2)
		# move the sprites so that their feet remains on the ground.
		player_manager_2.player.skin_sprite.position.y -= 16
		player_manager_1.player.skin_sprite.position.y -= 16
		player_manager_2.player.skin_sprite.z_index = 100
		player_manager_1.player.skin_sprite.z_index = 100
		player_manager_2.player.skin_sprite.play("victory")
		player_manager_1.player.skin_sprite.play("defeat")

	# Animate the labels moving to center screen
	_animate_labels_to_center()

	# after a short delay, we reset the game.

# Animate both win and lose labels to move down to the center of the screen
func _animate_labels_to_center():
	# Calculate the vertical center of the screen
	var screen_center_y = get_viewport().get_visible_rect().size.y / 2
	
	# Create tween animation for the win label moving to center
	var win_tween = create_tween()
	win_tween.tween_property(win_label, "position:y", screen_center_y, 5.0)
	# When animation completes, reload the scene to restart the game
	win_tween.tween_callback(_reload_scene)

	# Create tween animation for the lose label moving to center
	var lose_tween = create_tween()
	lose_tween.tween_property(lose_label, "position:y", screen_center_y, 5.0)

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

# Reload the current scene to restart the game
func _reload_scene():
	get_tree().reload_current_scene()
