extends Node2D

signal expanded
signal currency_decreased
signal fully_expanded

@export var factory_resource: Factory

var tile
var is_destroyed = false
var curr_expansion_radius:int = 0
var surronding_tiles_arrays: Array[Array]
var all_affected_tiles: Array
var additional_tiles: Array
var water_polluting_direction: Vector2i
var has_fully_expanded: bool = false
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var expand_timer = $ExpandTimer
@onready var smoke_node = $Smoke
@onready var gpu_particles_2d = $GPUParticles2D


func _ready():
	animated_sprite_2d.sprite_frames = factory_resource.sprite_frames
	animated_sprite_2d.play("working")
	expand_timer.wait_time = factory_resource.expand_time
	expand_timer.timeout.connect(_on_expand_timer_timeout)
	expand_timer.start()
	smoke_node.modulate = factory_resource.smoke_particels_modulate
	gpu_particles_2d.modulate = factory_resource.smoke_particels_modulate
	gpu_particles_2d.modulate -= Color(0.5, 0.5, 0.5, 0.5)
	for pos in factory_resource.smoke_particles_positions:
		var smoke_particels = factory_resource.smoke_particelse.instantiate()
		smoke_particels.position = pos
		smoke_particels.amount = factory_resource.smoke_particels_amount
		smoke_particels.scale = Vector2(factory_resource.smoke_size, factory_resource.smoke_size)
		smoke_node.add_child(smoke_particels)

func destroy():
	is_destroyed = true
	expand_timer.queue_free()
	smoke_node.queue_free()
	animated_sprite_2d.play("destroyed")

func get_time_to_next_expansion():
	return expand_timer.get_time_left()

func _on_expand_timer_timeout():
	gpu_particles_2d.emitting = true
	if curr_expansion_radius < factory_resource.max_radius:
		if factory_resource.pollution_type == "water":
			expanded.emit(surronding_tiles_arrays[0], water_polluting_direction, tile, additional_tiles)
			if surronding_tiles_arrays[0].size() > 0:
				all_affected_tiles.append_array(surronding_tiles_arrays[curr_expansion_radius])
			else:
				curr_expansion_radius += 1
		else:
			expanded.emit(surronding_tiles_arrays[curr_expansion_radius], factory_resource.pollution_type)
			curr_expansion_radius += 1
	else:
		if not has_fully_expanded and not factory_resource.pollution_type == "water":
			has_fully_expanded = true
			fully_expanded.emit(surronding_tiles_arrays[factory_resource.max_radius-1])
		if factory_resource.pollution_type == "water":
			expanded.emit(all_affected_tiles, null, tile, additional_tiles)
		else:
			expanded.emit(surronding_tiles_arrays[factory_resource.max_radius-1], factory_resource.pollution_type)

func get_info():
	var info_array = []
	info_array.append("0 points in 1 second.")
	info_array.append(factory_resource.name)
	if factory_resource.pollution_type == "water":
		info_array.append("the entire river below it.")
		info_array.append("rivers next to it.")
	else:
		info_array.append("%s tile radius" % factory_resource.max_radius)
		info_array.append("currently %s tiles." % curr_expansion_radius)
	info_array.append(get_time_to_next_expansion())
	return info_array
