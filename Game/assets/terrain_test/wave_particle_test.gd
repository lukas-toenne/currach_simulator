extends Node


func _ready():
	var vp = get_node("WaveParticles")._particle_sim.viewport
	var rect = get_node("ColorRect")
	var mat = rect.material as ShaderMaterial
	mat.set_shader_param("viewport_tex", vp.get_texture())
