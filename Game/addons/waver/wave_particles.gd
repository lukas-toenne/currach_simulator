# GPU-based particle simulation used by the water shader for dynamic waves.
# This outputs directly to a texture, unlike conventional Godot particle
# simulation which uses a vertex buffer.

extends Node

const WaveParticleShader = preload("./shaders/wave_particles.shader")

# Make sure water shaders are updated when changing width.
const WAVE_PARTICLE_PIXELS = 4;
const WAVE_PARTICLE_TEXTURE_WIDTH = 1024

#var _num_particles := 0
var _do_reset := false

var _material_params_need_update := false


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
		var viewport_size = Vector2(100, 100)

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
		viewport.transparent_bg = true

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


func _init():
	_particle_sim = Stage.new(WaveParticleShader, true)


func _enter_tree():
	add_child(_particle_sim.viewport)
	if !Engine.is_editor_hint():
		VisualServer.connect("frame_pre_draw", self, "_on_VisualServer_pre_draw")


func _exit_tree():
	remove_child(_particle_sim.viewport)
	if !Engine.is_editor_hint():
		VisualServer.disconnect("frame_pre_draw", self, "_on_VisualServer_pre_draw")


func _ready():
	_update_particle_viewport()
	reset()


func _on_VisualServer_pre_draw():
	_update_material_params()


func _update_material_params():
	if !_material_params_need_update:
		return
	_material_params_need_update = false

	_particle_sim.rect.material.set_shader_param("u_reset", _do_reset)
	if _do_reset:
		# Flag for shader param update in the next frame to clear the reset flag again.
		_do_reset = false
		_material_params_need_update = true


func get_particle_texture():
	if _particle_sim and _particle_sim.viewport:
		return _particle_sim.viewport.get_texture()


func reset():
	_do_reset = true
	_material_params_need_update = true


#func get_num_particles():
#	return _num_particles


#func clear_particles():
#	_num_particles = 0
#	_update_particle_viewport()
#	_material_params_need_update = true


#func set_num_particles(num_particles: int):
#	_num_particles = num_particles
#	_update_particle_viewport()
#	_material_params_need_update = true


func _update_particle_viewport():
	if _particle_sim:
#		var num_pixels := _num_particles * WAVE_PARTICLE_PIXELS
#		var num_rows := (num_pixels + WAVE_PARTICLE_TEXTURE_WIDTH - 1) / WAVE_PARTICLE_TEXTURE_WIDTH
		var num_rows = 8
		
		# !!! XXX Smaller viewport sizes crash Godot !!!
		# https://github.com/godotengine/godot/issues/24702
		num_rows = max(num_rows, 4)
		
		_particle_sim.size = Vector2(WAVE_PARTICLE_TEXTURE_WIDTH, num_rows)
