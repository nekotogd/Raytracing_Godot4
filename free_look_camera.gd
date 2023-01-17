extends Camera3D

@export var mouse_sensitivity : float = 1.0
@export var move_speed : float = 0.1

func _input(event):
	if event is InputEventMouseMotion:
		if Input.is_action_pressed("RMB"):
			rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
			rotate_object_local(Vector3(1.0, 0.0, 0.0), deg_to_rad(event.relative.y * mouse_sensitivity))

func _process(_delta):
	if Input.is_action_pressed("RMB"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_move()

func _move():
	var input_vector := Vector3.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.z = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector.y = Input.get_action_strength("move_v_up") - Input.get_action_strength("move_v_down")
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	
	var displacement := Vector3.ZERO
	displacement = global_transform.basis.z * move_speed * input_vector.z
	global_transform.origin += displacement
	
	displacement = global_transform.basis.x * move_speed * input_vector.x
	global_transform.origin += displacement
	
	displacement = global_transform.basis.y * move_speed * input_vector.y
	global_transform.origin -= displacement
	# should be += displacement, but my compute shader is negative y-up for some reason
	# TODO: Debug why the compute shader is negative y-up
