extends Node2D

signal has_grown(affected_tiles: Array, name: String)
signal generated_currency(amount: int)
signal game_lost(lost_message: String)

@export var plant_resource: Plant

var growth_state = 0
var tile:
	set(value):
		tile = value
		$GPUParticles2D.process_material.set_shader_parameter("position", position)
var surronding_tiles_arrays: Array
var all_affected_tiles_pos: Array:
	set(value):
		all_affected_tiles_pos = value
		$GPUParticles2D.process_material.set_shader_parameter("destinations", value)
		$GPUParticles2D.process_material.set_shader_parameter("tile_count", value.size())
var do_not_emit = false

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var currency_timer: Timer = $CurrencyTimer
@onready var growth_timer: Timer = $GrowthTimer
@onready var gpu_particles_2d = $GPUParticles2D


func _ready():
	if plant_resource.is_prime:
		animated_sprite_2d.scale = Vector2(1.5, 1.5)
	elif plant_resource.name == "Fern":
		animated_sprite_2d.scale = Vector2(1, 1)
		do_not_emit = true
	animated_sprite_2d.sprite_frames = plant_resource.sprite_frames
	animated_sprite_2d.position = plant_resource.starting_pos
	currency_timer.wait_time = plant_resource.currency_production_time
	currency_timer.timeout.connect(_on_currency_timer_timeout)
	growth_timer.wait_time = plant_resource.growth_time
	growth_timer.timeout.connect(_on_growth_timer_timeout)
	growth_timer.start()
#	gpu_particles_2d.position += plant_resource.starting_pos
	if plant_resource.amount_of_currency_produced == 0:
		currency_timer.stop()
		currency_timer.wait_time = 0.001
	if plant_resource.sprite_frames.get_animation_names().has("seedling"):
		animated_sprite_2d.play("seedling")
	else:
		animated_sprite_2d.play("fully_grown")
	all_affected_tiles_pos = surronding_tiles_arrays[0]

func fully_grown():
	growth_state = plant_resource.max_radius + 1
	animated_sprite_2d.play("fully_grown")

func get_time_to_next_expansion():
	return growth_timer.get_time_left()

func _on_currency_timer_timeout():
	generated_currency.emit(plant_resource.amount_of_currency_produced)

func _on_growth_timer_timeout():
	if growth_state < plant_resource.max_radius + 1:
		growth_state += 1
	gpu_particles_2d.amount = 150 * growth_state
	if growth_state == 1:
		animated_sprite_2d.play("fully_grown")
	else:
		if not do_not_emit:
			gpu_particles_2d.emitting = true
		has_grown.emit(surronding_tiles_arrays[growth_state-2], plant_resource.name, tile)

func kill():
	if plant_resource.can_be_killed:
		currency_timer.stop()
		growth_timer.stop()
		if plant_resource.is_prime:
			game_lost.emit("Your %s was destroyed, you lost!" % plant_resource.name)
		if growth_state < 1:
			animated_sprite_2d.play("seedling_dead")
		else:
			animated_sprite_2d.play("fully_grown_dead")
	else:
		push_error("Tried to kill a %s that can't be killed." % plant_resource.name)

func get_info():
	var info_array = []
	info_array.append("%s points in %s seconds." % [plant_resource.amount_of_currency_produced, plant_resource.currency_production_time])
	info_array.append(plant_resource.name)
	info_array.append("%s tile radius." % plant_resource.max_radius)
	info_array.append("currently %s tiles." % ((growth_state - 1) if growth_state >= 1 else 0))
	info_array.append(get_time_to_next_expansion())
	return info_array
