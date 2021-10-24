tool
extends "res://addons/zylann.hterrain/hterrain_water.gd"

const WaveBaker = preload("./wave_baker.gd")

const SHADER_PARAM_WAVE_AMPLITUDE = "u_wave_amplitude"
const SHADER_PARAM_WAVE_DENSITY = "u_wave_density"
const SHADER_PARAM_WAVE_KERNEL_POS = "u_wave_kernel_pos"
const SHADER_PARAM_WAVE_KERNEL_POS_DX = "u_wave_kernel_pos_dx"
const SHADER_PARAM_WAVE_KERNEL_POS_DY = "u_wave_kernel_pos_dy"
const SHADER_PARAM_WAVE_KERNEL_POS_DZ = "u_wave_kernel_pos_dz"
const SHADER_PARAM_WAVE_KERNEL_PARTICLE = "u_wave_kernel_particle"

const SHADER_PARAM_TIME = "time"
const SHADER_PARAM_DELTA_TIME = "delta_time"


var _wave_baker = WaveBaker.new()
var _wave_kernel_pos: Texture = ImageTexture.new()
var _wave_kernel_pos_dx: Texture = ImageTexture.new()
var _wave_kernel_pos_dy: Texture = ImageTexture.new()
var _wave_kernel_pos_dz: Texture = ImageTexture.new()
var _wave_kernel_particle: Texture = ImageTexture.new()

var _wave_amplitude := 0.1
var _wave_density := 20.0

var _use_editor_time := true
var _editor_time := 0.0
var _editor_delta_time := 0.0


func _get_property_list():
	# A lot of properties had to be exported like this instead of using `export`,
	# because Godot 3 does not support easy categorization and lacks some hints
	var props = [
		{
			"name": "Waves",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_CATEGORY
		},
		{
			"name": "wave_amplitude",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,1,or_greater",
		},
		{
			"name": "wave_density",
			"type": TYPE_REAL,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
			"hint": PROPERTY_HINT_RANGE,
			"hint_string": "0,50,or_greater",
		},
		{
			"name": "Debugging",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
		},
		{
			"name": "use_editor_time",
			"type": TYPE_BOOL,
			"usage": PROPERTY_USAGE_EDITOR,
		},
	]
	
#	props.append_array(._get_property_list())

	return props


func _get(key: String):
	if key == "wave_amplitude":
		return _wave_amplitude

	elif key == "wave_density":
		return _wave_density

	elif key == "use_editor_time":
		return _use_editor_time
	

func _set(key: String, value):
	if key == "wave_amplitude":
		_wave_amplitude = value
		_material_params_need_update = true

	elif key == "wave_density":
		_wave_density = value
		_material_params_need_update = true

	elif key == "use_editor_time":
		if is_inside_tree() and Engine.is_editor_hint():
			_use_editor_time = value


func _init():
	add_child(_wave_baker)
	_wave_baker.connect("finished", self, "_update_wave_kernel")
	_wave_baker.bake()


func _update_wave_kernel():
	var flags = Texture.FLAG_MIPMAPS | Texture.FLAG_FILTER;
	_wave_kernel_pos.create_from_image(_wave_baker._images[_wave_baker.OutputType.POSITION], flags)
	_wave_kernel_pos_dx.create_from_image(_wave_baker._images[_wave_baker.OutputType.POS_DX], flags)
	_wave_kernel_pos_dy.create_from_image(_wave_baker._images[_wave_baker.OutputType.POS_DY], flags)
	_wave_kernel_pos_dz.create_from_image(_wave_baker._images[_wave_baker.OutputType.POS_DZ], flags)
	_wave_kernel_particle.create_from_image(_wave_baker._images[_wave_baker.OutputType.PARTICLE], flags)
	_material_params_need_update = true


func _process(delta):
	._process(delta)
	
	if Engine.is_editor_hint():
		# Update time to animate waves in the editor
		if _use_editor_time:
			_editor_time += delta
			_material_params_need_update = true


func _update_material_params():
	._update_material_params()

	var lookdev_material : ShaderMaterial = _get_lookdev_material() if _lookdev_enabled else null

	if is_inside_tree():
		_material.set_shader_param(SHADER_PARAM_WAVE_AMPLITUDE, _wave_amplitude)
		_material.set_shader_param(SHADER_PARAM_WAVE_DENSITY, _wave_density)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS, _wave_kernel_pos)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DX, _wave_kernel_pos_dx)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DY, _wave_kernel_pos_dy)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DZ, _wave_kernel_pos_dz)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_PARTICLE, _wave_kernel_particle)

		if _use_editor_time:
			_material.set_shader_param(SHADER_PARAM_TIME, _editor_time)
			_material.set_shader_param(SHADER_PARAM_DELTA_TIME, _editor_delta_time)
		
		if lookdev_material != null:
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_AMPLITUDE, _wave_amplitude)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_DENSITY, _wave_density)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS, _wave_kernel_pos)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DX, _wave_kernel_pos_dx)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DY, _wave_kernel_pos_dy)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DZ, _wave_kernel_pos_dz)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_PARTICLE, _wave_kernel_particle)


func _get_region_aabb(cpos_x: int, cpos_y: int, lod: int) -> AABB:
	var aabb = ._get_region_aabb(cpos_x, cpos_y, lod)
	aabb.position.y = -_wave_amplitude * _wave_density
	aabb.size.y = 2.0 * _wave_amplitude * _wave_density
	return aabb


func _get_vertical_bounds(cpos_x: int, cpos_y: int, lod: int) -> Vector2:
	return _wave_amplitude * _wave_density * Vector2(-1.0, 1.0)
