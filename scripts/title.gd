extends Node2D

# Background elements for animation
@onready var background_wall: Sprite2D = $BackgroundWall
@onready var background_mountains: Sprite2D = $BackgroundMountains

# UI elements for animation
@onready var ui: Control = %UI
@onready var pyropop_title: Sprite2D = $PyropopTitle

# Timer for repeating fireworks
var fireworks_timer: Timer

# UI Management system
var ui_manager: Node

# Cheat code system (Konami code: up, up, down, down, left, right, left, right)
var cheat_sequence: Array = [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT]
var current_input_sequence: Array = []
var cheat_timeout_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Set up initial states for animations
	setup_initial_states()
	
	# Start background animations
	animate_backgrounds()
	
	# Initialize cheat code timer
	setup_cheat_timer()

# Set up initial positions and visibility for animation elements
func setup_initial_states() -> void:
	
	# Make title sprite invisible initially
	pyropop_title.modulate.a = 0.0
	
	# Hide selection corners initially (handled by UI manager)
	#var selection = $Selection
	#selection.visible = false

# Animate both background elements and coordinate the sequence
func animate_backgrounds() -> void:
	# Create tweens for both background elements
	var wall_tween = create_tween()
	var mountains_tween = create_tween()
	
	# Set initial positions
	background_wall.position.y = -389
	
	# Animate both backgrounds simultaneously
	wall_tween.tween_property(background_wall, "position:y", -10, 4.0)
	mountains_tween.tween_property(background_mountains, "position:y", 0, 4.0)
	
	# When both tweens complete, animate the UI elements
	wall_tween.tween_callback(animate_ui_elements)

# Animate UI elements after background animations complete
func animate_ui_elements() -> void:
	# Create tweens for UI animations
	var menu_tween = create_tween()
	var title_tween = create_tween()
	
	# Bring the menu buttons from the bottom in 0.5 seconds
	%MainMenu.position = Vector2(207, 120)
	%MainMenu.z_index = -1
	
	menu_tween.tween_property(%MainMenu, "position:y", 12, 0.5)

	# Fade-in the title sprite (0.5 seconds)
	title_tween.tween_property(pyropop_title, "modulate:a", 1.0, 0.5)
	
	# When UI animations complete, notify the UI manager and launch fireworks
	title_tween.tween_callback(_on_ui_animations_complete)

# Called when UI animations are complete
func _on_ui_animations_complete() -> void:
	# Notify UI manager that animations are complete
	ui.on_ui_animations_complete()
	
	# Launch fireworks
	launch_fireworks()

# Launch celebratory fireworks after all animations complete
func launch_fireworks() -> void:
	print("Title: Launching fireworks!")
	
	# Create the first firework immediately
	create_firework()
	
	# Set up timer to repeat fireworks every 3 seconds
	if fireworks_timer == null:
		fireworks_timer = Timer.new()
		add_child(fireworks_timer)
		fireworks_timer.wait_time = randf_range(1.0, 2.0)
		fireworks_timer.one_shot = false  # Repeat continuously
		fireworks_timer.timeout.connect(create_firework)
		fireworks_timer.start()

# Create a single firework instance
func create_firework() -> void:
	var new_big_firework = BigFirework.new()
	add_child(new_big_firework)

# Setup cheat code timeout timer
func setup_cheat_timer() -> void:
	cheat_timeout_timer = Timer.new()
	add_child(cheat_timeout_timer)
	cheat_timeout_timer.wait_time = 2.0  # Reset sequence after 2 seconds of no input
	cheat_timeout_timer.one_shot = true
	cheat_timeout_timer.timeout.connect(_on_cheat_timeout)

# Handle input for cheat code detection and delegate to UI manager
func _input(event: InputEvent) -> void:
	# Handle cheat code input first
	if event is InputEventKey and event.pressed:
		# Add the key to current sequence
		current_input_sequence.append(event.keycode)
		
		# Restart the timeout timer
		cheat_timeout_timer.stop()
		cheat_timeout_timer.start()
		
		# Check if sequence is getting too long
		if current_input_sequence.size() > cheat_sequence.size():
			current_input_sequence.clear()
		
		# Check if we have the correct sequence
		if current_input_sequence.size() == cheat_sequence.size():
			if arrays_equal(current_input_sequence, cheat_sequence):
				activate_cheat()
			current_input_sequence.clear()
	
	# Delegate to UI manager
	if ui_manager and ui_manager.handle_input(event):
		get_viewport().set_input_as_handled()

# Reset cheat sequence on timeout
func _on_cheat_timeout() -> void:
	current_input_sequence.clear()

# Check if two arrays are equal
func arrays_equal(arr1: Array, arr2: Array) -> bool:
	if arr1.size() != arr2.size():
		return false
	for i in range(arr1.size()):
		if arr1[i] != arr2[i]:
			return false
	return true

# Activate the cheat code
func activate_cheat() -> void:
	print("CHEAT ACTIVATED: Maximum difficulty unlocked!")
	Globals.max_difficulty_level = Globals.IMPOSSIBLE_LEVEL
	# Optional: Add visual feedback
	pyropop_title.modulate = Color.GOLD
	var tween = create_tween()
	tween.tween_property(pyropop_title, "modulate", Color.WHITE, 1.0)

# Delegate process to UI manager for input cooldown
func _process(delta: float) -> void:
	if ui_manager:
		ui_manager.process_input(delta)

