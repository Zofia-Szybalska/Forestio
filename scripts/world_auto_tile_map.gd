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

var plants : Dictionary = {}
var factories : Dictionary = {}
enum TreesTypes {OAK, PRIMAL_OAK, SPRUCE, PRIMAL_SPRUCE, FERN, ALGAE}
var first_tree = true
var building_preview: Sprite2D
var destroy_mode_active = false
var primal_oak_placed = false
var primal_spruce_placed = false
var can_build_modulate = Color(1, 1, 1, 0.3)
var cannot_build_modulate = Color(1, 0, 0, 0.5)

signal currency_changed
signal grass_tiles_changed
signal game_lost

@onready var plant_scene: PackedScene = preload("res://scenes/plant.tscn")
@onready var oak: Plant = preload("res://resources/plants/oak.tres")
@onready var prime_oak: Plant = preload("res://resources/plants/prime_oak.tres")
@onready var spruce: Plant = preload("res://resources/plants/spruce.tres")
@onready var prime_spruce: Plant = preload("res://resources/plants/prime_spruce.tres")
@onready var fern: Plant = preload("res://resources/plants/fern.tres")
@onready var algea: Plant = preload("res://resources/plants/algae.tres")

@onready var factory_scene: PackedScene = preload("res://scenes/factory.tscn")
@onready var base_factory: Factory = preload("res://resources/factories/base_factory.tres")
@onready var super_factory: Factory = preload("res://resources/factories/super_factory.tres")
@onready var river_factory: Factory = preload("res://resources/factories/river_factory.tres")

@onready var oak_texture = preload("res://assets/trees/SmallerOak.png")
@onready var spruce_texture = preload("res://assets/trees/Spruce.png")
@onready var fern_texture = preload("res://assets/trees/FernFullyGrown.png")
@onready var algae_texture = preload("res://assets/trees/Algea0000.png")

func _ready():
	mouse_pos = get_global_mouse_position()
	curr_tile = local_to_map(mouse_pos)
	prev_tile = curr_tile
	place_plant(Vector2(-763.3334, -750))
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
	elif chosen_tree == TreesTypes.ALGAE:
		building_preview.texture = algae_texture
		building_preview.scale = Vector2(0.75, 0.75)
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
	var tile
	if pos is Vector2:
		tile = local_to_map(pos)
	else:
		tile = pos
	var info_array: Array = []
	info_array.append(get_tile_type(tile))
	if plants.has(tile):
		info_array.append_array(plants[tile].get_info())
	elif tile in factories:
		info_array.append_array(factories[tile].get_info())
	else:
		info_array.append("0 points in 1 second.")
		info_array.append("None")
		info_array.append("None")
		info_array.append("None")
		info_array.append("None")
	info_array.append(tile)
	return info_array

func can_place_object(pos):
	var tile
	if pos is Vector2:
		tile = local_to_map(pos)
	else:
		tile = pos
	if get_cell_source_id(base_layer, tile) == -1 or plants.has(tile) or factories.has(tile):
		return false
	elif is_water(tile):
		return false
	elif not get_cell_source_id(rocks_layer, tile) == -1:
		return false
	elif plants.has(tile) or factories.has(tile):
		return false
	elif not get_cell_source_id(rocks_layer, tile) == -1:
		return false
	return true

func can_place_plant(pos):
	var tile = local_to_map(pos)
	if chosen_tree == TreesTypes.ALGAE and is_water(tile) and not plants.has(tile):
		return true
	if chosen_tree == TreesTypes.ALGAE and not is_water(tile):
		return false
	if not can_place_object(pos):
		return false
	if not get_cell_source_id(eternal_grass_layer, tile) == -1:
		return true
	var data = get_cell_tile_data(base_layer, tile)
	if data and data.get_custom_data("is_polluted"):
		return false
	if not get_cell_source_id(super_pollution_layer, tile) == -1:
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
	elif chosen_tree == TreesTypes.ALGAE:
		building_preview.position.x += 10
		building_preview.position.y -= 10
	if not can_place_plant(mouse_pos) or (chosen_tree == TreesTypes.PRIMAL_OAK and primal_oak_placed) or (chosen_tree == TreesTypes.PRIMAL_SPRUCE and primal_spruce_placed):
		building_preview.modulate = cannot_build_modulate
	else:
		building_preview.modulate = can_build_modulate
	if destroy_mode_active or get_cell_source_id(base_layer, curr_tile) == -1:
		building_preview.hide()
	else:
		building_preview.show()

