extends Timer

# Reference to the timer display label
@onready var timer_label: Label = get_parent().get_node("GameTimerText")

# Timer state
var total_seconds: int = 180  
var current_seconds: int = total_seconds

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	# Initialize the display
	update_timer_display()

# Called every second when timer times out
func _on_timeout() -> void:
	current_seconds -= 1
	update_timer_display()
		
	# Check if time is up
	if current_seconds <= 0:
		stop()  # Stop the timer
		_on_time_up()

# Update the timer display text in MM'SS format
func update_timer_display() -> void:
	var minutes = int(current_seconds / 60)  # Convert to integer
	var seconds = current_seconds % 60
	var time_text = str("%d'%02d" % [minutes, seconds])
	timer_label.text = time_text


func _on_time_up() -> void:
	print("GameTimer: Time's up!")
