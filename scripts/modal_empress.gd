extends Node2D

var char_index: int = 0
var modal_text: String = ""
var any_key_text: String = ""
var next_scene: String = "res://scenes/title/title.tscn"

var winner: int = 0  # 1 for player 1 win, 2 for player 2 win

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# make sure that the modal content is initially hidden
	%ModalContent.visible = false
	%AnyKey.visible = false

	# make sure this scene has the highest z-index to appear above all else.
	z_index = 1000

	# Create a tween to make the black background fade in over 0.5 seconds
	%BlackBackground.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(%BlackBackground, "modulate:a", 0.7, 0.5)

	
	# When the tween is finished, we can show the modal content.
	tween.finished.connect(_show_modal_content)	

func set_text(winner_arg) -> void:
	# Set the full text based on the winner
	winner = winner_arg
	#todo: properly manager NUM_COLUMNS
	if (winner == 1):
		if (Globals.difficulty_level == Globals.EASY_LEVEL):
			modal_text = "That was EASY,  BUT\nTHE NEXT OPPONENT\nSHOULD BE A BETTER\nCHALLENGE FOR YOU"
			any_key_text = "Press any key to start the HARD challenge"
			next_scene = "res://scenes/game/game.tscn"
			Globals.difficulty_level = Globals.HARD_LEVEL
		elif (Globals.difficulty_level == Globals.HARD_LEVEL):
			modal_text = "You'RE GETTING BETTER ! \nBUT I'M SURE THE \nNEXT OPPONENT WILL \nOUTSMART YOU ! "
			any_key_text = "Press any key to start the LEGENDARY challenge"
			next_scene = "res://scenes/game/game.tscn"
			Globals.difficulty_level = Globals.LEGENDARY_LEVEL
		elif (Globals.difficulty_level == Globals.LEGENDARY_LEVEL):
			modal_text = "IMPRESSIVE ! ONLY ONE\nCHALLENGE LEFT TO\nPROVE YOU ARE THE\nFIREWORKS MASTER! "
			any_key_text = "Press any key to start the IMPOSSIBLE challenge"
			next_scene = "res://scenes/game/game.tscn"
			Globals.difficulty_level = Globals.IMPOSSIBLE_LEVEL
		elif (Globals.difficulty_level == Globals.IMPOSSIBLE_LEVEL):
			modal_text = "NO DOUBT, YOU ARE\nTHE FIREWORKS MASTER\nI WAS LOOKING FOR.\nTHANK YOU SO MUCH!"
			any_key_text = "Press any key to go to the title screen"
			next_scene = "res://scenes/title/title.tscn"
	else:
		modal_text = "You still have a lot\n to learn to become \na firework master"
		any_key_text = "Press any key to go to the title screen"
		next_scene = "res://scenes/title/title.tscn"

	# Update the max difficulty level if needed
	if (Globals.max_difficulty_level <= Globals.difficulty_level):
		Globals.max_difficulty_level = Globals.difficulty_level
	
func _show_modal_content() -> void:
	%ModalContent.visible = true
	%Modal.text = "" 
	%CharTimer.start()


	print("ModalEmpress: Showing modal content")
	print ("ModalEmpress: modal_text = ", modal_text)
	print ("ModalEmpress: any_key_text = ", any_key_text)
	print ("ModalEmpress: next_scene = ", next_scene)

func _on_char_timer_timeout() -> void:
	# Add the next character to the Modal label
	print("ModalEmpress: _on_char_timer_timeout called, char_index = ", char_index)
	print("ModalEmpress: adding character: ", modal_text[char_index] if char_index < modal_text.length() else "N/A")
	if char_index < modal_text.length():
		%Modal.text += modal_text[char_index]
		char_index += 1
	# if the text is complete, stop the timer
	else:
		%CharTimer.stop()
		%AnyKey.text = any_key_text
		%AnyKey.visible = true
		get_viewport().set_input_as_handled()  # Prevent immediate trigger


func _input(event: InputEvent) -> void:
	if %AnyKey.visible:
		if event.is_pressed():
			get_tree().change_scene_to_file(next_scene)
			
