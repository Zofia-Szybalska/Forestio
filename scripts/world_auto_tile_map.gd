extends TileMap

var mouse_pos: Vector2
var curr_tile: Vector2
var prev_tile: Vector2

var tree_chosen: bool = true
var chosen_tree = null:
	set(value):
		chosen_tree = value
		_on_chosen_tree_change()

var highlight_layer: int = 6
var base_layer:int = 0
var grass_layer:int = 4
var pollution_layer:int = 1
var water_layer:int = 5
var rocks_layer:int = 7
var super_pollution_layer:int = 2
var eternal_grass_layer:int = 3

var trees : Dictionary = {}
var factories : Dictionary = {}
enum TreesTypes {OAK, PRIMAL_OAK, SPRUCE, PRIMAL_SPRUCE, FERN}
var first_tree = true
var building_preview: Sprite2D
var destroy_mode_active = false
var primal_oak_placed = false
var primal_spruce_placed = false

signal currency_changed
signal grass_tiles_changed
signal game_lost

@onready var oak: PackedScene = preload("res://scenes/trees/oak.tscn")
@onready var spruce: PackedScene = preload("res://scenes/trees/spruce.tscn")
@onready var base_factory: PackedScene = preload("res://scenes/factories/base_factory.tscn")
@onready var super_factory: PackedScene = preload("res://scenes/factories/super_factory.tscn")
@onready var river_factory: PackedScene = preload("res://scenes/factories/river_polluting_factory.tscn")
@onready var primal_oak: PackedScene = preload("res://scenes/trees/primal_oak.tscn")
@onready var primal_spruce: PackedScene = preload("res://scenes/trees/primal_spruce.tscn")
@onready var fern: PackedScene = preload("res://scenes/trees/fern.tscn")
@onready var oak_texture = preload("res://assets/trees/SmallerOak.png")
@onready var spruce_texture = preload("res://assets/trees/Spruce.png")
@onready var fern_texture = preload("res://assets/trees/FernFullyGrown.png")

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
	grass_tiles_changed.emit(get_used_cells(grass_layer).size())

func _on_chosen_tree_change():
	if chosen_tree == TreesTypes.PRIMAL_OAK:
		building_preview.texture = oak_texture
		building_preview.scale = Vector2(1.5,1.5)
	elif chosen_tree == TreesTypes.OAK:
		building_preview.texture = oak_texture
		building_preview.scale = Vector2(0.75,0.75)
	elif chosen_tree == TreesTypes.PRIMAL_SPRUCE:
		building_preview.texture = spruce_texture
		building_preview.scale = Vector2(1.5,1.5)
	elif chosen_tree == TreesTypes.SPRUCE:
		building_preview.texture = spruce_texture
		building_preview.scale = Vector2(0.75,0.75)
	elif chosen_tree == TreesTypes.FERN:
		building_preview.texture = fern_texture
		building_preview.scale = Vector2(1, 1)
	else:
		building_preview.texture = null

func get_tile_type(tile):
	var rocks = ""
	if not get_cell_source_id(rocks_layer, tile) == -1:
		rocks = " Because of the rocks nothing can be built on this tile."
	if not get_cell_source_id(water_layer, tile) == -1:
		if get_cell_tile_data(water_layer, tile).get_custom_data("is_polluted"):
			return "polluted water it can be cleanse with algae." + rocks
		else:
			return "water that is not polluted." + rocks
	elif not get_cell_source_id(eternal_grass_layer, tile) == -1:
		return "grass that cannot be polluted." + rocks
	elif not get_cell_source_id(super_pollution_layer, tile) == -1:
		return "super pollution that can be remove only with fern." + rocks
	elif not get_cell_source_id(grass_layer, tile) == -1:
		return "normal grass that can be normally polluted." + rocks
	elif get_cell_tile_data(base_layer, tile).get_custom_data("is_polluted"):
		return "normal pollution that can be removed by any tree." + rocks
	else:
		return "base tile it's not polluted and grass don't grow on it." + rocks

func get_tile_info(pos):
	var tile = local_to_map(pos)
	var info_array: Array = []
	info_array.append(get_tile_type(tile))
	if tile in trees:
		var tree = trees[tile]
		info_array.append("%s points in %s seconds." % [tree.currency_generated, tree.currency_generation_time])
		info_array.append(tree.type)
		info_array.append("%s tile radius." % tree.max_radius)
		info_array.append("currently %s tiles." % (tree.growth_state - 1) if tree.growth_state > 0 else 0)
		info_array.append(tree.get_time_to_next_expansion())
		info_array.append(tree.growth_time)
	elif tile in factories:
		var factory = factories[tile]
		info_array.append("0 points in 1 second.")
		info_array.append(factory.type)
		info_array.append("%s tile radius." % factory.max_radius)
		info_array.append(("currently %s tiles." % (factory.curr_expansion_radius-1)) if factory.curr_expansion_radius is int else factory.curr_expansion_radius)
		info_array.append(factory.get_time_to_next_expansion())
		info_array.append(factory.expand_time)
	else:
		info_array.append("0 points in 1 second.")
		info_array.append("None")
		info_array.append("None")
		info_array.append("None")
		info_array.append("None")
	return info_array

