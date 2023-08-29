extends Node2D

var currency
enum TreesTypes {OAK, PRIMAL_OAK, SPRUCE, PRIMAL_SPRUCE}
var primal_oak_placed = false
var primal_spruce_placed = false
var tree_chosen: bool = true
var chosen_tree = null
var oak_cost = 10
var spruce_cost = 10
var mouse_pos

@export var starting_currency: int = 100
@export var currency_max: int = 500

@onready var world_auto_tile_map = $WorldAutoTileMap
@onready var tiles = world_auto_tile_map.get_used_cells(0).size()
@onready var grass_tiles = world_auto_tile_map.get_used_cells(2).size()



func _ready():
	world_auto_tile_map.currency_changed.connect(_on_currency_changed)
	world_auto_tile_map.grass_tiles_changed.connect(_on_grass_tiles_changed)
	currency = starting_currency
	_on_currency_changed(0)
	mouse_pos = get_global_mouse_position()
	place_factory(Vector2(-3033.333, 713.3333))
	place_factory(Vector2(700, 246.6665))
	place_factory(Vector2(1306.667, -1440))

func _on_grass_tiles_changed(tiles_count):
	grass_tiles = tiles_count
	var value: float = (grass_tiles * 100) / tiles
	$UI/LevelUI.change_progress_bar_value(value)
	if value >= 95:
		show_level_ended("Nature has won!")
	elif value <= 5:
		show_level_ended("Pollution has won!")	

func _process(_delta):
	mouse_pos = get_global_mouse_position()

func _unhandled_input(event):
	if event.is_action_pressed("left_click") and tree_chosen:
		if world_auto_tile_map.can_place_object(mouse_pos):
			place_tree(mouse_pos)
	if event.is_action_pressed("ui_down"):
		if world_auto_tile_map.can_place_object(mouse_pos):
			place_factory(mouse_pos)
	if event.is_action_pressed("check"):
		print(mouse_pos)

func _on_currency_changed(amount):
	currency += amount
	if currency < 0:
		currency =0
	elif currency > currency_max:
		currency = currency_max
	$UI/LevelUI.change_currency_amout(currency)

func place_tree(pos):
	if chosen_tree == TreesTypes.PRIMAL_OAK and not primal_oak_placed:
		if currency >= oak_cost*10:
			_on_currency_changed(-oak_cost*10)
			world_auto_tile_map.place_tree(pos, TreesTypes.PRIMAL_OAK)
			primal_oak_placed = true
	elif chosen_tree == TreesTypes.OAK and primal_oak_placed:
		if currency >= oak_cost:
			_on_currency_changed(-oak_cost)
			world_auto_tile_map.place_tree(pos, TreesTypes.OAK)
	elif chosen_tree == TreesTypes.PRIMAL_SPRUCE and not primal_spruce_placed:
		if currency >= spruce_cost*10:
			_on_currency_changed(-spruce_cost*10)
			world_auto_tile_map.place_tree(pos, TreesTypes.PRIMAL_SPRUCE)
			primal_spruce_placed = true
	elif chosen_tree == TreesTypes.SPRUCE and primal_spruce_placed:
		if currency >= spruce_cost:
			_on_currency_changed(-spruce_cost)
			world_auto_tile_map.place_tree(pos, TreesTypes.SPRUCE)
	else:
		return

func place_factory(pos):
	world_auto_tile_map.place_factory(pos)

func _on_level_ui_chosen_tree_changed(type):
	chosen_tree = type
	if chosen_tree == null:
		tree_chosen = false
	else:
		tree_chosen = true

func show_level_ended(text):
	$UI/LevelEnded.display(text)
	get_tree().paused = true

func _on_level_ended_level_restarted():
	get_tree().reload_scene()
