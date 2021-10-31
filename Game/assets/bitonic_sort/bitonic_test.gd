extends Node2D

const RandomizeShader = preload("bitonic_test_randomize.gdshader")
const StageShader = preload("bitonic_test_stage.gdshader")

const VIEWPORT_SIZE := Vector2(64, 64);


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
		viewport.render_target_clear_mode = Viewport.CLEAR_MODE_ALWAYS if clear else Viewport.CLEAR_MODE_NEVER
		viewport.render_target_v_flip = true
		viewport.world = World.new()
		viewport.own_world = true
		viewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
		# Needs to be 3D_NO_EFFECTS usage and hdr=true, to enable full range float output
		viewport.usage = Viewport.USAGE_3D_NO_EFFECTS
		viewport.hdr = true
		# Disable sRGB transform on output colors
		viewport.keep_3d_linear = true
		viewport.transparent_bg = false

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


enum OutputStage { None, Randomized }

export(OutputStage) var output_stage setget _set_output_stage, _get_output_stage
var _output_stage: int = OutputStage.None

var _material_params_need_update := false
var _stage_randomized: Stage = null
var _stage_endpoints := []
var _stage_passes := []

var _export_image = false


func _init():
	_stage_randomized = Stage.new(RandomizeShader, true)
	_stage_randomized.size = VIEWPORT_SIZE
	
	var num_values = VIEWPORT_SIZE[0] * VIEWPORT_SIZE[1]
	var num_stages_needed := int(ceil(log(num_values) / log(2.0)))
	print("NEEDED STAGES: ", num_stages_needed, " (=> 2^n=", 2 << num_stages_needed, " >= ", num_values)
	
	var last_stage = _stage_randomized
	for s in num_stages_needed:
		for p in range(s, -1, -1):
			var stage = Stage.new(StageShader, true)
			stage.size = VIEWPORT_SIZE
			stage.rect.material.set_shader_param("u_tex", last_stage.viewport.get_texture())
			stage.rect.material.set_shader_param("u_tex_size", [VIEWPORT_SIZE[0], VIEWPORT_SIZE[1]])
			stage.rect.material.set_shader_param("u_stage", s)
			stage.rect.material.set_shader_param("u_pass", p)
			_stage_passes.append(stage)
			
			last_stage = stage
		
		print("STAGE ", s)
		_stage_endpoints.append(last_stage)

	print("STAGES COMPLETE")


func _enter_tree():
	add_child(_stage_randomized.viewport)
	for stage in _stage_passes:
		add_child(stage.viewport)
	if !Engine.is_editor_hint():
		VisualServer.connect("frame_pre_draw", self, "_on_VisualServer_pre_draw")
		VisualServer.connect("frame_post_draw", self, "_on_VisualServer_post_draw")
#		OS.window_size = VIEWPORT_SIZE * 4.0


func _exit_tree():
	# Clean up references
	_update_material_params()

	remove_child(_stage_randomized.viewport)
	for stage in _stage_passes:
		remove_child(stage.viewport)
	if !Engine.is_editor_hint():
		VisualServer.disconnect("frame_pre_draw", self, "_on_VisualServer_pre_draw")
		VisualServer.disconnect("frame_post_draw", self, "_on_VisualServer_post_draw")


func _on_VisualServer_pre_draw():
	_update_material_params()


func _on_VisualServer_post_draw():
	if _export_image:
		_export_image = false
		var stage = _get_output_stage_data()
		if stage:
			var vp = $ColorRect.get_viewport()
#			var vp = stage.viewport as Viewport
			var img = vp.get_texture().get_data()
			img.save_png("res://assets/bitonic_sort/stage_" + str(_output_stage) + ".png")


func _get_output_stage_data() -> Stage:
	var stage: Stage = null
	if _output_stage == OutputStage.Randomized:
		stage = _stage_randomized
	else:
		var index = _output_stage - OutputStage.Randomized
		stage = _stage_endpoints[index] if index < _stage_endpoints.size() else null
	return stage


func _update_material_params():
	if !_material_params_need_update:
		return
	_material_params_need_update = false

	if !Engine.is_editor_hint() and is_inside_tree():
		var stage := _get_output_stage_data()
		var tex := stage.viewport.get_texture() if stage and stage.viewport else null
		$ColorRect.material.set_shader_param("u_tex", tex)

#	_particle_sim.rect.material.set_shader_param("u_reset", _do_reset)
#	if _do_reset:
#		# Flag for shader param update in the next frame to clear the reset flag again.
#		_do_reset = false
#		_material_params_need_update = true


func _set_output_stage(value: int):
	_output_stage = value;
	_material_params_need_update = true


func _get_output_stage() -> int:
	return _output_stage


func _input(event):
	if event.is_action_pressed("ui_right"):
		_set_output_stage(min(_output_stage + 1, OutputStage.Randomized + _stage_endpoints.size()))
		print("Switched output stage to ", _output_stage)
	if event.is_action_pressed("ui_left"):
		_set_output_stage(max(_output_stage - 1, OutputStage.None))
		print("Switched output stage to ", _output_stage)
	if event.is_action_pressed("ui_accept"):
		_export_image = true
