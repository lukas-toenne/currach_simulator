# GPU-based particle simulation used by the water shader for dynamic waves.
# This outputs directly to a texture, unlike conventional Godot particle
# simulation which uses a vertex buffer.

tool
extends Node

const WaveParticleShader = preload("./shaders/wave_particles.shader")

var _debug_mesh = null

class Stage:
	var viewport: Viewport = null
	var rect: ColorRect = null
	
	var size: Vector2 setget _set_size, _get_size
	
	func _set_size(value):
		viewport.size = value
		rect.rect_size = value
	
	func _get_size():
		return viewport.size

	func _init(shader: Shader, clear: bool):
		var viewport_size = Vector2(2, 2)

		viewport = Viewport.new()
		viewport.size = viewport_size
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ONLY_NEXT_FRAME if clear else Viewport.CLEAR_MODE_NEVER
		viewport.render_target_v_flip = true
		viewport.world = World.new()
		viewport.own_world = true
		viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
		# Needs to be 3D_NO_EFFECTS usage and hdr=true, to enable full range float output
		viewport.usage = Viewport.USAGE_3D_NO_EFFECTS
		viewport.hdr = true
		# Disable sRGB transform on output colors
		viewport.keep_3d_linear = true

		rect = ColorRect.new()
		rect.anchor_left = 0
		rect.anchor_top = 1
		rect.anchor_right = 1
		rect.anchor_bottom = 0
		rect.margin_left = 0
		rect.margin_top = 0
		rect.margin_right = 0
		rect.margin_bottom = 0
		rect.rect_size = viewport_size
		rect.material = ShaderMaterial.new()
		rect.material.shader = shader
		
		viewport.add_child(rect)
	
#	func _notification(what):
#		if what == NOTIFICATION_PREDELETE:
#			viewport.queue_free()

var _particle_sim: Stage = null


func _ready():
	_particle_sim = Stage.new(WaveParticleShader, true)
	add_child(_particle_sim.viewport)
	
	# !!! XXX Small viewport sizes crash Godot !!!
	# https://github.com/godotengine/godot/issues/24702
	_particle_sim.size = Vector2(100, 100)

#	_debug_mesh = MeshInstance.new()
#	add_child(_debug_mesh)
#	_debug_mesh.mesh = load()


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
