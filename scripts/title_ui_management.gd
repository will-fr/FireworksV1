extends Node

class_name TitleUIManagement

# Button references
var p1_vs_p2_button: Button
var p1_vs_cpu_button: Button  
var settings_button: Button
var exit_button: Button
var menu_buttons: Control
var selection: Node2D

# Menu sound effects
var menu_sound_player: AudioStreamPlayer

# Input debouncing for joypad navigation
var input_cooldown: float = 0.0
var input_delay: float = 0.1  # 200ms cooldown between navigation inputs
var last_axis_direction: float = 0.0  # Track last analog stick direction

# Reference to the parent scene
var parent_scene: Node2D

# Initialize the UI management system
func initialize(scene_parent: Node2D) -> void:
	parent_scene = scene_parent
	
	# Get button references from parent scene
	p1_vs_p2_button = scene_parent.get_node("MenuButtons/P1vsP2Button")
	p1_vs_cpu_button = scene_parent.get_node("MenuButtons/P1vsCPUButton")
	settings_button = scene_parent.get_node("MenuButtons/SettingsButton")
	exit_button = scene_parent.get_node("MenuButtons/ExitButton")
	menu_buttons = scene_parent.get_node("MenuButtons")
	selection = scene_parent.get_node("Selection")
	
	# Set up menu sound effects
	setup_menu_sound()
	
	# Set up button functionality
	setup_joypad_navigation()
	connect_button_signals()
	connect_mouse_hover_signals()
	
	print("TitleUIManagement: Initialized successfully")

# Set up menu sound effects
func setup_menu_sound() -> void:
	# Create AudioStreamPlayer for menu sounds
	menu_sound_player = AudioStreamPlayer.new()
	parent_scene.add_child(menu_sound_player)
	
	# Load the menu change sound
	var menu_sound = load("res://gfx/sound/menu_change.wav")
	if menu_sound:
		menu_sound_player.stream = menu_sound
		menu_sound_player.volume_db = -5  # Adjust volume as needed
		print("TitleUIManagement: Menu sound loaded successfully")
	else:
		print("TitleUIManagement: Warning - Could not load menu_change.wav")

# Play menu change sound effect
func play_menu_change_sound() -> void:
	if menu_sound_player and menu_sound_player.stream:
		menu_sound_player.play()

# Set up joypad navigation for buttons
func setup_joypad_navigation() -> void:
	# Enable focus mode for all buttons
	p1_vs_p2_button.focus_mode = Control.FOCUS_ALL
	p1_vs_cpu_button.focus_mode = Control.FOCUS_ALL
	settings_button.focus_mode = Control.FOCUS_ALL
	exit_button.focus_mode = Control.FOCUS_ALL
	
	# Don't set focus_next/focus_previous - we'll handle navigation manually
	# This prevents conflicts between built-in focus system and our custom navigation
	
	print("TitleUIManagement: Joypad navigation setup complete")

# Set initial focus on P1 vs CPU button
func set_initial_focus() -> void:
	p1_vs_cpu_button.grab_focus()
	selection.visible = true  # Show selection corners
	update_selection_position()
	print("TitleUIManagement: Initial focus set to P1 vs CPU button")

# Handle input processing
func process_input(delta: float) -> void:
	# Handle input cooldown for joypad navigation
	if input_cooldown > 0:
		input_cooldown -= delta

# Handle joypad and keyboard input
func handle_input(event: InputEvent) -> bool:
	# Handle keyboard navigation (override default Tab behavior)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_UP:
				move_focus_up()
				return true
			KEY_DOWN:
				move_focus_down()
				return true
			KEY_TAB:
				if event.shift_pressed:
					move_focus_up()
				else:
					move_focus_down()
				return true
	
	# Handle joypad navigation
	elif event is InputEventJoypadButton:
		if event.pressed:
			match event.button_index:
				JOY_BUTTON_A:  # A button (confirm)
					var focused_button = get_focused_button()
					if focused_button == p1_vs_p2_button:
						_on_p1_vs_p2_pressed()
					elif focused_button == p1_vs_cpu_button:
						_on_p1_vs_cpu_pressed()
					elif focused_button == settings_button:
						_on_settings_pressed()
					elif focused_button == exit_button:
						_on_exit_pressed()
					return true
				JOY_BUTTON_B:  # B button (back/exit)
					_on_exit_pressed()
					return true
				JOY_BUTTON_DPAD_UP:
					if input_cooldown <= 0:
						move_focus_up()
						input_cooldown = input_delay
					return true
				JOY_BUTTON_DPAD_DOWN:
					if input_cooldown <= 0:
						move_focus_down()
						input_cooldown = input_delay
					return true
	
	# Handle joypad analog stick
	elif event is InputEventJoypadMotion:
		# Only process if cooldown has expired
		if input_cooldown <= 0:
			match event.axis:
				JOY_AXIS_LEFT_Y:
					var current_direction = 0.0
					if event.axis_value < -0.5:  # Up
						current_direction = -1.0
					elif event.axis_value > 0.5:  # Down
						current_direction = 1.0
					
					# Only trigger movement if direction changed from neutral or opposite
					if current_direction != 0 and current_direction != last_axis_direction:
						if current_direction < 0:
							move_focus_up()
						else:
							move_focus_down()
						input_cooldown = input_delay
						return true
					
					last_axis_direction = current_direction
	
	return false  # Input not handled

