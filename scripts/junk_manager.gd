class_name JunkManager extends Node2D

@onready var shells_grid: ShellsGrid = get_parent().get_node("ShellsGrid")
@onready var player_manager: PlayerManager = get_parent()
@onready var junk_manager: JunkManager = get_parent().get_node("JunkManager")
@onready var junk_manager_x: float = junk_manager.global_position.x
@onready var junk_manager_y: float = junk_manager.global_position.y
var nb_junk:int = 0

# maximum junk allowed
var max_junk:int = 6
# create a junk array the size of max_junk
var junk_array: Array = []



func increase_junk(points, firework_global_position:Vector2):
	print ("JunkManager: increase_junk called with points=", points, " firework_global_position=", firework_global_position)

	nb_junk =shells_grid.get_total_junk()



	# add the junk scenes at the specified position
	var junk_scene = preload("res://scenes/junk.tscn").instantiate()
	get_parent().add_child(junk_scene)
	junk_scene.global_position = firework_global_position
	junk_scene.z_index = 100


	# add junk only if we are not at max AND push the sprite in the junk_array
	if nb_junk <= max_junk:
		shells_grid.increase_junk(1)
		junk_array.append(junk_scene)

	# define the target position of the junk manager
	var target_position_x = junk_manager_x + 10 * nb_junk
	var target_position_y = junk_manager_y

	#move the junk scene towards the junk manager at 10,10	
	var tween = create_tween()
	tween.tween_property(junk_scene, "global_position", Vector2(target_position_x, target_position_y), 1.0)

	# if we have more than max, remove this junk when the tween is finished, call the tween_completed function
	if nb_junk > max_junk:
		tween.tween_callback(_on_tween_completed.bind(junk_scene))


func _on_tween_completed(junk_scene):
	junk_scene.queue_free()


func decrease_junk_visuals(amount:int):
	print("JunkManager: decrease_junk_visuals called with amount=", amount)
	for i in range(amount):
		# get the last element from junk_array and remove it
		if junk_array.size() > 0:
			var junk_to_remove = junk_array.pop_back()
			junk_to_remove.queue_free()
			print ("JunkManager: decrease_junk_visuals removed junk=", junk_to_remove.name)
