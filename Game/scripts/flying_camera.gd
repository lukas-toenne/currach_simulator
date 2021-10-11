extends Camera3D

@export var mouse_sensitivity : float = 0.0003
@export var camera_speed : float = 0.1

const X_AXIS = Vector3(1, 0, 0)
const Y_AXIS = Vector3(0, 1, 0)

var is_mouse_motion = false
var mouse_speed = Vector2(0, 0)

var mouse_speed_x = 0
var mouse_speed_y = 0

@onready var camera_transform = self.get_transform()


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_physics_process(true)
	set_process_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(delta):
	if is_mouse_motion:
		is_mouse_motion = false
	else:
		mouse_speed = Vector2(0, 0)
	
	mouse_speed_x += mouse_speed.x * mouse_sensitivity
	mouse_speed_y += mouse_speed.y * mouse_sensitivity
	
	var rot_x = Quaternion(X_AXIS, -mouse_speed_y)
	var rot_y = Quaternion(Y_AXIS, -mouse_speed_x)
	
	if (Input.is_key_pressed(KEY_W)):
		camera_transform.origin += -self.get_transform().basis.z * camera_speed
	
	if (Input.is_key_pressed(KEY_S)):
		camera_transform.origin += self.get_transform().basis.z * camera_speed
	
	if (Input.is_key_pressed(KEY_A)):
		camera_transform.origin += -self.get_transform().basis.x * camera_speed
	
	if (Input.is_key_pressed(KEY_D)):
		camera_transform.origin += self.get_transform().basis.x * camera_speed
	
	if (Input.is_key_pressed(KEY_Q)):
		camera_transform.origin += -self.get_transform().basis.y * camera_speed
	
	if (Input.is_key_pressed(KEY_E)):
		camera_transform.origin += self.get_transform().basis.y * camera_speed
	
	self.set_transform(camera_transform * Transform3D(rot_y) * Transform3D(rot_x))


func _input(event):
	if event is InputEventMouseMotion:
		is_mouse_motion = true
		mouse_speed = event.relative

	if Input.is_action_just_pressed("pause"):
		_on_pause_pressed()

func _on_pause_pressed():
	get_tree().paused = !get_tree().paused
