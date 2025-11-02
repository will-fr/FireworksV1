class_name CountDown extends Label

# Signal emitted when countdown is finished
signal countdown_finished

var countdown_numbers = [3, 2, 1,"Go"]
var current_index = 0
@onready var ding_sound : AudioStreamPlayer2D = %Ding

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start the countdown immediately
	start_countdown()

func start_countdown():
	print("CountDown: Starting countdown...")
	# Make sure the label is visible
	visible = true
	modulate.a = 1.0
	
	# Start with the first number
	show_next_number()

func show_next_number():
	if current_index < countdown_numbers.size():
		var number = countdown_numbers[current_index]
		text = str(number)
		print("CountDown: Showing number ", number)

		# if it's the last element, play the sound on an high note and louder
		if current_index == countdown_numbers.size() - 1:
			ding_sound.pitch_scale = 1.5  # Increase pitch for "Go!"
			ding_sound.volume_db = +3  # Reset volume to +3 dB
		

		ding_sound.play()
		
		# Reset opacity to full
		modulate.a = 1.0
		
		# Create fade out tween
		var fade_tween = create_tween()
		fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)  # Fade over 1.0 seconds
		
		# When fade completes, show next number or finish
		fade_tween.tween_callback(move_to_next_number)
		
		current_index += 1
	else:
		# Countdown finished
		finish_countdown()

func move_to_next_number():
	if current_index < countdown_numbers.size():
		# Show the next number after a brief pause
		var pause_timer = Timer.new()
		add_child(pause_timer)
		pause_timer.wait_time = 0.2  # Brief pause between numbers
		pause_timer.one_shot = true
		pause_timer.timeout.connect(show_next_number)
		pause_timer.start()
	else:
		finish_countdown()

func finish_countdown():
	print("CountDown: Countdown finished!")
	text = ""  # Clear the text
	visible = false  # Hide the label
	
	# Emit the signal that countdown is done
	emit_signal("countdown_finished")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