func place_plant(pos):
	var tile = local_to_map(pos)
	var plant_instanced = plant_scene.instantiate()
	if chosen_tree == TreesTypes.PRIMAL_OAK:
		plant_instanced.plant_resource = prime_oak
		plant_instanced.add_to_group("oaks")
	elif chosen_tree == TreesTypes.OAK or first_tree:
		plant_instanced.add_to_group("oaks")
		plant_instanced.plant_resource = oak
	elif chosen_tree == TreesTypes.PRIMAL_SPRUCE:
		plant_instanced.plant_resource = prime_spruce
		plant_instanced.add_to_group("spruces")
	elif chosen_tree == TreesTypes.SPRUCE:
		plant_instanced.plant_resource = spruce
		plant_instanced.add_to_group("spruces")
	elif chosen_tree == TreesTypes.FERN:
		plant_instanced.plant_resource = fern
		plant_instanced.add_to_group("ferns")
		set_cells_terrain_connect(eternal_grass_layer, [tile],1,0)
	elif chosen_tree == TreesTypes.ALGAE:
		plant_instanced.plant_resource = algea
		plant_instanced.add_to_group("algae")
		set_cell(water_layer, tile, 8, get_cell_atlas_coords(water_layer, tile))
		for radius in plant_instanced.plant_resource.max_radius:
			plant_instanced.surronding_tiles_arrays.append(get_surronding_tiles(tile, radius+1, "water"))
	plant_instanced.game_lost.connect(_on_game_lost)
	plant_instanced.generated_currency.connect(_on_currency_changed)
	plant_instanced.has_grown.connect(_on_plant_has_grown)
	if not chosen_tree == TreesTypes.ALGAE:
		set_cells_terrain_connect(grass_layer, [tile],1,0)
		for radius in plant_instanced.plant_resource.max_radius:
			plant_instanced.surronding_tiles_arrays.append(get_surronding_tiles(tile, radius+1))
	plants[tile] = plant_instanced
	plant_instanced.position = map_to_local(tile)
	plant_instanced.tile = tile
	$Trees.add_child(plant_instanced)
	if first_tree:
		plant_instanced.fully_grown()
		first_tree = false

func place_factory(pos, type):
	var tile
	if pos is Vector2:
		tile = local_to_map(pos)
	else:
		tile = pos
	var factory_instanced = factory_scene.instantiate()
	if type == "base":
		factory_instanced.factory_resource = base_factory
		set_cells_terrain_connect(base_layer, [tile],0,0)
		factory_instanced.add_to_group("base_factories")
	elif type == "super":
		factory_instanced.factory_resource = super_factory
		set_cells_terrain_connect(super_pollution_layer, [tile],2,0)
		factory_instanced.add_to_group("super_factories")
	elif type == "river":
		factory_instanced.factory_resource = river_factory
		factory_instanced.add_to_group("river_factories")
		var surrounding_tiles = get_surrounding_cells(tile)
		for t in surrounding_tiles:
			if not get_cell_source_id(water_layer, t) == -1:
				var direction =  t - tile
				var riverbank_tiles: Array = []
				factory_instanced.surronding_tiles_arrays.append(get_water_tiles_line(t, direction, riverbank_tiles))
				factory_instanced.water_polluting_direction = direction
				factory_instanced.additional_tiles = riverbank_tiles
				break
	if not type == "river":
		for radius in factory_instanced.factory_resource.max_radius:
			factory_instanced.surronding_tiles_arrays.append(get_surronding_tiles(tile, radius+1))
	factory_instanced.fully_expanded.connect(_on_factory_fully_expanded)
	factories[tile] = factory_instanced
	factory_instanced.position = map_to_local(tile)
	factory_instanced.tile = tile

	$Factories.add_child(factory_instanced)
	if type == "river":
		factory_instanced.expanded.connect(_on_water_polluted)
	else:
		factory_instanced.expanded.connect(_on_factory_expanded)

