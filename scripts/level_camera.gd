extends Camera2D

var zoom_speed: float = 3.0
var zoom_min: float = 0.05
var zoom_max: float = 1.0
var zoom_margin: float = 0.1
var zoom_factor: float = 1.0
var drag_sensitivity: float = 1.0
var move_sensitivity: float = 100.0
var zooming = false
var zoom_pos = Vector2()


func _process(delta):
	zoom = lerp(zoom, zoom * zoom_factor, zoom_speed * delta)
	zoom = clamp(zoom, Vector2(zoom_min, zoom_min), Vector2(zoom_max, zoom_max))
	if not zooming:
		zoom_factor = 1.0
	if Input.is_action_pressed("left"):
		position += Vector2.LEFT * move_sensitivity * delta / zoom 
	if Input.is_action_pressed("right"):
		position += Vector2.RIGHT * move_sensitivity * delta / zoom 
	if Input.is_action_pressed("up"):
		position += Vector2.UP * move_sensitivity * delta / zoom 
	if Input.is_action_pressed("down"):
		position += Vector2.DOWN * move_sensitivity * delta / zoom 

func _input(event):
	if abs(zoom_pos.x - get_global_mouse_position().x) > zoom_margin or abs(zoom_pos.y - get_global_mouse_position().y) > zoom_margin :
		zoom_factor = 1.0
	if event is InputEventMouseButton:
		if event.is_pressed():
			zooming = true
			zoom_pos = get_global_mouse_position()
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_factor += 0.01 + zoom_speed
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_factor -= 0.01 + zoom_speed
		else:
			zooming = false
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		position = lerp(position, position - event.relative * drag_sensitivity / zoom, 0.8)
