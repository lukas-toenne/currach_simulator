extends Camera

class_name BoatCamera

export(float) var mouse_sensitivity = 0.0003
export(float) var camera_speed = 0.1
export(float) var camera_distance = 8.0

const X_AXIS = Vector3(1, 0, 0)
const Y_AXIS = Vector3(0, 1, 0)

var target_node = null setget _set_target_node

var is_mouse_motion = false
var mouse_speed = Vector2(0, 0)

var mouse_angle_x = 0
var mouse_angle_y = 0

onready var camera_offset = Vector3(0, 0, 0)
onready var camera_rotation = Basis.IDENTITY


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_physics_process(true)
	set_process_input(true)
	pause_mode = Node.PAUSE_MODE_PROCESS

func _set_target_node(value):
	target_node = value

func _physics_process(delta):
	if is_mouse_motion:
		is_mouse_motion = false
	else:
		mouse_speed = Vector2(0, 0)
	
	mouse_angle_x += mouse_speed.x * mouse_sensitivity
	mouse_angle_y += mouse_speed.y * mouse_sensitivity
	
	var rot_x = Quat(X_AXIS, -mouse_angle_y)
	var rot_y = Quat(Y_AXIS, -mouse_angle_x)
	camera_rotation = Basis(rot_y * rot_x)
	
	if (Input.is_key_pressed(KEY_W)):
		camera_offset += -self.get_transform().basis.z * camera_speed
	
	if (Input.is_key_pressed(KEY_S)):
		camera_offset += self.get_transform().basis.z * camera_speed
	
	if (Input.is_key_pressed(KEY_A)):
		camera_offset += -self.get_transform().basis.x * camera_speed
	
	if (Input.is_key_pressed(KEY_D)):
		camera_offset += self.get_transform().basis.x * camera_speed
	
	if (Input.is_key_pressed(KEY_Q)):
		camera_offset += -self.get_transform().basis.y * camera_speed
	
	if (Input.is_key_pressed(KEY_E)):
		camera_offset += self.get_transform().basis.y * camera_speed
	
	var origin = camera_rotation * Vector3(0, 0, camera_distance) + camera_offset
	if target_node != null:
		origin += target_node.transform.origin
	self.set_transform(Transform(camera_rotation, origin))


func _input(event):
	if event is InputEventMouseMotion:
		is_mouse_motion = true
		mouse_speed = event.relative
	
	if Input.is_action_just_pressed("pause"):
		_on_pause_pressed()

func _on_pause_pressed():
	get_tree().paused = !get_tree().paused
