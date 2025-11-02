extends Node

class_name TitleUIManagement

@onready var selection = %Selection

func _ready() -> void:
	# Connect focus_entered signal for all buttons in the menu_buttons group
	for button in get_tree().get_nodes_in_group("menu_button"):
		if button is BaseButton:
			button.focus_entered.connect(_on_menu_button_focus_changed)

func _on_menu_button_focus_changed() -> void:
	# Move selection corners to the focused button
	var focused_button = get_viewport().gui_get_focus_owner()
	if focused_button and focused_button is Button:
		selection.position = focused_button.global_position
		selection.visible = true


# Set initial focus on One Player vs CPU button
func set_initial_focus() -> void:
	%OnePlayerButton.grab_focus()

# Animation callback - called when UI animations complete
func on_ui_animations_complete() -> void:
	# Set initial focus after animations complete
	var focus_timer = Timer.new()
	get_parent().add_child(focus_timer)
	focus_timer.wait_time = 0.5  # Short delay after UI animations
	focus_timer.one_shot = true
	focus_timer.timeout.connect(set_initial_focus)
	focus_timer.start()




func _on_one_player_button_pressed() -> void:
	print("TitleUIManagement: One Player vs CPU selected - Starting transition to Game scene")
	# Start transition effect instead of immediate scene change
	# move the MenuButtons node offscreen to the top in 0.5 seconds
	selection.visible = false
	var move_tween =get_parent().create_tween()
	# Bring the menu buttons from the bottom in 0.5 seconds
	%OnePlayerMenu.position = Vector2(207, 120)
	%OnePlayerMenu.z_index = -1
	move_tween.tween_property(%MainMenu, "position:y", -120, 0.5)
	move_tween.tween_property(%OnePlayerMenu, "position:y", 4, 0.5)
	# when the tween is done, set focus to EasyButton
	move_tween.finished.connect(%EasyButton.grab_focus)

	#start_scene_transition("res://scenes/game.tscn")


func _on_two_players_button_pressed() -> void:
	print("TitleUIManagement: Two Players vs Player selected - Starting transition to Game scene")
	pass
	



func _on_back_pressed() -> void:
	print("TitleUIManagement: Back to main menu")
	selection.visible = false
	var move_tween =get_parent().create_tween()
	# Bring the menu buttons from the bottom in 0.5 seconds
	move_tween.tween_property(%OnePlayerMenu, "position:y", 120, 0.5)
	move_tween.tween_property(%MainMenu, "position:y", 4, 0.5)

	# when the tween is done, set focus to OnePlayerButton
	move_tween.finished.connect(%OnePlayerButton.grab_focus)


func _on_easy_button_pressed() -> void:
	Globals.difficulty_level = Globals.EASY_LEVEL
	# fade the scene to black over 0.5 seconds, then change to game scene
	print("TitleUIManagement: Easy difficulty selected - Starting transition to Game scene")
	var fade_tween = get_parent().create_tween()
	fade_tween.tween_property(get_parent(), "modulate:a", 0.0, 0.5)
	fade_tween.finished.connect(_start_game_scene)

func _start_game_scene() -> void:
	print("TitleUIManagement: Transition complete - Changing to Game scene")
	get_tree().change_scene_to_file("res://scenes/game.tscn")	
