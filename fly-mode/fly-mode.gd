extends Camera3D

@export var speed: float = 10.0
@export var sensitivity: float = 0.1
@export var fast_speed_multiplier: float = 3.0

var is_active: bool = false
var rotation_x: float = 0.0
var rotation_y: float = 0.0

func _ready():
	rotation_x = rotation_degrees.x
	rotation_y = rotation_degrees.y

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		is_active = !is_active

		if is_active:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if is_active and event is InputEventMouseMotion:
		rotation_y -= event.relative.x * sensitivity
		rotation_x -= event.relative.y * sensitivity
		rotation_x = clamp(rotation_x, -89, 89)

		rotation_degrees = Vector3(rotation_x, rotation_y, 0)

func _process(delta):
	if not is_active:
		return

	var direction = Vector3.ZERO
	var current_speed = speed

	if Input.is_key_pressed(KEY_SHIFT):
		current_speed *= fast_speed_multiplier

	var basis = global_transform.basis

	if Input.is_key_pressed(KEY_W):
		direction -= basis.z
	if Input.is_key_pressed(KEY_S):
		direction += basis.z
	if Input.is_key_pressed(KEY_A):
		direction -= basis.x
	if Input.is_key_pressed(KEY_D):
		direction += basis.x
	if Input.is_key_pressed(KEY_E):
		direction -= basis.y
	if Input.is_key_pressed(KEY_Q):
		direction += basis.y

	if direction != Vector3.ZERO:
		global_position += direction.normalized() * current_speed * delta
