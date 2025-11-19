class_name BigFirework extends Node2D

signal firework_completed(type: int, colors: Array)
signal points_to_add (additional_points: int, firework_global_position: Vector2)


#var player_manager 
var is_title_firework: bool = false
var firework_shells : Array = []
var position_x: float
var initial_y: float= 145.0 # initial position of the tail, outside the screen.
var target_y: float
var destroy_timer: Timer

func _init(firework_shells_arg=null):
	
	# if the firework shells are not provided, this is because we are creating a random firework for the title screen.
	if firework_shells_arg == null:
		firework_shells = _create_random_firework()
		position_x = randf_range(30, 290 )
		target_y = randf_range(50, 80 )
		z_index = -1
		_create_and_animate_tail()
		is_title_firework = true
	else:
		print("Firework shells created: ", firework_shells_arg)
		firework_shells = firework_shells_arg

		# we mark the top shell as being dropped, and light the bottom shell, with a connector on bottom shell's animation.
		firework_shells[0].set_status(Shell.status.DROPPED)
		firework_shells[-1].play("1_light")
		firework_shells[-1].animation_finished.connect(_on_big_rocket_assembled)

		# position the firework on the other side of the screen depending on which player created it.
		position_x = firework_shells[0].position.x + 8
		print ("BigFirework: init at position : X = : ", position_x, " Y = ", initial_y)		
		target_y = randf_range(50, 80 )
	
# This function creates a random firework. Useful for title screen. 
func _create_random_firework():
	var fireworks_shells_rand = []
	var load_scene_one = load("res://scenes/entities/shells/shell.tscn")

	for i in range(2):
		var new_instance = load_scene_one.instantiate()
		# Generate random shell type, but ensure top and bottom are correct
		var shell_type: int
		if i == 0:
			shell_type = Globals.TOP_SHELL
		elif i == 4:
			shell_type = Globals.BOTTOM_SHELL
		else:
			shell_type = Globals.YELLOW
			
		print("Random Shell, i=", i, ", shell_type=", shell_type)
		
		# Position the shell correctly in the stack (16 pixels apart)
		new_instance.position = Vector2(64, 145 - (i * 16))
		
		# Initialize the shell with the correct parameters
		new_instance.initialize(i, shell_type)
		fireworks_shells_rand.append(new_instance)

		#add_child(new_instance) 

	return fireworks_shells_rand


# Event called when a shell finishes converging
func _on_big_rocket_assembled():

	# we make sure this is destroyed after a certain amount of time. 
	start_destroy_timer()

	print ("  -- Rocket assembled ")
	#player_manager.set_player_play()
	firework_shells[-1].play("1_fly")
	print ("  -- fireworks shell : ", firework_shells)
	
	# Create flashing effect for all shells in the rocket
	create_flashing_effect()

func create_flashing_effect():
	print("BigFirework: Creating flashing effect for rocket shells")
	
	# Create flashing tween for each shell
	for i in range(firework_shells.size()):
		var shell = firework_shells[i]
		var flash_tween = create_tween()
		flash_tween.set_loops(3)  # Flash 3 times
		
		# Flash by modulating between normal and bright white
		flash_tween.tween_property(shell, "modulate", Color.WHITE * 2.0, 0.05)  # Bright flash
		flash_tween.tween_property(shell, "modulate", Color.WHITE, 0.05)  # Back to normal
	
	# Wait for flashing to complete before launching
	var launch_timer = Timer.new()
	add_child(launch_timer)
	launch_timer.wait_time = 0.2  # Wait for 3 flashes to complete
	launch_timer.one_shot = true
	launch_timer.timeout.connect(launch_rocket_shells)
	launch_timer.start()

# Launch the rocket shells upwards and make it disappear from the screen.
func launch_rocket_shells():
	print("BigFirework: Launching rocket shells after flashing")
	
	for i in range(firework_shells.size()):
		print ("    -- launching tween")
		firework_shells[i].z_index = 100  # Bring to front
		var tween = create_tween()
		tween.tween_property(firework_shells[i], "position:y", firework_shells[i].position.y - 200, 0.5)
		if i == firework_shells.size() - 1:
			firework_completed.emit(1, firework_shells)
			tween.finished.connect(_create_and_animate_tail)

func _create_and_animate_tail():
	# Create an instance of the big_firework_tail scene
	var tail_scene = load("res://scenes/entities/fireworks/big_firework_tail.tscn")
	var tail_instance = tail_scene.instantiate()
	
	# Place it at the starting position (252, 207)
	tail_instance.position = Vector2(position_x, initial_y)
	add_child(tail_instance)
	
	# Create a tween to move it up to (252, 50) in 0.8 seconds
	var tween = create_tween()
	tween.tween_property(tail_instance, "position:y", target_y, 0.8)

	# After the movement, make it disappear
	tween.tween_callback(_make_tail_disappear.bind(tail_instance))

