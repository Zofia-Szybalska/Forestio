extends Node2D

var currency
enum TreesTypes {OAK, PRIMAL_OAK, SPRUCE, PRIMAL_SPRUCE, FERN, ALGAE}
var primal_oak_placed = false
var primal_spruce_placed = false
var tree_chosen: bool = false
var chosen_tree = null
var oak_cost = 10
var spruce_cost = 10
var fern_cost = 10
var algae_cost = 10
var mouse_pos
var destroy_mode_active = false

@export var starting_currency: int = 100
@export var currency_max: int = 5000

@onready var world_auto_tile_map = $WorldAutoTileMap
@onready var level_ui = $UI/LevelUI
@onready var avaliable_tiles = world_auto_tile_map.get_used_cells(0).size() -  world_auto_tile_map.get_used_cells(world_auto_tile_map.water_layer).size()
@onready var grass_tiles = world_auto_tile_map.get_used_cells(2).size()



func _ready():
	world_auto_tile_map.currency_changed.connect(_on_currency_changed)
	world_auto_tile_map.grass_tiles_changed.connect(_on_grass_tiles_changed)
	currency = starting_currency
	_on_currency_changed(0)
	mouse_pos = get_global_mouse_position()
	place_factory(Vector2(-3033.333, 713.3333), "base")
	place_factory(Vector2(700, 246.6665), "base")
	place_factory(Vector2(1306.667, -1440), "super")
	place_factory(world_auto_tile_map.map_to_local(Vector2(-9,1)), "river")

func _on_grass_tiles_changed(tiles_count):
	grass_tiles = tiles_count
	var value: float = (grass_tiles * 100) / avaliable_tiles
	$UI/LevelUI.change_progress_bar_value(value)
	if value >= 95:
		show_level_ended("Nature has won!")
	elif value <= 5:
		show_level_ended("Pollution has won!")	

func _process(_delta):
	mouse_pos = get_global_mouse_position()

func _unhandled_input(event):
	if event.is_action_pressed("left_click") and tree_chosen and not destroy_mode_active:
		if world_auto_tile_map.can_place_plant(mouse_pos) and not chosen_tree == TreesTypes.ALGAE:
			place_tree(mouse_pos)
		if chosen_tree == TreesTypes.ALGAE and world_auto_tile_map.is_water(mouse_pos):
			place_tree(mouse_pos)
	elif event.is_action_pressed("left_click") and not tree_chosen and not destroy_mode_active:
		var info_array = world_auto_tile_map.get_tile_info(mouse_pos)
		level_ui.show_info(info_array)
	elif event.is_action_pressed("left_click") and destroy_mode_active:
		world_auto_tile_map.try_to_destroy_tree(mouse_pos)

func _on_currency_changed(amount):
	currency += amount
	if currency < 0:
		currency = 0
	elif currency > currency_max:
		currency = currency_max
	$UI/LevelUI.change_currency_amount(currency)

func place_tree(pos):
	if chosen_tree == TreesTypes.PRIMAL_OAK and not primal_oak_placed:
		if currency >= oak_cost*10:
			_on_currency_changed(-oak_cost*10)
			world_auto_tile_map.place_plant(pos)
			primal_oak_placed = true
			world_auto_tile_map.primal_oak_placed = true
	elif chosen_tree == TreesTypes.OAK and primal_oak_placed:
		if currency >= oak_cost:
			_on_currency_changed(-oak_cost)
			world_auto_tile_map.place_plant(pos)
	elif chosen_tree == TreesTypes.PRIMAL_SPRUCE and not primal_spruce_placed:
		if currency >= spruce_cost*10:
			_on_currency_changed(-spruce_cost*10)
			world_auto_tile_map.place_plant(pos)
			primal_spruce_placed = true
			world_auto_tile_map.primal_spruce_placed = true
	elif chosen_tree == TreesTypes.SPRUCE and primal_spruce_placed:
		if currency >= spruce_cost:
			_on_currency_changed(-spruce_cost)
			world_auto_tile_map.place_plant(pos)
	elif chosen_tree == TreesTypes.FERN:
		if currency >= fern_cost:
			_on_currency_changed(-fern_cost)
			world_auto_tile_map.place_plant(pos)
	elif chosen_tree == TreesTypes.ALGAE:
		if currency >= algae_cost:
			_on_currency_changed(-algae_cost)
			world_auto_tile_map.place_plant(pos)
	else:
		return

func place_factory(pos, type):
	world_auto_tile_map.place_factory(pos, type)

func _on_level_ui_chosen_tree_changed(type):
	chosen_tree = type
	world_auto_tile_map.chosen_tree = type
	if chosen_tree == null:
		tree_chosen = false
	else:
		tree_chosen = true

func show_level_ended(text):
	$UI/LevelEnded.display(text)
	get_tree().paused = true

func _on_level_ended_level_restarted():
	get_tree().reload_scene()

func _on_level_ui_destroy_mode_changed(value):
	destroy_mode_active = value
	world_auto_tile_map.destroy_mode_active = value

func _on_world_auto_tile_map_game_lost(text):
	show_level_ended(text)

func _on_level_ui_info_needed(tile):
	var info_array = world_auto_tile_map.get_tile_info(tile)
	level_ui.show_info(info_array)
