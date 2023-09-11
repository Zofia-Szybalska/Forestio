extends TileMap

var mouse_pos: Vector2
var curr_tile: Vector2
var prev_tile: Vector2

var tree_chosen: bool = true
var chosen_tree = null:
	set(value):
		chosen_tree = value
		_on_chosen_tree_change()

var highlight_layer: int = 5
var base_layer:int = 0
var grass_layer:int = 3
var pollution_layer:int = 1
var water_layer:int = 4
var super_pollution_layer:int = 2
var trees : Dictionary = {}
var factories : Dictionary = {}
enum TreesTypes {OAK, PRIMAL_OAK, SPRUCE, PRIMAL_SPRUCE}
var firt_tree = true
var building_preview: Sprite2D
var destroy_mode_active = false

signal currency_changed
signal grass_tiles_changed

@onready var oak: PackedScene = preload("res://scenes/trees/oak.tscn")
@onready var spruce: PackedScene = preload("res://scenes/trees/spruce.tscn")
@onready var base_factory: PackedScene = preload("res://scenes/factories/base_factory.tscn")
@onready var super_factory: PackedScene = preload("res://scenes/factories/super_factory.tscn")
@onready var primal_oak: PackedScene = preload("res://scenes/trees/primal_oak.tscn")
@onready var primal_spruce: PackedScene = preload("res://scenes/trees/primal_spruce.tscn")
@onready var oak_texture = preload("res://assets/trees/OakFullyGrown.png")
@onready var spruce_texture = preload("res://assets/trees/Spruce.png")

func _ready():
	mouse_pos = get_global_mouse_position()
	curr_tile = local_to_map(mouse_pos)
	prev_tile = curr_tile
	place_tree(Vector2(-763.3334, -750))
	building_preview = Sprite2D.new()
	building_preview.modulate = Color(1, 1, 1, 0.3)
	building_preview.z_index = 1
	$Trees.add_child(building_preview)

func _process(_delta):
	mouse_pos = get_global_mouse_position()
	curr_tile =  local_to_map(mouse_pos)
	draw_highlight()
	if not chosen_tree == null:
		draw_building_preview()
	if Input.is_action_pressed("check"):
		pass
	grass_tiles_changed.emit(get_used_cells(grass_layer).size())

func _on_chosen_tree_change():
	if chosen_tree == TreesTypes.PRIMAL_OAK:
		building_preview.texture = oak_texture
		building_preview.scale = Vector2(2,2)
	elif chosen_tree == TreesTypes.OAK:
		building_preview.texture = oak_texture
		building_preview.scale = Vector2(1,1)
	elif chosen_tree == TreesTypes.PRIMAL_SPRUCE:
		building_preview.texture = spruce_texture
		building_preview.scale = Vector2(2,2)
	elif chosen_tree == TreesTypes.SPRUCE:
		building_preview.texture = spruce_texture
		building_preview.scale = Vector2(1,1)
	else:
		building_preview.texture = null

func can_place_object(pos):
	var tile = local_to_map(pos)
	var data = get_cell_tile_data(water_layer, tile)
	if get_cell_source_id(base_layer, tile) == -1 or trees.has(tile) or factories.has(tile):
		return false
	elif data:
		if data.get_custom_data("water"):
			return false
	else:
		return true

func can_place_tree(pos):
	if not can_place_object(pos):
		return false
	var tile = local_to_map(pos)
	var data = get_cell_tile_data(base_layer, tile)
	if data and data.get_custom_data("is_polluted"):
		return false
	data = get_cell_tile_data(super_pollution_layer, tile)
	if data and data.get_custom_data("is_polluted"):
		return false
	return true

func draw_highlight():
	if curr_tile != prev_tile:
		set_cell(highlight_layer, prev_tile,-1,Vector2(-1.0, -1.0),-1)
		prev_tile = curr_tile
	if get_cell_source_id(0, curr_tile) == -1:
		return
	else:
		set_cell(highlight_layer, curr_tile,1,Vector2(0.0, 0.0))

func draw_building_preview():
	building_preview.position = map_to_local(curr_tile)
	if chosen_tree == TreesTypes.PRIMAL_OAK or chosen_tree == TreesTypes.PRIMAL_SPRUCE:
		building_preview.position.y -= 233
	else:
		building_preview.position.y -= 128
	if not can_place_tree(mouse_pos) or destroy_mode_active:
		building_preview.visible = false
	else:
		building_preview.visible = true

