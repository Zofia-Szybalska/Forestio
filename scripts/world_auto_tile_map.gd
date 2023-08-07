extends TileMap

var mouse_pos: Vector2
var curr_tile: Vector2
var prev_tile: Vector2
var tree_chosen: bool = true
signal tree_placed
var chosen_tree = "oak"
@onready var oak: PackedScene = preload("res://scenes/trees/oak.tscn")

func _ready():
	mouse_pos = get_global_mouse_position()
	curr_tile =  local_to_map(mouse_pos)
	prev_tile = curr_tile

func _process(_delta):
	draw_highlight()
	if tree_chosen and (Input.is_action_just_pressed("right_click") or Input.is_action_just_pressed("ui_cancel")):
		tree_chosen = false
	if Input.is_action_just_pressed("left_click") and tree_chosen and not get_cell_source_id(0, curr_tile) == -1:
		tree_placed.emit(chosen_tree, map_to_local(curr_tile))

func draw_highlight():
	mouse_pos = get_global_mouse_position()
	curr_tile =  local_to_map(mouse_pos)
	if get_cell_source_id(0, curr_tile) == null:
		return
	if curr_tile != prev_tile:
		set_cell(1, prev_tile,-1,Vector2(-1.0, -1.0),-1)
		prev_tile = curr_tile
	var tile_data = get_cell_tile_data(0, curr_tile)
	if tile_data:
		set_cell(1, curr_tile,1,Vector2(0.0, 0.0))

