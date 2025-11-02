extends Node2D

var char_index: int = 0
var full_text: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# make sure that the modal content is initially hidden
	%ModalContent.visible = false

	# make sure this scene has the highest z-index to appear above all else.
	z_index = 1000

	# Create a tween to make the black background appear in 0.2 seconds. 
	var tween = create_tween()
	tween.tween_property($BlackBackground, "modulate:a", 1.0, 0.2)
	# When the tween is finished, we can show the modal content.
	tween.finished.connect(_show_modal_content)	


func _show_modal_content() -> void:
	print("ModalEmpress: Showing modal content")
	
	#we get the full text from the EmpressText label
	full_text = %EmpressText.text
	%EmpressText.text = ""  # Clear initial text
	
	# Show the modal content (e.g., winner text, buttons)
	%ModalContent.visible = true

	%CharTimer.start()




func _on_char_timer_timeout() -> void:
	# Add the next character to the EmpressText label
	if char_index < full_text.length():
		%EmpressText.text += full_text[char_index]
		char_index += 1
	# if the text is complete, stop the timer
	else:
		%CharTimer.stop()
		# Display the BackToTitleButton
		%BackToTitle.visible = true
		# if any key or button is pressed, go back to title
		get_viewport().set_input_as_handled()  # Prevent immediate trigger


func _input(event: InputEvent) -> void:
	if %BackToTitle.visible:
		if event.is_pressed():
			# Go back to the title screen
			get_tree().change_scene_to_file("res://scenes/title.tscn")
			print("ModalEmpress: Returning to title screen.")
