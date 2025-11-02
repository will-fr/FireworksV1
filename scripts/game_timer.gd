class_name GameTimer 
extends Timer


signal game_started
signal game_ended

# Reference to the timer display label
@onready var timer_label: Label = get_parent().get_node("GameTimerText")
@onready var countdown_1: CountDown = get_parent().get_parent().get_node("PlayerManager1").get_node("CountDown")
# 	emit_signal("countdown_finished")

# Timer state
var total_seconds: int = 180  
var current_seconds: int = total_seconds
var game_status: String = "stopped"  # "running", "paused", "stopped"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	# Initialize the display
	update_timer_display()
	countdown_1.connect("countdown_finished", Callable(self, "_on_countdown_finished"))

func _on_countdown_finished():
	start()  # Start the game timer when countdown finishes
	game_status = "running"
	emit_signal("game_started")
	print("GameTimer: Countdown finished, starting game timer.")

# Called every second when timer times out
func _on_timeout() -> void:
	current_seconds -= 1
	update_timer_display()
		
	# Check if time is up
	if current_seconds <= 0:
		stop()  # Stop the timer
		game_status = "stopped"
		_on_time_up()

# Update the timer display text in MM'SS format
func update_timer_display() -> void:
	var minutes = int(current_seconds / 60)  # Convert to integer
	var seconds = current_seconds % 60
	var time_text = str("%d:%02d" % [minutes, seconds])
	timer_label.text = time_text


func _on_time_up() -> void:
	print("GameTimer: Time's up!")
	emit_signal("game_ended")

func get_game_status() -> String:
	return game_status