func _on_plant_has_grown(affected_tiles, plant_name):
	if plant_name == "Fern":
		_on_fern_has_grown(affected_tiles)
	elif plant_name == "Algae":
		change_water_tiles(affected_tiles, "clear")
	else:
		change_surronding_tiles_tree(affected_tiles)

func _on_fern_has_grown(affected_tiles):
	var tiles_to_change: Array = []
	for tile in affected_tiles:
		if not (factories.has(tile) and not factories[tile].is_destroyed):
			tiles_to_change.append(tile)
			set_cell(eternal_grass_layer, tile, 5, Vector2i(1,0))
	set_cells_terrain_connect(base_layer, tiles_to_change, 0, 2, false)
	set_cells_terrain_connect(super_pollution_layer, tiles_to_change, 2, -1, false)

func _on_factory_expanded(affected_tiles, pollution_type):
	change_surronding_tiles_polution(affected_tiles, pollution_type)

func _on_currency_changed(amount):
	currency_changed.emit(amount)

func _on_water_polluted(water_tiles:Array, direction, tile, riverbank_tiles):
	set_cells_terrain_connect(base_layer, riverbank_tiles, 0, 0, false)
	set_cells_terrain_connect(grass_layer, riverbank_tiles, 1, -1)
	if not direction:
		change_water_tiles(water_tiles, "pollution")
	else:
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
			factories[tile].surronding_tiles_arrays[0] = new_water_tiles

func _on_factory_fully_expanded(tiles:Array):
	var random_tile = get_random_polluted_tile(tiles.duplicate())
	if random_tile:
		place_factory(random_tile, get_random_factory_type())

func get_random_factory_type():
	var random_float = randf()
	if random_float < 0.8:
		return "base"
	else:
		return "super"

func get_random_polluted_tile(tiles:Array):
	tiles.shuffle()
	var random_tile = tiles[randi() % tiles.size()]
	while not is_polluted(random_tile) or not can_place_object(random_tile):
		tiles.erase(random_tile)
		if tiles.size() == 0:
			break
		random_tile = tiles[randi() % tiles.size()]
	if tiles.size() == 0:
		return null
	return random_tile

func is_grass(tile):
	if not get_cell_source_id(grass_layer, tile) == -1:
		return true
	return false

func is_polluted(tile):
	if get_cell_tile_data(base_layer, tile).get_custom_data("is_polluted"):
		return true
	var data = get_cell_tile_data(super_pollution_layer, tile)
	if data and data.get_custom_data("is_polluted"):
		return true
	data = get_cell_tile_data(water_layer, tile)
	if data and data.get_custom_data("is_polluted"):
		return true
	return false

func is_water(tile):
	if tile is Vector2:
		tile = local_to_map(tile)
	if not get_cell_source_id(water_layer, tile) == -1:
		return true
	return false

func change_surronding_tiles_tree(tiles: Array):
	var local_tiles = tiles.duplicate()
	for tile in tiles:
		if not get_cell_source_id(super_pollution_layer, tile) == -1:
			local_tiles.erase(tile)
		if factories.has(tile) and not factories[tile].is_destroyed:
			if factories[tile].is_in_group("base_factories") or factories[tile].is_in_group("river_factories"):
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
		if plants.has(tile):
			if plants[tile].is_in_group("oaks"):
				plants[tile].remove_from_group("oaks")
			if plants[tile].is_in_group("spruces"):
				plants[tile].remove_from_group("spruces")
			if plants[tile].is_in_group("ferns"):
				continue
			plants[tile].kill()
	affected_tiles = local_tiles
	if pollution_type == "normal":
		set_cells_terrain_connect(base_layer, affected_tiles, 0, 0)
	elif pollution_type == "super":
		set_cells_terrain_connect(super_pollution_layer, affected_tiles, 2, 0)
	set_cells_terrain_connect(grass_layer, affected_tiles, 1, -1)

func get_surronding_tiles(tile, radius, type = "normal"):
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
				if type == "water":
					surronding_tiles.append(target_tile)
				continue
			elif not data:
				if type == "water":
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
	if plants.has(tile):
		var tree = plants[tile]
		plants.erase(tile)
		currency_changed.emit(tree.plant_resource.cost/2)
		tree.queue_free()

func _on_game_lost(text):
	game_lost.emit(text)
