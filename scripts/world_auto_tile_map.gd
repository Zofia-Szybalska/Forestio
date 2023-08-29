extends TileMap

var mouse_pos: Vector2
var curr_tile: Vector2
var prev_tile: Vector2

var tree_chosen: bool = true
var chosen_tree = TreesTypes.PRIMAL_OAK
var highlight_layer: int = 3
var base_layer:int = 0
var grass_layer:int = 2
var pollution_layer:int = 1
var trees : Dictionary = {}
var factories : Dictionary = {}
enum TreesTypes {OAK, PRIMAL_OAK, SPRUCE, PRIMAL_SPRUCE}
var firt_tree = true

signal currency_changed
signal grass_tiles_changed

@onready var oak: PackedScene = preload("res://scenes/trees/oak.tscn")
@onready var spruce: PackedScene = preload("res://scenes/trees/spruce.tscn")
@onready var base_factory: PackedScene = preload("res://scenes/factories/base_factory.tscn")
@onready var primal_oak: PackedScene = preload("res://scenes/trees/primal_oak.tscn")
@onready var primal_spruce: PackedScene = preload("res://scenes/trees/primal_spruce.tscn")


func _ready():
	mouse_pos = get_global_mouse_position()
	curr_tile = local_to_map(mouse_pos)
	prev_tile = curr_tile
	place_tree(Vector2(-763.3334, -750), TreesTypes.OAK)

func _process(_delta):
	mouse_pos = get_global_mouse_position()
	curr_tile =  local_to_map(mouse_pos)
	draw_highlight()

func can_place_object(pos):
	var tile = local_to_map(pos)
	if get_cell_source_id(base_layer, tile) == -1 or trees.has(tile) or factories.has(tile):
		return false
	else:
		return true

func draw_highlight():
	if curr_tile != prev_tile:
		set_cell(highlight_layer, prev_tile,-1,Vector2(-1.0, -1.0),-1)
		prev_tile = curr_tile
	if get_cell_source_id(0, curr_tile) == -1:
		return
	else:
		set_cell(highlight_layer, curr_tile,1,Vector2(0.0, 0.0))

func place_tree(pos, type):
	chosen_tree = type
	var tile = local_to_map(pos)
	var data = get_cell_tile_data(base_layer, tile)
	if data and data.get_custom_data("is_polluted"):
		return
	
	var tree_instanced
	if chosen_tree == TreesTypes.PRIMAL_OAK:
		tree_instanced = primal_oak.instantiate()
		chosen_tree = TreesTypes.OAK
	elif chosen_tree == TreesTypes.OAK or firt_tree:
		tree_instanced = oak.instantiate()
	elif chosen_tree == TreesTypes.PRIMAL_SPRUCE:
		tree_instanced = primal_spruce.instantiate()
	elif chosen_tree == TreesTypes.SPRUCE:
		tree_instanced = spruce.instantiate()
	
	trees[tile] = tree_instanced
	tree_instanced.position = map_to_local(tile)
	tree_instanced.tile = tile
	set_cell(grass_layer, tile, 5, Vector2i(4,7))
	set_cells_terrain_connect(grass_layer, [tile],1,0, false)
	$Trees.add_child(tree_instanced)
	tree_instanced.has_grown.connect(_on_tree_has_grown)
	tree_instanced.generated_currency.connect(_on_currency_changed)
	grass_tiles_changed.emit(get_used_cells(2).size())
	if firt_tree:
		tree_instanced.fully_grown()
		firt_tree = false

func place_factory(pos):
	var tile = local_to_map(pos)
	var factory_instanced = base_factory.instantiate()
	factories[tile] = factory_instanced
	factory_instanced.position = map_to_local(tile)
	set_cells_terrain_connect(base_layer, [tile],0,0)
	factory_instanced.tile = tile
	$Factories.add_child(factory_instanced)
	factory_instanced.expanded.connect(_on_factory_expanded)

func _on_tree_has_grown(growth_state, tile):
	change_surronding_tiles_tree(tile, growth_state-1)
	grass_tiles_changed.emit(get_used_cells(2).size())

func _on_factory_expanded(tile, radius, fully_expanded):
	change_surronding_tiles_polution(tile, radius, fully_expanded)
	grass_tiles_changed.emit(get_used_cells(2).size())

func _on_currency_changed(amount):
	currency_changed.emit(amount)

func change_surronding_tiles_tree(tile, radius):
	var target_tile
	var surronding_tiles = []
	var count = radius * 2 + 1
	for y in count:
		for x in count:
			target_tile = tile + Vector2i(x-radius, y-radius)
			if get_cell_source_id(0, target_tile) == -1:
				continue
			if factories.has(target_tile) and not factories[target_tile].is_destroyed:
				factories[target_tile].destroy()
			surronding_tiles.append(target_tile)
	set_cells_terrain_connect(grass_layer, surronding_tiles, 1, 0, false)
	set_cells_terrain_connect(base_layer, surronding_tiles, 0, 2, false)

func change_surronding_tiles_polution(tile, radius, fully_expanded):
	var target_tile
	var surronding_tiles = []
	var count = radius * 2 + 1
	for y in count:
		for x in count:
			target_tile = tile + Vector2i(x-radius, y-radius)
			if get_cell_source_id(0, target_tile) == -1:
				continue
			elif target_tile in trees:
				trees[target_tile].kill()
			surronding_tiles.append(target_tile)
	set_cells_terrain_connect(base_layer, surronding_tiles, 0, 0)
	set_cells_terrain_connect(grass_layer, surronding_tiles, 1, -1)
	if not fully_expanded:
		set_cells_terrain_connect(pollution_layer, surronding_tiles, 0, 3, false)

func remove_tiles(layer, tiles):
	for tile in tiles:
		erase_cell(layer, tile)