func can_place_object(pos):
	var tile = local_to_map(pos)
	var data = get_cell_tile_data(water_layer, tile)
	if get_cell_source_id(base_layer, tile) == -1 or trees.has(tile) or factories.has(tile):
		return false
	elif data and data.get_custom_data("water"):
		return false
	elif not get_cell_source_id(rocks_layer, tile) == -1:
		return false
	else:
		return true

func can_place_tree(pos):
	if not can_place_object(pos):
		return false
	var tile = local_to_map(pos)
	if not get_cell_source_id(eternal_grass_layer, tile) == -1:
		return true
	var data = get_cell_tile_data(base_layer, tile)
	if data and data.get_custom_data("is_polluted"):
		return false
	if not get_cell_source_id(super_pollution_layer, tile) == -1:
		return false
	if chosen_tree == TreesTypes.PRIMAL_OAK and primal_oak_placed:
		return false
	elif  chosen_tree == TreesTypes.PRIMAL_SPRUCE and primal_spruce_placed:
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
		building_preview.position.y -= 170
	elif chosen_tree == TreesTypes.OAK or chosen_tree == TreesTypes.SPRUCE:
		building_preview.position.y -= 100
	elif chosen_tree == TreesTypes.FERN:
		building_preview.position.y -= 25
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
		tree_instanced.game_lost.connect(_on_game_lost)
	elif chosen_tree == TreesTypes.OAK or first_tree:
		tree_instanced = oak.instantiate()
		tree_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		tree_instanced.surronding_tiles_radius2 = get_surronding_tiles(tile, 2)
		tree_instanced.surronding_tiles_radius3 = get_surronding_tiles(tile, 3)
	elif chosen_tree == TreesTypes.PRIMAL_SPRUCE:
		tree_instanced = primal_spruce.instantiate()
		tree_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		tree_instanced.surronding_tiles_radius2 = get_surronding_tiles(tile, 2)
		tree_instanced.game_lost.connect(_on_game_lost)
	elif chosen_tree == TreesTypes.SPRUCE:
		tree_instanced = spruce.instantiate()
		tree_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		tree_instanced.surronding_tiles_radius2 = get_surronding_tiles(tile, 2)
	elif chosen_tree == TreesTypes.FERN:
		tree_instanced = fern.instantiate()
		tree_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		set_cells_terrain_connect(eternal_grass_layer, [tile],1,0)
	trees[tile] = tree_instanced
	tree_instanced.position = map_to_local(tile)
	tree_instanced.tile = tile
	set_cells_terrain_connect(grass_layer, [tile],1,0)
	$Trees.add_child(tree_instanced)
	if not chosen_tree == TreesTypes.FERN:
		tree_instanced.has_grown.connect(_on_tree_has_grown)
		tree_instanced.generated_currency.connect(_on_currency_changed)
	else:
		tree_instanced.has_grown.connect(_on_fern_has_grown)
	if first_tree:
		tree_instanced.fully_grown()
		first_tree = false

func place_factory(pos, type):
	var tile = local_to_map(pos)
	var factory_instanced
	if type == "base":
		factory_instanced = base_factory.instantiate()
		set_cells_terrain_connect(base_layer, [tile],0,0)
		factory_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		factory_instanced.surronding_tiles_radius2  = get_surronding_tiles(tile, 2)
		factory_instanced.surronding_tiles_radius3  = get_surronding_tiles(tile, 3)
	elif type == "super":
		factory_instanced = super_factory.instantiate()
		set_cells_terrain_connect(super_pollution_layer, [tile],2,0)
		factory_instanced.surronding_tiles_radius1 = get_surronding_tiles(tile, 1)
		factory_instanced.surronding_tiles_radius2  = get_surronding_tiles(tile, 2)
		factory_instanced.surronding_tiles_radius3  = get_surronding_tiles(tile, 3)
	elif type == "river":
		factory_instanced = river_factory.instantiate()	
		var surrounding_tiles = get_surrounding_cells(tile)
		for t in surrounding_tiles:
			if not get_cell_source_id(water_layer, t) == -1:
				var direction =  t - tile
				var riverbank_tiles: Array = []
				factory_instanced.starting_water_tiles = get_water_tiles_line(t, direction, riverbank_tiles)
				factory_instanced.direction = direction
				factory_instanced.riverbank_tiles = riverbank_tiles
				break
	
	factories[tile] = factory_instanced
	factory_instanced.position = map_to_local(tile)
	factory_instanced.tile = tile

	$Factories.add_child(factory_instanced)
	if type == "river":
		factory_instanced.water_polluted.connect(_on_water_polluted)
	else:
		factory_instanced.expanded.connect(_on_factory_expanded)

func _on_tree_has_grown(affected_tiles):
	change_surronding_tiles_tree(affected_tiles)

