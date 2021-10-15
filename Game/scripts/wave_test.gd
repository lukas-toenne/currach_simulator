tool
extends MeshInstance

export(bool) var play = true;
export(float) var speed = 1.0;
onready var time = 0.0

func _ready():
	get_surface_material(0).set_shader_param("time", time)
	get_surface_material(0).set_shader_param("delta_time", 0.0)

func _process(delta):
	if play:
		time += delta * speed
		if time > 1000.0:
			time -= 1000.0
	
	get_surface_material(0).set_shader_param("time", time)
	get_surface_material(0).set_shader_param("delta_time", delta)
