extends Node

onready var menu = get_node("/root/Menu")

var level = null

const SHOW_FPS = false
const TIMER_LIMIT = 2.0
var timer = 0.0

func _process(_delta):
	if Input.is_action_just_pressed("exit"):
		_on_exit_pressed()
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen

	if SHOW_FPS:
		timer += _delta
		if timer > TIMER_LIMIT:
			print("fps: " + str(Engine.get_frames_per_second()))
			timer = 0.0

func _on_exit_pressed():
	if is_instance_valid(level):
		# Go back to main menu.
		level.queue_free()
		menu.show()
	else:
		# In main menu, exit the game.
		get_tree().quit()

func load_scene(boat):
	level = load("res://puddle.tscn").instance()
	get_parent().add_child(level)
	
	var vessel = load(boat).instance()
	level.add_child(vessel)
	vessel.set_name("boat")
	vessel.wave_sampler = level.get_node("WaveSampler")
	vessel.transform = level.get_node("InstancePos").transform

#	level.get_node("Camera").target_node = vessel
#	level.get_node("Back").connect("pressed", self, "_on_Back_pressed")