func place_tree(pos):
	var tile = local_to_map(pos)
	
	var tree_instanced
	if chosen_tree == TreesTypes.PRIMAL_OAK:
		tree_instanced = primal_oak.instantiate()
		tree_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		tree_instanced.surronding_tiles_radius2 = get_surronding_tiles(tile, 2)
		tree_instanced.surronding_tiles_radius3 = get_surronding_tiles(tile, 3)
	elif chosen_tree == TreesTypes.OAK or firt_tree:
		tree_instanced = oak.instantiate()
		tree_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		tree_instanced.surronding_tiles_radius2 = get_surronding_tiles(tile, 2)
		tree_instanced.surronding_tiles_radius3 = get_surronding_tiles(tile, 3)
	elif chosen_tree == TreesTypes.PRIMAL_SPRUCE:
		tree_instanced = primal_spruce.instantiate()
		tree_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		tree_instanced.surronding_tiles_radius2 = get_surronding_tiles(tile, 2)
	elif chosen_tree == TreesTypes.SPRUCE:
		tree_instanced = spruce.instantiate()
		tree_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		tree_instanced.surronding_tiles_radius2 = get_surronding_tiles(tile, 2)
	
	trees[tile] = tree_instanced
	tree_instanced.position = map_to_local(tile)
	tree_instanced.tile = tile
	set_cell(grass_layer, tile, 5, Vector2i(4,7))
	set_cells_terrain_connect(grass_layer, [tile],1,0, false)
	$Trees.add_child(tree_instanced)
	tree_instanced.has_grown.connect(_on_tree_has_grown)
	tree_instanced.generated_currency.connect(_on_currency_changed)
#	grass_tiles_changed.emit(get_used_cells(grass_layer).size())
	if firt_tree:
		tree_instanced.fully_grown()
		firt_tree = false

func place_factory(pos, type):
	var tile = local_to_map(pos)
	var factory_instanced
	if type == "base":
		factory_instanced = base_factory.instantiate()
		set_cells_terrain_connect(base_layer, [tile],0,0)
	elif type == "super":
		factory_instanced = super_factory.instantiate()
		set_cells_terrain_connect(super_pollution_layer, [tile],2,0)
	factories[tile] = factory_instanced
	factory_instanced.position = map_to_local(tile)
	factory_instanced.tile = tile
	factory_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
	factory_instanced.surronding_tiles_radius2  = get_surronding_tiles(tile, 2)
	factory_instanced.surronding_tiles_radius3  = get_surronding_tiles(tile, 3)
	$Factories.add_child(factory_instanced)
	factory_instanced.expanded.connect(_on_factory_expanded)

func _on_tree_has_grown(affected_tiles):
	change_surronding_tiles_tree(affected_tiles)

func _on_factory_expanded(affected_tiles, pollution_type):
	change_surronding_tiles_polution(affected_tiles, pollution_type)

func _on_currency_changed(amount):
	currency_changed.emit(amount)

func is_grass(tile):
	if not get_cell_source_id(grass_layer, tile) == -1:
		return true
	return false

func change_surronding_tiles_tree(tiles: Array):
	var local_tiles = tiles.duplicate()
	for tile in tiles:
		var data = get_cell_tile_data(super_pollution_layer, tile)
		if data and data.get_custom_data("is_polluted"):
			local_tiles.erase(tile)
		if factories.has(tile) and not factories[tile].is_destroyed:
			if factories[tile].is_in_group("base_factories"):
				factories[tile].destroy()
			if factories[tile].is_in_group("super_factories") and factories[tile].surronding_tiles_radius1.any(is_grass):
				factories[tile].destroy()

				local_tiles.append(tile)
	set_cells_terrain_connect(grass_layer, local_tiles, 1, 0, false)
	set_cells_terrain_connect(base_layer, local_tiles, 0, 2, false)

func change_surronding_tiles_polution(affected_tiles, pollution_type):
	for tile in affected_tiles:
		if tile in trees:
			if trees[tile].is_in_group("oaks"):
				trees[tile].remove_from_group("oaks")
			if trees[tile].is_in_group("spruces"):
				trees[tile].remove_from_group("spruces")
			trees[tile].kill()
	if pollution_type == "pollution":
		set_cells_terrain_connect(base_layer, affected_tiles, 0, 0)
	elif pollution_type == "super_pollution":
		set_cells_terrain_connect(super_pollution_layer, affected_tiles, 2, 0)
	set_cells_terrain_connect(grass_layer, affected_tiles, 1, -1)

func get_surronding_tiles(tile, radius):
	var target_tile
	var surronding_tiles = []
	var count = radius * 2 + 1
	for y in count:
		for x in count:
			target_tile = tile + Vector2i(x-radius, y-radius)
			if get_cell_source_id(0, target_tile) == -1:
				continue
			var data = get_cell_tile_data(water_layer, target_tile)
			if data and data.get_custom_data("water"):
				continue
			surronding_tiles.append(target_tile)
	return surronding_tiles

func remove_tiles(layer, tiles):
	for tile in tiles:
		erase_cell(layer, tile)

func try_to_destroy_tree(mouse_pos):
	var tile = local_to_map(mouse_pos)
	if trees.has(tile):
		var tree = trees[tile]
		trees.erase(tile)
		currency_changed.emit(tree.currency_cost/2)
		tree.queue_free()