func _make_tail_disappear(tail_instance: Node):
	if tail_instance != null and is_instance_valid(tail_instance):
		tail_instance.queue_free()
	_create_firework_bouquet()


func _create_firework_bouquet():	
	# Create fireworks with staggered timing
	var delay = 0.1
	var new_x = position_x
	var new_y = target_y

	# remove the first element from firework_shells array (bottom_shell)
	# so that we don't do 2 fireworks for the smallest one. 
	firework_shells.remove_at(0)

	for i in firework_shells.size():
		var shell = firework_shells[i]

		if shell.shell_type == Globals.TOP_SHELL or shell.shell_type == Globals.BOTTOM_SHELL:
			break
		# Create a timer for each firework with increasing delay
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = delay
		timer.one_shot = true
		timer.timeout.connect(_create_individual_firework.bind(i,shell.get_shell_type(), new_x, new_y))
		timer.start()
		
		# Place it at the final position where the tail disappeared with random offset
		new_x = position_x + randi() % 60 - 30  # Random offset between -30 and +30
		new_y = target_y + randi() % 30 - 15  # Random offset between -15 and +15
		delay += 0.4  # Increase delay for next firework


func _create_individual_firework(shell_rank,color_tint,fw_x,fw_y):
	# Create an instance of the big_firework_effect scene
	var effect_scene = load("res://scenes/entities/fireworks/big_firework_effect.tscn")
	var effect_instance = effect_scene.instantiate()
	effect_instance.initialize(color_tint)
	effect_instance.position = Vector2(fw_x, fw_y)
	add_child(effect_instance)

	var additional_points=Globals.FIREWORK_SCORE[shell_rank]
	points_to_add.emit(additional_points, effect_instance.global_position)
	
	# Create shaking effect for the other player ! 

	create_screen_shake()

func create_screen_shake():
	# Skip screen shake for title screen fireworks
	if is_title_firework:
		print("BigFirework: Skipping screen shake for title firework")
		return
	
	# Find the current player_manager (the one who created this firework)
	var current_player_manager = get_parent()
	if current_player_manager == null or current_player_manager is not PlayerManager:
		print("BigFirework: No parent PlayerManager found for screen shake")
		return
	
	# Find the GameManager to get access to both players
	var game_manager = current_player_manager.get_parent().get_node("GameManager")
	if game_manager == null:
		print("BigFirework: GameManager not found")
		return
	
	# Determine which player to shake (the OTHER player)
	var target_player_manager = null
	if current_player_manager.name == "PlayerManager1":
		target_player_manager = current_player_manager.get_parent().get_node("PlayerManager2")
	elif current_player_manager.name == "PlayerManager2":
		target_player_manager = current_player_manager.get_parent().get_node("PlayerManager1")
	
	if target_player_manager == null:
		print("BigFirework: Could not find target player manager")
		return
	
	print("BigFirework: Creating screen shake effect on OTHER player: ", target_player_manager.name)
	
	# Store original position
	var original_position = target_player_manager.position
	print("BigFirework: Original position stored - ", original_position)
	
	# Create shake tween without loops to have better control
	var shake_tween = create_tween()
	
	# Generate and apply individual shake steps
	var shake_intensity = 2  # Pixels to shake
	var shake_duration = 0.05  # Duration of each shake
	
	# Create 6 individual shake movements
	for i in range(6):
		var random_x = randf_range(-shake_intensity, shake_intensity)
		var random_y = randf_range(-shake_intensity, shake_intensity)
		var shake_offset = Vector2(random_x, random_y)
		
		shake_tween.tween_property(target_player_manager, "position", original_position + shake_offset, shake_duration)
	
	# Ensure we return to exact original position at the end
	shake_tween.tween_property(target_player_manager, "position", original_position, shake_duration)
	
	# Add callback to confirm position reset
	shake_tween.tween_callback(_confirm_position_reset.bind(target_player_manager, original_position))

func _confirm_position_reset(target_player_manager: Node, original_position: Vector2):
	print("BigFirework: Shake complete, confirming position reset")
	print("BigFirework: Current position - ", target_player_manager.position)
	print("BigFirework: Target position - ", original_position)
	
	# Force exact position if there's any drift
	target_player_manager.position = original_position
	print("BigFirework: Position forcibly reset to original")


# Start a 5-second timer to call destroy_me function
func start_destroy_timer():
	print ("Starting Destroy Timer")
	destroy_timer = Timer.new()
	add_child(destroy_timer)
	destroy_timer.wait_time = 5  # 5 seconds
	destroy_timer.one_shot = true
	destroy_timer.timeout.connect(destroy_me)
	destroy_timer.start()

# Destroy this firework launcher after cleanup
func destroy_me():
	print("DESTROY ME CALLED")
	#we remove the sprites once they're off screen. 
	for i in range(firework_shells.size()):
		firework_shells[i].queue_free()	
	# Queue this node for deletion
	queue_free()         
