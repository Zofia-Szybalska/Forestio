extends CanvasLayer

enum PlantTypes {OAK, PRIMAL_OAK, SPRUCE, PRIMAL_SPRUCE, FERN, ALGAE}

var cross = load("res://assets/CrossCursor.png")
var curr_info_tile
var prev_nature_points_value = 100
var curr_nature_points_value = 100
var info_box_is_beeing_hidden = false
@onready var nature_points_amount_lable = $NaturePoints/MarginContainer/VBoxContainer/NaturePoints/NaturePointsAmount
@onready var nature_points_per_second_lable = $NaturePoints/MarginContainer/VBoxContainer/NaturePointsPerSecond

@onready var tile_info = $InfoBox/MarginContainer/VBoxContainer/TileInfo/TileInfo
@onready var nature_info = $InfoBox/MarginContainer/VBoxContainer/NatureInfo/NatureInfo
@onready var building_info = $InfoBox/MarginContainer/VBoxContainer/BuildingInfo/BuildingInfo
@onready var range_info = $InfoBox/MarginContainer/VBoxContainer/RangeInfo/RangeInfo
@onready var expand_info = $InfoBox/MarginContainer/VBoxContainer/ExpandInfo/ExpandInfo
@onready var time_info = $InfoBox/MarginContainer/VBoxContainer/TimeInfo/TimeInfo

@onready var info_box = $InfoBox


signal chosen_tree_changed
signal destroy_mode_changed
signal info_needed
signal info_hidden

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
		$Buttons/HBoxContainer/FernButton.release_focus()
		$Buttons/HBoxContainer/AlgaeButton.release_focus()
		if info_box.visible:
			hide_info()

func change_progress_bar_value(value):
	$ProgressBar.value = value

func change_currency_amount(value):
	nature_points_amount_lable.text = str(value)
	curr_nature_points_value = value

func _on_primal_oak_button_pressed():
	chosen_tree_changed.emit(PlantTypes.PRIMAL_OAK)
	deactivate_destroy()
	hide_info()

func _on_oak_button_pressed():
	chosen_tree_changed.emit(PlantTypes.OAK)
	deactivate_destroy()
	hide_info()

func _on_spruce_button_pressed():
	chosen_tree_changed.emit(PlantTypes.SPRUCE)
	deactivate_destroy()
	hide_info()

func _on_primal_spruce_button_pressed():
	chosen_tree_changed.emit(PlantTypes.PRIMAL_SPRUCE)
	deactivate_destroy()
	hide_info()

func deactivate_destroy():
	destroy_mode_changed.emit(false)
	Input.set_custom_mouse_cursor(null)

func _on_destroy_button_pressed():
	Input.set_custom_mouse_cursor(cross, Input.CURSOR_ARROW, Vector2(16,16))
	destroy_mode_changed.emit(true)
	hide_info()

func _on_fern_button_pressed():
	chosen_tree_changed.emit(PlantTypes.FERN)
	deactivate_destroy()
	hide_info()

func show_info(info_array:Array):
	change_info(info_array[0], info_array[1], info_array[2], info_array[3], info_array[4], info_array[5])
	info_box.visible = true
	var tween = get_tree().create_tween()
	tween.tween_property(info_box, "modulate", Color(1,1,1,1), 0.5)
	curr_info_tile = info_array[6]

func hide_info():
	if not info_box_is_beeing_hidden and info_box.visible:
		info_box_is_beeing_hidden = true
		var tween = get_tree().create_tween()
		tween.tween_property(info_box, "modulate", Color(1,1,1,0), 0.5)
		tween.connect("finished", on_tween_finished)

func on_tween_finished():
	info_box.hide()
	info_box_is_beeing_hidden = false
	info_hidden.emit()

func change_info(tile, nature, building, curr_range, expand, time):
	tile_info.text = str(tile)
	nature_info.text = str(nature)
	building_info.text = str(building)
	range_info.text =  str(curr_range)
	expand_info.text = str(expand)
	time_info.text = str(snapped(time, 0.01) if time is float else 0)
	$TimeLeftTimer.wait_time = time if time is float else 0.001
	if $TimeLeftTimer.wait_time == 0.001:
		$TimeLeftTimer.stop()
	else:
		$TimeLeftTimer.start()

func _on_time_left_timer_timeout():
	info_needed.emit(curr_info_tile)

func _on_nature_points_timer_timeout():
	var value = curr_nature_points_value - prev_nature_points_value
	if value > 0:
		nature_points_per_second_lable.text = "%s/s" % value
	prev_nature_points_value = curr_nature_points_value

func _on_algae_button_pressed():
	chosen_tree_changed.emit(PlantTypes.ALGAE)
	deactivate_destroy()
	hide_info()