# Get the currently focused button
func get_focused_button() -> Button:
	if p1_vs_p2_button.has_focus():
		return p1_vs_p2_button
	elif p1_vs_cpu_button.has_focus():
		return p1_vs_cpu_button
	elif settings_button.has_focus():
		return settings_button
	elif exit_button.has_focus():
		return exit_button
	return null

# Move focus to the next button up
func move_focus_up() -> void:
	var focused = get_focused_button()
	if focused == p1_vs_cpu_button:
		exit_button.grab_focus()  # Wrap around to last
	elif focused == p1_vs_p2_button:
		p1_vs_cpu_button.grab_focus()
	elif focused == settings_button:
		p1_vs_p2_button.grab_focus()
	elif focused == exit_button:
		settings_button.grab_focus()
	
	# Play menu sound when focus changes
	play_menu_change_sound()
	update_selection_position()

# Move focus to the next button down
func move_focus_down() -> void:
	var focused = get_focused_button()
	if focused == p1_vs_cpu_button:
		p1_vs_p2_button.grab_focus()
	elif focused == p1_vs_p2_button:
		settings_button.grab_focus()
	elif focused == settings_button:
		exit_button.grab_focus()
	elif focused == exit_button:
		p1_vs_cpu_button.grab_focus()  # Wrap around to first
	
	# Play menu sound when focus changes
	play_menu_change_sound()
	update_selection_position()

# Update selection corners position based on focused button
func update_selection_position() -> void:
	var focused = get_focused_button()
	if focused == null:
		return
	
	# Get the focused button's position and size
	var button_rect = focused.get_global_rect()
	
	# Move the entire Selection node to match the button's position
	# This will move all 4 corner sprites as a group
	selection.global_position = button_rect.position

# Connect button signals to their handlers
func connect_button_signals() -> void:
	p1_vs_p2_button.pressed.connect(_on_p1_vs_p2_pressed)
	p1_vs_cpu_button.pressed.connect(_on_p1_vs_cpu_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	print("TitleUIManagement: Button signals connected")

# Connect mouse hover signals for focus-on-hover behavior
func connect_mouse_hover_signals() -> void:
	p1_vs_p2_button.mouse_entered.connect(_on_button_mouse_entered.bind(p1_vs_p2_button))
	p1_vs_cpu_button.mouse_entered.connect(_on_button_mouse_entered.bind(p1_vs_cpu_button))
	settings_button.mouse_entered.connect(_on_button_mouse_entered.bind(settings_button))
	exit_button.mouse_entered.connect(_on_button_mouse_entered.bind(exit_button))
	print("TitleUIManagement: Mouse hover signals connected")

# Called when mouse enters any button
func _on_button_mouse_entered(button: Button) -> void:
	# Only play sound if focus is actually changing to a different button
	var current_focused = get_focused_button()
	if current_focused != button:
		play_menu_change_sound()
	
	# Give focus to the button that the mouse entered
	button.grab_focus()
	# Update visual selection to match
	update_selection_position()
	print("TitleUIManagement: Mouse entered ", button.name, " - focus updated")

# Button event handlers
func _on_p1_vs_p2_pressed() -> void:
	print("TitleUIManagement: P1 vs P2 selected")
	# TODO: Implement P1 vs P2 functionality
	pass

func _on_p1_vs_cpu_pressed() -> void:
	print("TitleUIManagement: P1 vs CPU selected - Starting transition to Game scene")
	# Start transition effect instead of immediate scene change
	start_scene_transition("res://scenes/game.tscn")

func _on_settings_pressed() -> void:
	print("TitleUIManagement: Settings selected")
	# TODO: Implement settings functionality
	pass

func _on_exit_pressed() -> void:
	print("TitleUIManagement: Exit selected")
	# Quit the application
	parent_scene.get_tree().quit()

# Animation callback - called when UI animations complete
func on_ui_animations_complete() -> void:
	# Set initial focus after animations complete
	var focus_timer = Timer.new()
	parent_scene.add_child(focus_timer)
	focus_timer.wait_time = 0.5  # Short delay after UI animations
	focus_timer.one_shot = true
	focus_timer.timeout.connect(set_initial_focus)
	focus_timer.start()

# Create smooth transition effect when changing scenes
func start_scene_transition(scene_path: String) -> void:
	# Disable input during transition
	parent_scene.set_process_input(false)
	
	# Create a CanvasLayer to ensure overlay is on top of everything
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer value to be on top
	parent_scene.add_child(canvas_layer)
	
	# Create a black overlay for fade effect
	var transition_overlay = ColorRect.new()
	transition_overlay.color = Color.BLACK
	transition_overlay.modulate.a = 0.0  # Start transparent
	
	# Make it cover the entire screen
	transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Add to the canvas layer (ensures it's on top)
	canvas_layer.add_child(transition_overlay)
	
	print("TitleUIManagement: Starting transition overlay - should be visible now")
	
	# Create fade-out tween
	var fade_tween = parent_scene.create_tween()
	fade_tween.tween_property(transition_overlay, "modulate:a", 1.0, 1.0)
	
	# When fade-out completes, change scene
	fade_tween.tween_callback(_complete_scene_transition.bind(scene_path))

# Complete the scene transition after fade-out
func _complete_scene_transition(scene_path: String) -> void:
	print("TitleUIManagement: Transition complete - Loading scene: ", scene_path)
	parent_scene.get_tree().change_scene_to_file(scene_path)
