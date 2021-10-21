# Bakes a single wave kernel as a texture with mipmaps for filtering.

tool
extends Node

const WaveKernelShader = preload("../shaders/wave_kernel.shader")

# Must be power of two
const DEFAULT_VIEWPORT_SIZE = 512

signal finished

enum OutputType { POSITION, POS_DX, POS_DY, POS_DZ, PARTICLE, UV }

var _viewports := []
var _rects := []
var _images := []


func bake():
	if _viewports.empty():
		_setup_scene()
	
	VisualServer.connect("frame_post_draw", self, "_on_VisualServer_post_draw")
	VisualServer.draw()
	yield(VisualServer, "frame_post_draw")
	VisualServer.disconnect("frame_post_draw", self, "_on_VisualServer_post_draw")

	emit_signal("finished")


func _on_VisualServer_post_draw():
	for i in _viewports.size():
		_images[i] = _viewports[i].get_texture().get_data()


func _setup_scene():
	_setup_viewport(OutputType.POSITION)
	_setup_viewport(OutputType.POS_DX)
	_setup_viewport(OutputType.POS_DY)
	_setup_viewport(OutputType.POS_DZ)
	_setup_viewport(OutputType.PARTICLE)

func _setup_viewport(output_type: int):
	var viewport_size = DEFAULT_VIEWPORT_SIZE

	var viewport = Viewport.new()
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

	var rect = ColorRect.new()
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
	rect.material.shader = WaveKernelShader
	rect.material.set_shader_param("output_type", output_type)
	viewport.add_child(rect)
	
	add_child(viewport)
	
	_viewports.resize(output_type + 1)
	_rects.resize(output_type + 1)
	_images.resize(output_type + 1)
	_viewports[output_type] = viewport
	_rects[output_type] = rect


func _cleanup_scene():
	for viewport in _viewports:
		viewport.queue_free()
	_viewports.clear()
	_rects.clear()
