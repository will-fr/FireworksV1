class_name BigFirework extends Node2D

var position_x: float
var target_y: float
var initial_y: float= 207.0  # initial position of the tail, outside the screen.
var fireworks_colors: Array
var side_fw: String




func initialize(fireworks_colors_arg, side_fw_arg):
	# Initialize the firework with the given colors and player type
	self.fireworks_colors = fireworks_colors_arg
	self.side_fw = side_fw_arg

	if side_fw == "left":
		position_x = randf_range(32, 120)
	elif side_fw == "right":
		position_x = randf_range(232, 310)
	else:
		return

	z_index = -1
	target_y = randf_range(50, 80 )

	_create_and_animate_tail()



func _create_and_animate_tail():
	# Create an instance of the big_firework_tail scene
	var tail_scene = load("res://scenes/big_firework/big_firework_tail.tscn")
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
		tail_instance.visible = false
		# Optional: Remove it completely after hiding
		tail_instance.queue_free()
	_create_firework_bouquet()


func _create_firework_bouquet():
	if fireworks_colors.size() == 0:
		_create_individual_firework(0,position_x , target_y)
		return

	# Create fireworks with staggered timing
	var delay = 0.05
	var new_x = position_x
	var new_y = target_y
	for color_tint in fireworks_colors:
		#we ensure that the first one is launched on the tail. 

		# Create a timer for each firework with increasing delay
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = delay
		timer.one_shot = true
		timer.timeout.connect(_create_individual_firework.bind(color_tint, new_x, new_y))
		timer.start()
		
		delay += 0.2  # Increase delay by 0.1 seconds for next firework

		# Place it at the final position where the tail disappeared with random offset
		new_x = 64 + randi() % 96 - 48  # Random offset between -30 and +30
		new_y = target_y + randi() % 60 - 30  # Random offset between -15 and +15



func _create_individual_firework(color_tint,fw_x,fw_y):
	# Create an instance of the big_firework_effect scene
	var effect_scene = load("res://scenes/big_firework/big_firework_effect.tscn")
	var effect_instance = effect_scene.instantiate()
	effect_instance.initialize(color_tint)
	effect_instance.position = Vector2(fw_x, fw_y)
	add_child(effect_instance)

func _on_effect_finished():
	queue_free()
