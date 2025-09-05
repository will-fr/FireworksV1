extends Node2D

var lantern_lights: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Find all PointLight2D nodes in the "lantern" group
	find_lantern_lights()
	# Start flickering effect for each lantern light
	start_lantern_flickering()

func find_lantern_lights():
	# Get all nodes in the "lantern" group
	var lantern_nodes = get_tree().get_nodes_in_group("lantern")
	
	# Filter for PointLight2D nodes only
	for node in lantern_nodes:
		if node is PointLight2D:
			lantern_lights.append(node)
			print("Background: Found lantern light - ", node.name)
	
	print("Background: Found ", lantern_lights.size(), " lantern lights to flicker")

func start_lantern_flickering():
	# Create individual flickering for each lantern light
	for i in range(lantern_lights.size()):
		var light = lantern_lights[i]
		create_lantern_flicker(light, i)

func create_lantern_flicker(light_node: PointLight2D, index: int):
	if light_node == null:
		return
		
	print("Background: Starting subtle flicker for lantern ", light_node.name)
	
	# Store the original energy value
	var original_energy = light_node.energy
	
	# Create a timer for this specific lantern with slight offset
	var flicker_timer = Timer.new()
	add_child(flicker_timer)
	
	# Each lantern has slightly different timing to create natural variation
	var base_interval = randf_range(1.0, 2.5)  # Slower, more subtle timing
	var time_offset = index * 0.3  # Offset to prevent synchronization
	
	flicker_timer.wait_time = base_interval + time_offset
	flicker_timer.timeout.connect(_flicker_lantern.bind(light_node, flicker_timer, original_energy))
	flicker_timer.start()

func _flicker_lantern(light_node: PointLight2D, timer: Timer, original_energy: float):
	if light_node == null or !is_instance_valid(light_node):
		timer.queue_free()
		return
	
	# Create very subtle energy variation (only 10-20% change)
	var flicker_intensity = randf_range(0.1, 2) * original_energy
	
	# Smooth transition to flickered state and back
	var tween = create_tween()
	tween.tween_property(light_node, "energy", flicker_intensity, 0.15)
	tween.tween_property(light_node, "energy", original_energy, 0.15)
	
	# Set random time for next flicker (longer intervals for subtlety)
	timer.wait_time = randf_range(1.5, 4.0)
	timer.start()
