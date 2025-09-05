extends Timer

# Reference to the timer display label
@onready var timer_label: Label = get_parent().get_node("GameTimerText")

# Timer state
var total_seconds: int = 180  # 2 minutes
var current_seconds: int = 180

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set up the timer to tick every second
	wait_time = 1.0
	one_shot = false
	autostart = true
	
	# Connect the timeout signal to our countdown function
	timeout.connect(_on_timer_timeout)
	
	# Initialize the display
	update_timer_display()

# Called every second when timer times out
func _on_timer_timeout() -> void:
	current_seconds -= 1
	update_timer_display()
	
	# Check for special time events
	if current_seconds == 175:  # 2'45 remaining
		_trigger_player1_grey_effect()
	
	# Check if time is up
	if current_seconds <= 0:
		stop()  # Stop the timer
		_on_time_up()

# Trigger grey effect on all player1 shells when timer reaches 2'45
func _trigger_player1_grey_effect() -> void:
	print("Game Timer: Triggering grey effect on Player 1 shells at 2'45")
	
	# Get reference to player manager 1
	var player_manager_1 = get_parent().get_parent().get_node("PlayerManager1")
	if player_manager_1 == null:
		print("Game Timer: Could not find PlayerManager1")
		return
	
	# Apply grey effect to all shells in player1's grid
	_apply_grey_effect_to_player(player_manager_1)

# Apply grey effect to all shells in a player's grid over 5 seconds
func _apply_grey_effect_to_player(player_manager: Node) -> void:
	print("Game Timer: Applying grey effect to player shells")
	
	# Access the shells grid directly from the player manager
	var shells_grid = player_manager.shells_grid
	
	# Create tween for the grey effect
	var grey_tween = create_tween()
	grey_tween.set_parallel(true)  # Allow multiple properties to animate simultaneously
	
	# Apply grey modulation to all shells in the grid
	for column in range(shells_grid.size()):
		for row in range(shells_grid[column].size()):
			var shell = shells_grid[column][row]
			if shell != null and shell.get_status() == shell.status.DROPPED:
				# Animate to grey color over 5 seconds
				grey_tween.tween_property(shell, "modulate", Color.BLACK, 0.5)

# Update the timer display text in MM'SS format
func update_timer_display() -> void:
	var minutes = int(current_seconds / 60)  # Convert to integer
	var seconds = current_seconds % 60
	var time_text = str("%d'%02d" % [minutes, seconds])
	timer_label.text = time_text

# Called when timer reaches 0'00
func _on_time_up() -> void:
	print("Game Timer: Time's up!")
	# TODO: Add game over logic or notify game manager
