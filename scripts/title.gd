extends Node2D

# Background elements for animation
@onready var background_wall: Sprite2D = $BackgroundWall
@onready var background_mountains: Sprite2D = $BackgroundMountains

# UI elements for animation
@onready var menu_buttons: Control = $MenuButtons
@onready var pyropop_title: Sprite2D = $PyropopTitle

# Timer for repeating fireworks
var fireworks_timer: Timer

# UI Management system
var ui_manager: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize UI management system
	ui_manager = preload("res://scripts/title_ui_management.gd").new()
	add_child(ui_manager)
	ui_manager.initialize(self)
	
	# Set up initial states for animations
	setup_initial_states()
	
	# Start background animations
	animate_backgrounds()

# Set up initial positions and visibility for animation elements
func setup_initial_states() -> void:
	# Hide menu buttons off-screen to the right
	menu_buttons.position.x = 400  # Move off-screen to the right
	
	# Make title sprite invisible initially
	pyropop_title.modulate.a = 0.0
	
	# Hide selection corners initially (handled by UI manager)
	var selection = $Selection
	selection.visible = false

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
	
	# Quickly bring menu buttons from right side (0.5 seconds)
	menu_tween.tween_property(menu_buttons, "position:x", 205, 0.5)
	
	# Fade-in the title sprite (0.5 seconds)  
	title_tween.tween_property(pyropop_title, "modulate:a", 1.0, 0.5)
	
	# When UI animations complete, notify the UI manager and launch fireworks
	title_tween.tween_callback(_on_ui_animations_complete)

# Called when UI animations are complete
func _on_ui_animations_complete() -> void:
	# Notify UI manager that animations are complete
	ui_manager.on_ui_animations_complete()
	
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

# Delegate input handling to UI manager
func _input(event: InputEvent) -> void:
	if ui_manager and ui_manager.handle_input(event):
		get_viewport().set_input_as_handled()

# Delegate process to UI manager for input cooldown
func _process(delta: float) -> void:
	if ui_manager:
		ui_manager.process_input(delta)
