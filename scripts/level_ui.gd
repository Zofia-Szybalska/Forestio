extends CanvasLayer

enum TreesTypes {OAK, PRIMAL_OAK, SPRUCE, PRIMAL_SPRUCE, FERN}

var cross = load("res://assets/CrossCursor.png")
var curr_info_time = null
@onready var tile_info = $InfoBox/MarginContainer/VBoxContainer/TileInfo/TileInfo
@onready var nature_info = $InfoBox/MarginContainer/VBoxContainer/NatureInfo/NatureInfo
@onready var building_info = $InfoBox/MarginContainer/VBoxContainer/BuildingInfo/BuildingInfo
@onready var range_info = $InfoBox/MarginContainer/VBoxContainer/RangeInfo/RangeInfo
@onready var expand_info = $InfoBox/MarginContainer/VBoxContainer/ExpandInfo/ExpandInfo
@onready var time_info = $InfoBox/MarginContainer/VBoxContainer/TimeInfo/TimeInfo

@onready var info_box = $InfoBox


signal chosen_tree_changed
signal destroy_mode_changed

func _ready():
	pass
#	tile_info.custom_minimum_size.x = info_box.size.x - $InfoBox/MarginContainer/VBoxContainer/TileInfo/Lable.size.x
#	nature_info.custom_minimum_size.x = info_box.size.x - $InfoBox/MarginContainer/VBoxContainer/NatureInfo/Label.size.x
#	building_info.custom_minimum_size.x = info_box.size.x - $InfoBox/MarginContainer/VBoxContainer/BuildingInfo/Label.size.x
#	range_info.custom_minimum_size.x = info_box.size.x - $InfoBox/MarginContainer/VBoxContainer/RangeInfo/Label.size.x
#	expand_info.custom_minimum_size.x = info_box.size.x - $InfoBox/MarginContainer/VBoxContainer/ExpandInfo/Label.size.x
#	time_info.custom_minimum_size.x = info_box.size.x - $InfoBox/MarginContainer/VBoxContainer/TimeInfo/Lable.size.x

func _process(_delta):
	if info_box.visible:
		time_info.text = str(snapped($TimeLeftTimer.get_time_left(), 0.01))
	
	if Input.is_action_just_pressed("ui_cancel"):
		chosen_tree_changed.emit(null)
		deactivate_destroy()
		$Buttons/HBoxContainer/PrimalOakButton.release_focus()
		$Buttons/HBoxContainer/OakButton.release_focus()
		$Buttons/HBoxContainer/SpruceButton.release_focus()
		$Buttons/HBoxContainer/PrimalSpruceButton.release_focus()
		$Buttons/HBoxContainer/DestroyButton.release_focus()

func change_progress_bar_value(value):
	$ProgressBar.value = value

func change_currency_amout(value):
	$NaturePoints/MarginContainer/NaturePoints/NaturePointsAmount.text = str(value)

func _on_primal_oak_button_pressed():
	chosen_tree_changed.emit(TreesTypes.PRIMAL_OAK)
	deactivate_destroy()

func _on_oak_button_pressed():
	chosen_tree_changed.emit(TreesTypes.OAK)
	deactivate_destroy()

func _on_spruce_button_pressed():
	chosen_tree_changed.emit(TreesTypes.SPRUCE)
	deactivate_destroy()

func _on_primal_spruce_button_pressed():
	chosen_tree_changed.emit(TreesTypes.PRIMAL_SPRUCE)
	deactivate_destroy()

func deactivate_destroy():
	destroy_mode_changed.emit(false)
	Input.set_custom_mouse_cursor(null)

func _on_destroy_button_pressed():
	Input.set_custom_mouse_cursor(cross, Input.CURSOR_ARROW, Vector2(16,16))
	destroy_mode_changed.emit(true)

func _on_fern_button_pressed():
	chosen_tree_changed.emit(TreesTypes.FERN)
	deactivate_destroy()

func show_info(info_array:Array):
	change_info(info_array[0], info_array[1], info_array[2], info_array[3], info_array[4], info_array[5])
	info_box.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(info_box, "modulate", Color(1,1,1,1), 0.5)
	$InfoBoxTimer.start()
	if info_array.size() > 6:
		curr_info_time = info_array[6]
	else:
		curr_info_time = null

func hide_info():
	var tween = get_tree().create_tween()
	tween.tween_property(info_box, "modulate", Color(1,1,1,0), 0.5)
	info_box.visible = true

func change_info(tile, nature, building, curr_range, expand, time):
	tile_info.text = str(tile)
	nature_info.text = str(nature)
	building_info.text = str(building)
	range_info.text =  str(curr_range)
	expand_info.text = str(expand)
	time_info.text = str(snapped(time, 0.01) if time is float else 0)
	$TimeLeftTimer.wait_time = time if time is float else 0
	$TimeLeftTimer.start()

func _on_info_box_timer_timeout():
#	hide_info()
	pass


func _on_time_left_timer_timeout():
	if not curr_info_time == null and info_box.visible:
		$TimeLeftTimer.wait_time = curr_info_time
		$TimeLeftTimer.start()
	else:
		$TimeLeftTimer.stop()