func _on_fern_has_grown(affected_tiles):
	for tile in affected_tiles:
		if factories.has(tile) and not factories[tile].is_destroyed:
			factories[tile].destroy()
	set_cells_terrain_connect(eternal_grass_layer, affected_tiles, 1, 0, false)
	set_cells_terrain_connect(grass_layer, affected_tiles, 1, 0, false)
	set_cells_terrain_connect(base_layer, affected_tiles, 0, 2, false)
	set_cells_terrain_connect(super_pollution_layer, affected_tiles, 2, -1, false)

func _on_factory_expanded(affected_tiles, pollution_type):
	change_surronding_tiles_polution(affected_tiles, pollution_type)

func _on_currency_changed(amount):
	currency_changed.emit(amount)

func _on_water_polluted(water_tiles:Array, direction, tile, riverbank_tiles):
	set_cells_terrain_connect(base_layer, riverbank_tiles, 0, 0, false)
	set_cells_terrain_connect(grass_layer, riverbank_tiles, 1, -1)
	if water_tiles.size() > 0:
		change_water_tiles(water_tiles, "pollution")
		var water_direction = get_cell_tile_data(water_layer, water_tiles.front()).get_custom_data("water_direction")
		var new_water_tiles: Array = []
		for t in water_tiles:
			if is_water(t + water_direction):
				if not (t + water_direction) in new_water_tiles:
					new_water_tiles.append_array(get_water_tiles_line(t + water_direction, direction, riverbank_tiles))
			elif get_cell_source_id(base_layer, t + water_direction) == -1:
				break
		factories[tile].water_tiles = new_water_tiles

func is_grass(tile):
	if not get_cell_source_id(grass_layer, tile) == -1:
		return true
	return false

func is_water(tile):
	if not get_cell_source_id(water_layer, tile) == -1:
		return true
	return false

func change_surronding_tiles_tree(tiles: Array):
	var local_tiles = tiles.duplicate()
	for tile in tiles:
		if not get_cell_source_id(super_pollution_layer, tile) == -1:
			local_tiles.erase(tile)
		if factories.has(tile) and not factories[tile].is_destroyed:
			if factories[tile].is_in_group("base_factories"):
				factories[tile].destroy()
			if factories[tile].is_in_group("super_factories") and factories[tile].surronding_tiles_radius1.any(is_grass):
				factories[tile].destroy()
				local_tiles.append(tile)
	set_cells_terrain_connect(grass_layer, local_tiles, 1, 0, false)
	set_cells_terrain_connect(base_layer, local_tiles, 0, 2, false)

func change_water_tiles(tiles, type):
	if type == "pollution":
		for tile in tiles:
			set_cell(water_layer, tile, 9, get_cell_atlas_coords(water_layer, tile))
	else:
		for tile in tiles:
			set_cell(water_layer, tile, 8, get_cell_atlas_coords(water_layer, tile))

func change_surronding_tiles_polution(affected_tiles: Array, pollution_type):
	var local_tiles = affected_tiles.duplicate()
	for tile in affected_tiles:
		if not get_cell_source_id(eternal_grass_layer, tile) == -1:
			local_tiles.erase(tile)
		if tile in trees:
			if trees[tile].is_in_group("oaks"):
				trees[tile].remove_from_group("oaks")
			if trees[tile].is_in_group("spruces"):
				trees[tile].remove_from_group("spruces")
			if trees[tile].is_in_group("ferns"):
				continue
			trees[tile].kill()
	affected_tiles = local_tiles
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
			if data and data.get_custom_data("is_not_riverbank"):
				continue
			surronding_tiles.append(target_tile)
	return surronding_tiles

func get_water_tiles_line(tile, direction, riverbank_tiles: Array):
	var water_tiles = [tile]
	if not get_cell_tile_data(water_layer,tile).get_custom_data("is_not_riverbank"):
		riverbank_tiles.append(tile)
	var count = 1
	while true:
		var next_tile = tile + direction * count
		if is_water(next_tile):
			water_tiles.append(next_tile)
			count += 1
			if not (get_cell_tile_data(water_layer, next_tile).get_custom_data("is_not_riverbank") and next_tile in riverbank_tiles):
				riverbank_tiles.append(next_tile)
		else:
			break
	count = -1
	while true:
		var next_tile = tile + direction * count
		if is_water(next_tile):
			water_tiles.append(next_tile)
			count -= 1
			if not (get_cell_tile_data(water_layer, next_tile).get_custom_data("is_not_riverbank") and next_tile in riverbank_tiles):
				riverbank_tiles.append(next_tile)
		else:
			break
	return water_tiles

func remove_tiles(layer, tiles):
	for tile in tiles:
		erase_cell(layer, tile)

func try_to_destroy_tree(pos):
	var tile = local_to_map(pos)
	if trees.has(tile):
		var tree = trees[tile]
		trees.erase(tile)
		currency_changed.emit(tree.currency_cost/2)
		tree.queue_free()

func _on_game_lost(text):
	game_lost.emit(text)
