# GPU-based particle simulation used by the water shader for dynamic waves.
# This outputs directly to a texture, unlike conventional Godot particle
# simulation which uses a vertex buffer.

tool
extends Node

const WaveParticleShader = preload("./shaders/wave_particles.shader")

class Stage:
	var viewport: Viewport = null
	var rect: ColorRect = null
	
	var size: Vector2 setget _set_size, _get_size
	
	func _set_size(value):
		viewport.size = value
		rect.rect_size = value
	
	func _get_size():
		return viewport.size

	func _init(shader: Shader):
		var viewport_size = Vector2(2, 2)

		viewport = Viewport.new()
		viewport.size = Vector2(viewport_size + 1, viewport_size + 1)
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME
		viewport.render_target_v_flip = true
		viewport.world = World.new()
		viewport.own_world = true
		viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
		viewport.usage = Viewport.USAGE_2D_NO_SAMPLING
		# Disable sRGB transform on output colors
		viewport.keep_3d_linear = true

		rect = ColorRect.new()
		rect.anchor_left = 0
		rect.anchor_top = 1
		rect.anchor_right = 0
		rect.anchor_bottom = 0
		rect.margin_left = 0
		rect.margin_top = 0
		rect.margin_right = 0
		rect.margin_bottom = 0
		rect.rect_size = viewport.size
		rect.material = ShaderMaterial.new()
		rect.material.shader = shader
		
		viewport.add_child(rect)
	
	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			viewport.queue_free()

var _particle_sim: Stage = null


func _ready():
	_particle_sim = Stage.new(WaveParticleShader)
	add_child(_particle_sim.viewport)


#func bake():
#	if _viewports.empty():
#		_setup_scene()
#
#	VisualServer.connect("frame_post_draw", self, "_on_VisualServer_post_draw")
#	VisualServer.draw()
#	yield(VisualServer, "frame_post_draw")
#	VisualServer.disconnect("frame_post_draw", self, "_on_VisualServer_post_draw")
#
#	emit_signal("finished")


#func _on_VisualServer_post_draw():
#	for i in _viewports.size():
#		_images[i] = _viewports[i].get_texture().get_data()
