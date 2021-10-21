tool
extends Spatial

const QuadTreeLod = preload("./util/quad_tree_lod.gd")
const Mesher = preload("./hterrain_mesher.gd")
const Grid = preload("./util/grid.gd")
const HTerrainData = preload("./hterrain_data.gd")
const HTerrainChunk = preload("./hterrain_chunk.gd")
const HTerrainChunkDebug = preload("./hterrain_chunk_debug.gd")
const Util = preload("./util/util.gd")
const HTerrainTextureSet = preload("./hterrain_texture_set.gd")
const WaveBaker = preload("./util/wave_baker.gd")
const Logger = preload("./util/logger.gd")

const SHADER_DEEP_WATER = "DeepWater"
const SHADER_CUSTOM = "Custom"

const MIN_MAP_SCALE = 0.01

const _SHADER_TYPE_HINT_STRING = str(
	"DeepWater", ",",
	"Custom"
)

const _builtin_shaders = {
	SHADER_DEEP_WATER: {
		path = "res://addons/zylann.hterrain/shaders/deep_water.shader",
	},
}

const _LOOKDEV_SHADER_PATH = "res://addons/zylann.hterrain/shaders/lookdev.shader"

const SHADER_PARAM_INVERSE_WATER_TRANSFORM = "u_water_inverse_transform"
const SHADER_PARAM_INVERSE_TERRAIN_TRANSFORM = "u_terrain_inverse_transform"
const SHADER_PARAM_NORMAL_BASIS = "u_terrain_normal_basis"

const SHADER_PARAM_WAVE_AMPLITUDE = "u_wave_amplitude"
const SHADER_PARAM_WAVE_DENSITY = "u_wave_density"
const SHADER_PARAM_WAVE_KERNEL_POS = "u_wave_kernel_pos"
const SHADER_PARAM_WAVE_KERNEL_POS_DX = "u_wave_kernel_pos_dx"
const SHADER_PARAM_WAVE_KERNEL_POS_DY = "u_wave_kernel_pos_dy"
const SHADER_PARAM_WAVE_KERNEL_POS_DZ = "u_wave_kernel_pos_dz"
const SHADER_PARAM_WAVE_KERNEL_PARTICLE = "u_wave_kernel_particle"

const SHADER_PARAM_GROUND_PREFIX = "u_ground_" # + name + _0, _1, _2, _3...

const SHADER_PARAM_TIME = "time"
const SHADER_PARAM_DELTA_TIME = "delta_time"

# Those parameters are filtered out in the inspector,
# because they are not supposed to be set through it
const _api_shader_params = {
	"u_terrain_heightmap": true,
	"u_terrain_normalmap": true,
	"u_terrain_colormap": true,
	"u_terrain_splatmap": true,
	"u_terrain_splatmap_1": true,
	"u_terrain_splatmap_2": true,
	"u_terrain_splatmap_3": true,
	"u_terrain_splat_index_map": true,
	"u_terrain_splat_weight_map": true,

	"u_terrain_inverse_transform": true,
	"u_terrain_normal_basis": true,

	"u_ground_albedo_bump_0": true,
	"u_ground_albedo_bump_1": true,
	"u_ground_albedo_bump_2": true,
	"u_ground_albedo_bump_3": true,

	"u_ground_normal_roughness_0": true,
	"u_ground_normal_roughness_1": true,
	"u_ground_normal_roughness_2": true,
	"u_ground_normal_roughness_3": true,

	"u_ground_albedo_bump_array": true,
	"u_ground_normal_roughness_array": true
}

const _api_shader_ground_albedo_params = {
	"u_ground_albedo_bump_0": true,
	"u_ground_albedo_bump_1": true,
	"u_ground_albedo_bump_2": true,
	"u_ground_albedo_bump_3": true
}

const _ground_texture_array_shader_params = [
	"u_ground_albedo_bump_array",
	"u_ground_normal_roughness_array"
]

const _splatmap_shader_params = [
	"u_terrain_splatmap",
	"u_terrain_splatmap_1",
	"u_terrain_splatmap_2",
	"u_terrain_splatmap_3"
]

const MIN_CHUNK_SIZE = 16
const MAX_CHUNK_SIZE = 64

const MIN_CHUNK_SUBDIV = 1
const MAX_CHUNK_SUBDIV = 64

# Same as HTerrainTextureSet.get_texture_type_name, used for shader parameter names.
# Indexed by HTerrainTextureSet.TYPE_*
const _ground_enum_to_name = [
	"albedo_bump",
	"normal_roughness"
]

const _DEBUG_AABB = false

signal transform_changed(global_transform)

export(float, 0.0, 1.0) var ambient_wind := 0.0 setget set_ambient_wind
export(int, 2, 5) var lod_scale := 2.0 setget set_lod_scale, get_lod_scale

# TODO Replace with `size` in world units?
# Prefer using this instead of scaling the node's transform.
# Spatial.scale isn't used because it's not suitable for terrains,
# it would scale grass too and other environment objects.
export var map_scale := Vector3(1, 1, 1) setget set_map_scale

var _custom_shader : Shader = null
var _shader_type := SHADER_DEEP_WATER
var _material := ShaderMaterial.new()
var _material_params_need_update := false

var _render_layer_mask := 1

# Actual number of textures supported by the shader currently selected
var _ground_texture_count_cache = 0

var _used_splatmaps_count_cache := 0
var _is_using_indexed_splatmap := false

var _texture_set := HTerrainTextureSet.new()
var _texture_set_migration_textures = null

var _data: HTerrainData = null

var _mesher := Mesher.new()
var _lodder := QuadTreeLod.new()
var _viewer_pos_world := Vector3()

# [lod][z][x] -> chunk
# This container owns chunks
var _chunks := []
var _chunk_size: int = 32
var _chunk_subdiv: int = 4
var _pending_chunk_updates := []

var _detail_layers := []

# Stats & debug
var _updated_chunks := 0
var _logger = Logger.get_for(self)

var _lookdev_enabled := false
var _lookdev_material : ShaderMaterial

var _use_editor_time := true
var _editor_time := 0.0
var _editor_delta_time := 0.0

var _wave_baker = WaveBaker.new()
var _wave_kernel_pos: Texture = ImageTexture.new()
var _wave_kernel_pos_dx: Texture = ImageTexture.new()
var _wave_kernel_pos_dy: Texture = ImageTexture.new()
var _wave_kernel_pos_dz: Texture = ImageTexture.new()
var _wave_kernel_particle: Texture = ImageTexture.new()

var _wave_amplitude := 0.1
var _wave_density := 20.0


func _init():
	_logger.debug("Create HeightMap")
	# This sets up the defaults. They may be overriden shortly after by the scene loader.

	_lodder.set_callbacks( \
		funcref(self, "_cb_make_chunk"), \
		funcref(self,"_cb_recycle_chunk"), \
		funcref(self, "_cb_get_vertical_bounds"))

	set_notify_transform(true)
	
	add_child(_wave_baker)
	_wave_baker.connect("finished", self, "_update_wave_kernel")
	_wave_baker.bake()

#	# TODO Temporary!
#	# This is a workaround for https://github.com/godotengine/godot/issues/24488
#	_material.set_shader_param("u_ground_uv_scale", 20)
#	_material.set_shader_param("u_ground_uv_scale_vec4", Color(20, 20, 20, 20))
#	_material.set_shader_param("u_depth_blending", true)

	_material.shader = load(_builtin_shaders[_shader_type].path)

	_texture_set.connect("changed", self, "_on_texture_set_changed")


func _update_wave_kernel():
	var flags = Texture.FLAG_MIPMAPS | Texture.FLAG_FILTER;
	_wave_kernel_pos.create_from_image(_wave_baker._images[_wave_baker.OutputType.POSITION], flags)
	_wave_kernel_pos_dx.create_from_image(_wave_baker._images[_wave_baker.OutputType.POS_DX], flags)
	_wave_kernel_pos_dy.create_from_image(_wave_baker._images[_wave_baker.OutputType.POS_DY], flags)
	_wave_kernel_pos_dz.create_from_image(_wave_baker._images[_wave_baker.OutputType.POS_DZ], flags)
	_wave_kernel_particle.create_from_image(_wave_baker._images[_wave_baker.OutputType.PARTICLE], flags)
	_material_params_need_update = true

func _get_property_list():
	# A lot of properties had to be exported like this instead of using `export`,
	# because Godot 3 does not support easy categorization and lacks some hints
	var props = [
		{
			# Terrain data is exposed only as a path in the editor,
			# because it can only be saved if it has a directory selected.
			# That property is not used in scene saving (data is instead).
			"name": "data_directory",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_EDITOR,
			"hint": PROPERTY_HINT_DIR
		},
		{
			# The actual data resource is only exposed for storage.
			# I had to name it so that Godot won't try to assign _data directly
			# instead of using the setter I made...
			"name": "_terrain_data",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_STORAGE,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			# This actually triggers `ERROR: Cannot get class`,
			# if it were to be shown in the inspector.
			# See https://github.com/godotengine/godot/pull/41264
			"hint_string": "HTerrainData"
		},
		{
			"name": "chunk_size",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
			#"hint": PROPERTY_HINT_ENUM,
			"hint_string": "16, 32"
		},
		{
			"name": "chunk_subdiv",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
			#"hint": PROPERTY_HINT_ENUM,
			"hint_string": "1, 32"
		},
		{
			"name": "Rendering",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
		},
		{
			"name": "shader_type",
			"type": TYPE_STRING,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": _SHADER_TYPE_HINT_STRING
		},
		{
			"name": "custom_shader",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Shader"
		},
		{
			"name": "texture_set",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
			"hint": PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string": "Resource"
			# TODO Cannot properly hint the type of the resource in the inspector. 
			# This triggers `ERROR: Cannot get class 'HTerrainTextureSet'`
			# See https://github.com/godotengine/godot/pull/41264
			#"hint_string": "HTerrainTextureSet"
		},
		{
			"name": "render_layers",
			"type": TYPE_INT,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE,
			"hint": PROPERTY_HINT_LAYERS_3D_RENDER
		},
		{
			"name": "Waves",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP
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

	if _material.shader != null:
		var shader_params := VisualServer.shader_get_param_list(_material.shader.get_rid())
		for p in shader_params:
			if _api_shader_params.has(p.name):
				continue
			var cp := {}
			for k in p:
				cp[k] = p[k]
			cp.name = str("shader_params/", p.name)
			props.append(cp)

	return props


func _get(key: String):
	if key == "data_directory":
		return _get_data_directory()

	if key == "_terrain_data":
		if _data == null or _data.resource_path == "":
			# Consider null if the data is not set or has no path,
			# because in those cases we can't save the terrain properly
			return null
		else:
			return _data

	if key == "texture_set":
		return get_texture_set()

	elif key == "shader_type":
		return get_shader_type()

	elif key == "custom_shader":
		return get_custom_shader()

	elif key.begins_with("shader_params/"):
		var param_name = key.right(len("shader_params/"))
		return get_shader_param(param_name)

	elif key == "chunk_size":
		return _chunk_size

	elif key == "chunk_subdiv":
		return _chunk_subdiv

	elif key == "render_layers":
		return get_render_layer_mask()

	elif key == "wave_amplitude":
		return _wave_amplitude

	elif key == "wave_density":
		return _wave_density

	elif key == "use_editor_time":
		return _use_editor_time
	

func _set(key: String, value):
	if key == "data_directory":
		_set_data_directory(value)

	# Can't use setget when the exported type is custom,
	# because we were also are forced to use _get_property_list...
	elif key == "_terrain_data":
		set_data(value)

	elif key == "texture_set":
		set_texture_set(value)

	# Legacy, left for migration from 1.4
	if key.begins_with("ground/"):
		for ground_texture_type in HTerrainTextureSet.TYPE_COUNT:
			var type_name = _ground_enum_to_name[ground_texture_type]
			if key.begins_with(str("ground/", type_name, "_")):
				var i = key.right(len(key) - 1).to_int()
				if _texture_set_migration_textures == null:
					_texture_set_migration_textures = []
				while i >= len(_texture_set_migration_textures):
					_texture_set_migration_textures.append([null, null])
				var texs = _texture_set_migration_textures[i]
				texs[ground_texture_type] = value

	elif key == "shader_type":
		set_shader_type(value)

	elif key == "custom_shader":
		set_custom_shader(value)

	elif key.begins_with("shader_params/"):
		var param_name = key.right(len("shader_params/"))
		set_shader_param(param_name, value)

	elif key == "chunk_size":
		set_chunk_size(value)

	elif key == "chunk_subdiv":
		set_chunk_subdiv(value)

	elif key == "render_layers":
		return set_render_layer_mask(value)

	elif key == "wave_amplitude":
		_wave_amplitude = value
		_material_params_need_update = true

	elif key == "wave_density":
		_wave_density = value
		_material_params_need_update = true

	elif key == "use_editor_time":
		if is_inside_tree() and Engine.is_editor_hint():
			_use_editor_time = value


func get_texture_set() -> HTerrainTextureSet:
	return _texture_set


func set_texture_set(new_set: HTerrainTextureSet):
	if _texture_set == new_set:
		return

	if _texture_set != null:
		# TODO This causes `ERROR: Nonexistent signal 'changed' in [Resource:36653]` for some reason
		_texture_set.disconnect("changed", self, "_on_texture_set_changed")

	_texture_set = new_set

	if _texture_set != null:
		_texture_set.connect("changed", self, "_on_texture_set_changed")

	_material_params_need_update = true


func _on_texture_set_changed():
	_material_params_need_update = true
	Util.update_configuration_warning(self, false)


func get_shader_param(param_name: String):
	return _material.get_shader_param(param_name)


func set_shader_param(param_name: String, v):
	_material.set_shader_param(param_name, v)


func set_render_layer_mask(mask: int):
	_render_layer_mask = mask
	_for_all_chunks(SetRenderLayerMaskAction.new(mask))


func get_render_layer_mask() -> int:
	return _render_layer_mask


func _set_data_directory(dirpath: String):
	if dirpath != _get_data_directory():
		if dirpath == "":
			set_data(null)
		else:
			var fpath := dirpath.plus_file(HTerrainData.META_FILENAME)
			var f := File.new()
			if f.file_exists(fpath):
				# Load existing
				var d = load(fpath)
				set_data(d)
			else:
				# Create new
				var d := HTerrainData.new()
				d.resource_path = fpath
				set_data(d)
	else:
		_logger.warn("Setting twice the same terrain directory??")


func _get_data_directory() -> String:
	if _data != null:
		return _data.resource_path.get_base_dir()
	return ""


func _for_all_chunks(action):
	for lod in range(len(_chunks)):
		var grid = _chunks[lod]
		for y in range(len(grid)):
			var row = grid[y]
			for x in range(len(row)):
				var chunk = row[x]
				if chunk != null:
					action.exec(chunk)


func get_chunk_size() -> int:
	return _chunk_size


func set_chunk_size(p_cs: int):
	assert(typeof(p_cs) == TYPE_INT)
	_logger.debug(str("Setting chunk size to ", p_cs))
	var cs = Util.next_power_of_two(p_cs)
	if cs < MIN_CHUNK_SIZE:
		cs = MIN_CHUNK_SIZE
	if cs > MAX_CHUNK_SIZE:
		cs = MAX_CHUNK_SIZE
	if p_cs != cs:
		_logger.debug(str("Chunk size snapped to ", cs))
	if cs == _chunk_size:
		return
	_chunk_size = cs
	_reset_ground_chunks()


func get_chunk_subdiv() -> int:
	return _chunk_subdiv


func set_chunk_subdiv(p_cs: int):
	assert(typeof(p_cs) == TYPE_INT)
	_logger.debug(str("Setting chunk subdivision to ", p_cs))
	var cs = Util.next_power_of_two(p_cs)
	if cs < MIN_CHUNK_SUBDIV:
		cs = MIN_CHUNK_SUBDIV
	if cs > MAX_CHUNK_SUBDIV:
		cs = MAX_CHUNK_SUBDIV
	if p_cs != cs:
		_logger.debug(str("Chunk subdivision snapped to ", cs))
	if cs == _chunk_subdiv:
		return
	_chunk_subdiv = cs
	_reset_ground_chunks()


func set_map_scale(p_map_scale: Vector3):
	if map_scale == p_map_scale:
		return
	p_map_scale.x = max(p_map_scale.x, MIN_MAP_SCALE)
	p_map_scale.y = max(p_map_scale.y, MIN_MAP_SCALE)
	p_map_scale.z = max(p_map_scale.z, MIN_MAP_SCALE)
	map_scale = p_map_scale
	_on_transform_changed()


# Gets the global transform to apply to terrain geometry,
# which is different from Spatial.global_transform gives
# (that one must only have translation)
func get_internal_transform() -> Transform:
	# Terrain can only be self-scaled and translated,
	return Transform(Basis().scaled(map_scale / float(_chunk_subdiv)), global_transform.origin)


func _notification(what: int):
	match what:
		NOTIFICATION_PREDELETE:
			_logger.debug("Destroy HTerrain")
			# Note: might get rid of a circular ref in GDScript port
			_clear_all_chunks()

		NOTIFICATION_ENTER_WORLD:
			_logger.debug("Enter world")

			if _texture_set_migration_textures != null \
			and _texture_set.get_slots_count() == 0:
				# Convert from 1.4 textures properties to HTerrainTextureSet
				# TODO Unfortunately this might not always work,
				# once again because Godot wants the editor's UndoRedo to have modified the
				# resource for it to be saved... which sucks, sucks, and sucks.
				# I'll never say it enough.
				_texture_set.set_mode(HTerrainTextureSet.MODE_TEXTURES)
				while _texture_set.get_slots_count() < len(_texture_set_migration_textures):
					_texture_set.insert_slot(-1)
				for slot_index in len(_texture_set_migration_textures):
					var texs = _texture_set_migration_textures[slot_index]
					for type in len(texs):
						_texture_set.set_texture(slot_index, type, texs[type])
				_texture_set_migration_textures = null

			_for_all_chunks(EnterWorldAction.new(get_world()))

		NOTIFICATION_EXIT_WORLD:
			_logger.debug("Exit world")
			_for_all_chunks(ExitWorldAction.new())

		NOTIFICATION_TRANSFORM_CHANGED:
			_on_transform_changed()

		NOTIFICATION_VISIBILITY_CHANGED:
			_logger.debug("Visibility changed")
			_for_all_chunks(VisibilityChangedAction.new(is_visible_in_tree()))


func _on_transform_changed():
	_logger.debug("Transform changed")

	if not is_inside_tree():
		# The transform and other properties can be set by the scene loader,
		# before we enter the tree
		return

	var gt = get_internal_transform()

	_for_all_chunks(TransformChangedAction.new(gt))

	_material_params_need_update = true

	emit_signal("transform_changed", gt)


func _enter_tree():
	_logger.debug("Enter tree")

	set_process(true)


func _clear_all_chunks():
	# The lodder has to be cleared because otherwise it will reference dangling pointers
	_lodder.clear()

	#_for_all_chunks(DeleteChunkAction.new())

	for i in range(len(_chunks)):
		_chunks[i].clear()


func _get_chunk_at(pos_x: int, pos_y: int, lod: int) -> HTerrainChunk:
	if lod < len(_chunks):
		return Grid.grid_get_or_default(_chunks[lod], pos_x, pos_y, null)
	return null


func get_data() -> HTerrainData:
	return _data


func has_data() -> bool:
	return _data != null


func set_data(new_data: HTerrainData):
	assert(new_data == null or new_data is HTerrainData)

	_logger.debug(str("Set new data ", new_data))

	if _data == new_data:
		return

	if has_data():
		_logger.debug("Disconnecting old HeightMapData")
		_data.disconnect("resolution_changed", self, "_on_data_resolution_changed")
		_data.disconnect("region_changed", self, "_on_data_region_changed")
		_data.disconnect("map_changed", self, "_on_data_map_changed")
		_data.disconnect("map_added", self, "_on_data_map_added")
		_data.disconnect("map_removed", self, "_on_data_map_removed")

	_data = new_data

	# Note: the order of these two is important
	_clear_all_chunks()

	if has_data():
		_logger.debug("Connecting new HeightMapData")

		# This is a small UX improvement so that the user sees a default terrain
		if is_inside_tree() and Engine.is_editor_hint():
			if _data.get_resolution() == 0:
				_data._edit_load_default()

		_data.connect("resolution_changed", self, "_on_data_resolution_changed")
		_data.connect("region_changed", self, "_on_data_region_changed")
		_data.connect("map_changed", self, "_on_data_map_changed")
		_data.connect("map_added", self, "_on_data_map_added")
		_data.connect("map_removed", self, "_on_data_map_removed")

		_on_data_resolution_changed()

	_material_params_need_update = true
	
	Util.update_configuration_warning(self, true)
	
	_logger.debug("Set data done")


func _on_data_resolution_changed():
	_reset_ground_chunks()


func _reset_ground_chunks():
	if _data == null:
		return

	_clear_all_chunks()

	_pending_chunk_updates.clear()

	_lodder.create_from_sizes(_chunk_size, _data.get_resolution() * _chunk_subdiv)

	_chunks.resize(_lodder.get_lod_count())

	var cres := _data.get_resolution() * _chunk_subdiv / _chunk_size
	var csize_x := cres
	var csize_y := cres

	for lod in range(_lodder.get_lod_count()):
		_logger.debug(str("Create grid for lod ", lod, ", ", csize_x, "x", csize_y))
		var grid = Grid.create_grid(csize_x, csize_y)
		_chunks[lod] = grid
		csize_x /= 2
		csize_y /= 2

	_mesher.configure(_chunk_size, _chunk_size, _lodder.get_lod_count(), false)


func _on_data_region_changed(min_x, min_y, size_x, size_y, channel):
	# Testing only heights because it's the only channel that can impact geometry and LOD
	if channel == HTerrainData.CHANNEL_HEIGHT:
		set_area_dirty(min_x, min_y, size_x, size_y)


func _on_data_map_changed(type: int, index: int):
	if type == HTerrainData.CHANNEL_DETAIL \
	or type == HTerrainData.CHANNEL_HEIGHT \
	or type == HTerrainData.CHANNEL_NORMAL \
	or type == HTerrainData.CHANNEL_GLOBAL_ALBEDO:

		for layer in _detail_layers:
			layer.update_material()

	if type != HTerrainData.CHANNEL_DETAIL:
		_material_params_need_update = true


func _on_data_map_added(type: int, index: int):
	if type == HTerrainData.CHANNEL_DETAIL:
		for layer in _detail_layers:
			# Shift indexes up since one was inserted
			if layer.layer_index >= index:
				layer.layer_index += 1
			layer.update_material()
	else:
		_material_params_need_update = true
	Util.update_configuration_warning(self, true)


func _on_data_map_removed(type: int, index: int):
	if type == HTerrainData.CHANNEL_DETAIL:
		for layer in _detail_layers:
			# Shift indexes down since one was removed
			if layer.layer_index > index:
				layer.layer_index -= 1
			layer.update_material()
	else:
		_material_params_need_update = true
	Util.update_configuration_warning(self, true)


func get_shader_type() -> String:
	return _shader_type


func set_shader_type(type: String):
	if type == _shader_type:
		return
	_shader_type = type
	
	if _shader_type == SHADER_CUSTOM:
		_material.shader = _custom_shader
	else:
		_material.shader = load(_builtin_shaders[_shader_type].path)

	_material_params_need_update = true
	
	if Engine.editor_hint:
		property_list_changed_notify()


func get_custom_shader() -> Shader:
	return _custom_shader


func set_custom_shader(shader: Shader):
	if _custom_shader == shader:
		return

	if _custom_shader != null:
		_custom_shader.disconnect("changed", self, "_on_custom_shader_changed")

	if Engine.is_editor_hint() and shader != null and is_inside_tree():
		# When the new shader is empty, allow to fork from the previous shader
		if shader.get_code().empty():
			_logger.debug("Populating custom shader with default code")
			var src := _material.shader
			if src == null:
				src = load(_builtin_shaders[SHADER_DEEP_WATER].path)
			shader.set_code(src.code)
			# TODO If code isn't empty,
			# verify existing parameters and issue a warning if important ones are missing

	_custom_shader = shader

	if _shader_type == SHADER_CUSTOM:
		_material.shader = _custom_shader

	if _custom_shader != null:
		_custom_shader.connect("changed", self, "_on_custom_shader_changed")
		if _shader_type == SHADER_CUSTOM:
			_material_params_need_update = true
	
	if Engine.editor_hint:
		property_list_changed_notify()


func _on_custom_shader_changed():
	_material_params_need_update = true


func _update_material_params():
	assert(_material != null)
	_logger.debug("Updating terrain material params")
		
	var terrain_textures := {}
	
	var lookdev_material : ShaderMaterial
	if _lookdev_enabled:
		lookdev_material = _get_lookdev_material()

	# TODO Only get textures the shader supports

	if has_data():
		for map_type in HTerrainData.CHANNEL_COUNT:
			var count := _data.get_map_count(map_type)
			for i in count:
				var param_name: String = HTerrainData.get_map_shader_param_name(map_type, i)
				terrain_textures[param_name] = _data.get_texture(map_type, i)

	# Set all parameters from the terrain sytem.

	if is_inside_tree():
		var gt = get_internal_transform()
		var t = gt.affine_inverse()
		_material.set_shader_param(SHADER_PARAM_INVERSE_WATER_TRANSFORM, t)
		_material.set_shader_param(SHADER_PARAM_INVERSE_TERRAIN_TRANSFORM, t.scaled(Vector3.ONE / _chunk_subdiv))

		# This is needed to properly transform normals if the terrain is scaled
		var normal_basis = gt.basis.inverse().transposed()
		_material.set_shader_param(SHADER_PARAM_NORMAL_BASIS, normal_basis)
		
		_material.set_shader_param(SHADER_PARAM_WAVE_AMPLITUDE, _wave_amplitude)
		_material.set_shader_param(SHADER_PARAM_WAVE_DENSITY, _wave_density)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS, _wave_kernel_pos)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DX, _wave_kernel_pos_dx)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DY, _wave_kernel_pos_dy)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DZ, _wave_kernel_pos_dz)
		_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_PARTICLE, _wave_kernel_particle)
		
		if lookdev_material != null:
			lookdev_material.set_shader_param(SHADER_PARAM_INVERSE_WATER_TRANSFORM, t)
			lookdev_material.set_shader_param(SHADER_PARAM_INVERSE_TERRAIN_TRANSFORM, t.scaled(Vector3.ONE / _chunk_subdiv))
			lookdev_material.set_shader_param(SHADER_PARAM_NORMAL_BASIS, normal_basis)

			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_AMPLITUDE, _wave_amplitude)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_DENSITY, _wave_density)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS, _wave_kernel_pos)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DX, _wave_kernel_pos_dx)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DY, _wave_kernel_pos_dy)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_POS_DZ, _wave_kernel_pos_dz)
			lookdev_material.set_shader_param(SHADER_PARAM_WAVE_KERNEL_PARTICLE, _wave_kernel_particle)
	
	for param_name in terrain_textures:
		var tex = terrain_textures[param_name]
		_material.set_shader_param(param_name, tex)
		if lookdev_material != null:
			lookdev_material.set_shader_param(param_name, tex)

#	if _texture_set != null:
#		match _texture_set.get_mode():
#			HTerrainTextureSet.MODE_TEXTURES:
#				var slots_count := _texture_set.get_slots_count()
#				for type in HTerrainTextureSet.TYPE_COUNT:
#					for slot_index in slots_count:
#						var texture := _texture_set.get_texture(slot_index, type)
#						var shader_param := _get_ground_texture_shader_param_name(type, slot_index)
#						_material.set_shader_param(shader_param, texture)

#			HTerrainTextureSet.MODE_TEXTURE_ARRAYS:
#				for type in HTerrainTextureSet.TYPE_COUNT:
#					var texture_array := _texture_set.get_texture_array(type)
#					var shader_params := _get_ground_texture_array_shader_param_name(type)
#					_material.set_shader_param(shader_params, texture_array)

	if _use_editor_time:
		_material.set_shader_param(SHADER_PARAM_TIME, _editor_time)
		_material.set_shader_param(SHADER_PARAM_DELTA_TIME, _editor_delta_time)

#	_is_using_indexed_splatmap = false
#	_used_splatmaps_count_cache = 0
#
#	var shader := _material.shader
#	if shader != null:
#		var param_list := VisualServer.shader_get_param_list(shader.get_rid())
#		_ground_texture_count_cache = 0
#		for p in param_list:
#			if _api_shader_ground_albedo_params.has(p.name):
#				_ground_texture_count_cache += 1
#			elif p.name == "u_terrain_splat_index_map":
#				_is_using_indexed_splatmap = true
#			elif p.name in _splatmap_shader_params:
#				_used_splatmaps_count_cache += 1


# Gets how many splatmaps the current shader is using.
# This will only be valid once the material has been updated internally.
# (for example it won't be valid before the terrain is added to the SceneTree)
func get_used_splatmaps_count() -> int:
	return _used_splatmaps_count_cache


# Tells if the current shader is using a splatmap type based on indexes and weights.
# This will only be valid once the material has been updated internally.
# (for example it won't be valid before the terrain is added to the SceneTree)
func is_using_indexed_splatmap() -> bool:
	return _is_using_indexed_splatmap


static func _get_common_shader_params(shader1: Shader, shader2: Shader) -> Array:
	var shader1_param_names := {}
	var common_params := []
	
	var shader1_params := VisualServer.shader_get_param_list(shader1.get_rid())
	var shader2_params := VisualServer.shader_get_param_list(shader2.get_rid())
	
	for p in shader1_params:
		shader1_param_names[p.name] = true
	
	for p in shader2_params:
		if shader1_param_names.has(p.name):
			common_params.append(p.name)
	
	return common_params


func set_lod_scale(lod_scale: float):
	_lodder.set_split_scale(lod_scale)


func get_lod_scale() -> float:
	return _lodder.get_split_scale()


func get_lod_count() -> int:
	return _lodder.get_lod_count()


#        3
#      o---o
#    0 |   | 1
#      o---o
#        2
# Directions to go to neighbor chunks
const s_dirs = [
	[-1, 0], # SEAM_LEFT
	[1, 0], # SEAM_RIGHT
	[0, -1], # SEAM_BOTTOM
	[0, 1] # SEAM_TOP
]

#       7   6
#     o---o---o
#   0 |       | 5
#     o       o
#   1 |       | 4
#     o---o---o
#       2   3
#
# Directions to go to neighbor chunks of higher LOD
const s_rdirs = [
	[-1, 0],
	[-1, 1],
	[0, 2],
	[1, 2],
	[2, 1],
	[2, 0],
	[1, -1],
	[0, -1]
]


func _edit_update_viewer_position(camera: Camera):
	_update_viewer_position(camera)


func _update_viewer_position(camera: Camera):
	if camera == null:
		var viewport := get_viewport()
		if viewport != null:
			camera = viewport.get_camera()
	
	if camera == null:
		return
	
	if camera.projection == Camera.PROJECTION_ORTHOGONAL:
		# In this mode, due to the fact Godot does not allow negative near plane,
		# users have to pull the camera node very far away, but it confuses LOD
		# into very low detail, while the seen area remains the same.
		# So we need to base LOD on a different metric.
		var cam_pos := camera.global_transform.origin
		var cam_dir := -camera.global_transform.basis.z
		var max_distance := camera.far * 1.2
		var hit_cell_pos = cell_raycast(cam_pos, cam_dir, max_distance)
		
		if hit_cell_pos != null:
			var cell_to_world := get_internal_transform()
			var h := _data.get_height_at(hit_cell_pos.x, hit_cell_pos.y)
			_viewer_pos_world = cell_to_world * Vector3(hit_cell_pos.x, h, hit_cell_pos.y)
			
	else:
		_viewer_pos_world = camera.global_transform.origin


func _process(delta: float):
	if Engine.is_editor_hint():
		# Update time to animate waves in the editor
		if _use_editor_time:
			_editor_time += delta
			_material_params_need_update = true
	else:
		# In editor, the camera is only accessible from an editor plugin
		_update_viewer_position(null)

	if has_data():
		if _data.is_locked():
			# Can't use the data for now
			return

		if _data.get_resolution() != 0:
			var gt := get_internal_transform()
			# Viewer position such that 1 unit == 1 pixel in the heightmap
			var viewer_pos_heightmap_local := gt.affine_inverse() * _viewer_pos_world
			#var time_before = OS.get_ticks_msec()
			_lodder.update(viewer_pos_heightmap_local)
			#var time_elapsed = OS.get_ticks_msec() - time_before
			#if Engine.get_frames_drawn() % 60 == 0:
			#	_logger.debug(str("Lodder time: ", time_elapsed))

		if _data.get_map_count(HTerrainData.CHANNEL_DETAIL) > 0:
			# Note: the detail system is not affected by map scale,
			# so we have to send viewer position in world space
			for layer in _detail_layers:
				layer.process(delta, _viewer_pos_world)

	_updated_chunks = 0

	# Add more chunk updates for neighboring (seams):
	# This adds updates to higher-LOD chunks around lower-LOD ones,
	# because they might not needed to update by themselves, but the fact a neighbor
	# chunk got joined or split requires them to create or revert seams
	var precount = _pending_chunk_updates.size()
	for i in range(precount):
		var u: PendingChunkUpdate = _pending_chunk_updates[i]

		# In case the chunk got split
		for d in 4:
			var ncpos_x = u.pos_x + s_dirs[d][0]
			var ncpos_y = u.pos_y + s_dirs[d][1]

			var nchunk := _get_chunk_at(ncpos_x, ncpos_y, u.lod)
			if nchunk != null and nchunk.is_active():
				# Note: this will append elements to the array we are iterating on,
				# but we iterate only on the previous count so it should be fine
				_add_chunk_update(nchunk, ncpos_x, ncpos_y, u.lod)

		# In case the chunk got joined
		if u.lod > 0:
			var cpos_upper_x := u.pos_x * 2
			var cpos_upper_y := u.pos_y * 2
			var nlod := u.lod - 1

			for rd in 8:
				var ncpos_upper_x = cpos_upper_x + s_rdirs[rd][0]
				var ncpos_upper_y = cpos_upper_y + s_rdirs[rd][1]

				var nchunk := _get_chunk_at(ncpos_upper_x, ncpos_upper_y, nlod)
				if nchunk != null and nchunk.is_active():
					_add_chunk_update(nchunk, ncpos_upper_x, ncpos_upper_y, nlod)

	# Update chunks
	var lvisible := is_visible_in_tree()
	for i in range(len(_pending_chunk_updates)):
		var u: PendingChunkUpdate = _pending_chunk_updates[i]
		var chunk := _get_chunk_at(u.pos_x, u.pos_y, u.lod)
		assert(chunk != null)
		_update_chunk(chunk, u.lod, lvisible)
		_updated_chunks += 1

	_pending_chunk_updates.clear()

	if _material_params_need_update:
		_update_material_params()
		Util.update_configuration_warning(self, false)
		_material_params_need_update = false

	# DEBUG
#	if(_updated_chunks > 0):
#		_logger.debug(str("Updated {0} chunks".format(_updated_chunks)))


func _update_chunk(chunk: HTerrainChunk, lod: int, p_visible: bool):
	assert(has_data())

	# Check for my own seams
	var seams := 0
	var cpos_x := chunk.cell_origin_x / (_chunk_size << lod)
	var cpos_y := chunk.cell_origin_y / (_chunk_size << lod)
	var cpos_lower_x := cpos_x / 2
	var cpos_lower_y := cpos_y / 2

	# Check for lower-LOD chunks around me
	for d in 4:
		var ncpos_lower_x = (cpos_x + s_dirs[d][0]) / 2
		var ncpos_lower_y = (cpos_y + s_dirs[d][1]) / 2
		if ncpos_lower_x != cpos_lower_x or ncpos_lower_y != cpos_lower_y:
			var nchunk := _get_chunk_at(ncpos_lower_x, ncpos_lower_y, lod + 1)
			if nchunk != null and nchunk.is_active():
				seams |= (1 << d)

	var mesh := _mesher.get_chunk(lod, seams)
	chunk.set_mesh(mesh)

	# Because chunks are rendered using vertex shader displacement,
	# the renderer cannot rely on the mesh's AABB.
	var s := _chunk_size << lod
	var aabb := _data.get_region_aabb(chunk.cell_origin_x, chunk.cell_origin_y, s, s)
	aabb.position.x = 0
	aabb.position.y = -_wave_amplitude * _wave_density
	aabb.position.z = 0
	aabb.size.y = 2.0 * _wave_amplitude * _wave_density
	chunk.set_aabb(aabb)

	chunk.set_visible(p_visible)
	chunk.set_pending_update(false)


func _add_chunk_update(chunk: HTerrainChunk, pos_x: int, pos_y: int, lod: int):
	if chunk.is_pending_update():
		#_logger.debug("Chunk update is already pending!")
		return

	assert(lod < len(_chunks))
	assert(pos_x >= 0)
	assert(pos_y >= 0)
	assert(pos_y < len(_chunks[lod]))
	assert(pos_x < len(_chunks[lod][pos_y]))

	# No update pending for this chunk, create one
	var u := PendingChunkUpdate.new()
	u.pos_x = pos_x
	u.pos_y = pos_y
	u.lod = lod
	_pending_chunk_updates.push_back(u)

	chunk.set_pending_update(true)

	# TODO Neighboring chunks might need an update too
	# because of normals and seams being updated


# Used when editing an existing terrain
func set_area_dirty(origin_in_cells_x: int, origin_in_cells_y: int, \
					size_in_cells_x: int, size_in_cells_y: int):

	var cpos0_x := origin_in_cells_x * _chunk_subdiv / _chunk_size
	var cpos0_y := origin_in_cells_y * _chunk_subdiv / _chunk_size
	var csize_x := (size_in_cells_x - 1) * _chunk_subdiv / _chunk_size + 1
	var csize_y := (size_in_cells_y - 1) * _chunk_subdiv / _chunk_size + 1

	# For each lod
	for lod in range(_lodder.get_lod_count()):
		# Get grid and chunk size
		var grid = _chunks[lod]
		var s := _lodder.get_lod_size(lod)

		# Convert rect into this lod's coordinates:
		# Pick min and max (included), divide them, then add 1 to max so it's excluded again
		var min_x := cpos0_x / s
		var min_y := cpos0_y / s
		var max_x := (cpos0_x + csize_x - 1) / s + 1
		var max_y := (cpos0_y + csize_y - 1) / s + 1

		# Find which chunks are within
		for cy in range(min_y, max_y):
			for cx in range(min_x, max_x):
				var chunk = Grid.grid_get_or_default(grid, cx, cy, null)
				if chunk != null and chunk.is_active():
					_add_chunk_update(chunk, cx, cy, lod)


# Called when a chunk is needed to be seen
func _cb_make_chunk(cpos_x: int, cpos_y: int, lod: int):
	# TODO What if cpos is invalid? _get_chunk_at will return NULL but that's still invalid
	var chunk := _get_chunk_at(cpos_x, cpos_y, lod)

	if chunk == null:
		# This is the first time this chunk is required at this lod, generate it
		
		var lod_factor := _lodder.get_lod_size(lod)
		var origin_in_cells_x := cpos_x * _chunk_size * lod_factor
		var origin_in_cells_y := cpos_y * _chunk_size * lod_factor
		
		var material = _material
		if _lookdev_enabled:
			material = _get_lookdev_material()

		if _DEBUG_AABB:
			chunk = HTerrainChunkDebug.new(
				self, origin_in_cells_x, origin_in_cells_y, material)
		else:
			chunk = HTerrainChunk.new(self, origin_in_cells_x, origin_in_cells_y, material)
		chunk.parent_transform_changed(get_internal_transform())

		chunk.set_render_layer_mask(_render_layer_mask)

		var grid = _chunks[lod]
		var row = grid[cpos_y]
		row[cpos_x] = chunk

	# Make sure it gets updated
	_add_chunk_update(chunk, cpos_x, cpos_y, lod)

	chunk.set_active(true)
	return chunk


# Called when a chunk is no longer seen
func _cb_recycle_chunk(chunk: HTerrainChunk, cx: int, cy: int, lod: int):
	chunk.set_visible(false)
	chunk.set_active(false)


func _cb_get_vertical_bounds(cpos_x: int, cpos_y: int, lod: int):
	return _wave_amplitude * _wave_density * Vector2(-1.0, 1.0)


static func _get_height_or_default(im: Image, pos_x: int, pos_y: int):
	if pos_x < 0 or pos_y < 0 or pos_x >= im.get_width() or pos_y >= im.get_height():
		return 0.0
	return im.get_pixel(pos_x, pos_y).r


# Performs a raycast to the terrain without using the collision engine.
# This is mostly useful in the editor, where the collider can't be updated in realtime.
# Returns cell hit position as Vector2, or null if there was no hit.
# TODO Cannot type hint nullable return value
func cell_raycast(origin_world: Vector3, dir_world: Vector3, max_distance: float):
	assert(typeof(origin_world) == TYPE_VECTOR3)
	assert(typeof(dir_world) == TYPE_VECTOR3)
	if not has_data():
		return null
	# Transform to local (takes map scale into account)
	var to_local := get_internal_transform().affine_inverse()
	var origin = to_local.xform(origin_world)
	var dir = to_local.basis.xform(dir_world)
	return _data.cell_raycast(origin, dir, max_distance)


static func _get_ground_texture_shader_param_name(ground_texture_type: int, slot: int) -> String:
	assert(typeof(slot) == TYPE_INT and slot >= 0)
	_check_ground_texture_type(ground_texture_type)
	return str(SHADER_PARAM_GROUND_PREFIX, 
		_ground_enum_to_name[ground_texture_type], "_", slot)


# @obsolete
func get_ground_texture(slot: int, type: int) -> Texture:
	_logger.error(
		"HTerrain.get_ground_texture is obsolete, " +
		"use HTerrain.get_texture_set().get_texture(slot, type) instead")
	var shader_param = _get_ground_texture_shader_param_name(type, slot)
	return _material.get_shader_param(shader_param)


# @obsolete
func set_ground_texture(slot: int, type: int, tex: Texture):
	_logger.error(
		"HTerrain.set_ground_texture is obsolete, " +
		"use HTerrain.get_texture_set().set_texture(slot, type, texture) instead")
	assert(tex == null or tex is Texture)
	var shader_param = _get_ground_texture_shader_param_name(type, slot)
	_material.set_shader_param(shader_param, tex)


func _get_ground_texture_array_shader_param_name(type: int) -> String:
	return _ground_texture_array_shader_params[type] as String


# @obsolete
func get_ground_texture_array(type: int) -> TextureArray:
	_logger.error(
		"HTerrain.get_ground_texture_array is obsolete, " +
		"use HTerrain.get_texture_set().get_texture_array(type) instead")
	var param_name = _get_ground_texture_array_shader_param_name(type)
	return _material.get_shader_param(param_name)


# @obsolete
func set_ground_texture_array(type: int, texture_array: TextureArray):
	_logger.error(
		"HTerrain.set_ground_texture_array is obsolete, " +
		"use HTerrain.get_texture_set().set_texture_array(type, texarray) instead")
	var param_name = _get_ground_texture_array_shader_param_name(type)
	_material.set_shader_param(param_name, texture_array)


func _internal_add_detail_layer(layer):
	assert(_detail_layers.find(layer) == -1)
	_detail_layers.append(layer)


func _internal_remove_detail_layer(layer):
	assert(_detail_layers.find(layer) != -1)
	_detail_layers.erase(layer)


# Returns a list copy of all child HTerrainDetailLayer nodes.
# The order in that list has no relevance.
func get_detail_layers() -> Array:
	return _detail_layers.duplicate()


# @obsolete
func set_detail_texture(slot, tex):
	_logger.error(
		"HTerrain.set_detail_texture is obsolete, use HTerrainDetailLayer.texture instead")


# @obsolete
func get_detail_texture(slot):
	_logger.error(
		"HTerrain.get_detail_texture is obsolete, use HTerrainDetailLayer.texture instead")


func set_ambient_wind(amplitude: float):
	if ambient_wind == amplitude:
		return
	ambient_wind = amplitude
	for layer in _detail_layers:
		layer.update_material()


static func _check_ground_texture_type(ground_texture_type: int):
	assert(typeof(ground_texture_type) == TYPE_INT)
	assert(ground_texture_type >= 0 and ground_texture_type < HTerrainTextureSet.TYPE_COUNT)


# @obsolete
func get_ground_texture_slot_count() -> int:
	_logger.error("get_ground_texture_slot_count is obsolete, " \
		+ "use get_cached_ground_texture_slot_count instead")
	return get_max_ground_texture_slot_count()

# @obsolete
func get_max_ground_texture_slot_count() -> int:
	_logger.error("get_ground_texture_slot_count is obsolete, " \
		+ "use get_cached_ground_texture_slot_count instead")
	return get_cached_ground_texture_slot_count()


# This is a cached value based on the actual number of texture parameters
# in the current shader. It won't update immediately when the shader changes,
# only after a frame. This is mostly used in the editor.
func get_cached_ground_texture_slot_count() -> int:
	return _ground_texture_count_cache


func _edit_debug_draw(ci: CanvasItem):
	_lodder.debug_draw_tree(ci)


func _get_configuration_warning():
	if _data == null:
		return "The terrain is missing data.\n" \
			+ "Select the `Data Directory` property in the inspector to assign it."

	if _texture_set == null:
		return "The terrain does not have a HTerrainTextureSet assigned\n" \
			+ "This is required if you want to paint textures on it."

	# TODO Warn about unused data maps, have a tool to clean them up
	return ""


func set_lookdev_enabled(enable: bool):
	if _lookdev_enabled == enable:
		return
	_lookdev_enabled = enable
	_material_params_need_update = true
	if _lookdev_enabled:
		_for_all_chunks(SetMaterialAction.new(_get_lookdev_material()))
	else:
		_for_all_chunks(SetMaterialAction.new(_material))


func set_lookdev_shader_param(param_name: String, value):
	var mat = _get_lookdev_material()
	mat.set_shader_param(param_name, value)


func is_lookdev_enabled() -> bool:
	return _lookdev_enabled


func _get_lookdev_material() -> ShaderMaterial:
	if _lookdev_material == null:
		_lookdev_material = ShaderMaterial.new()
		_lookdev_material.shader = load(_LOOKDEV_SHADER_PATH)
	return _lookdev_material


class PendingChunkUpdate:
	var pos_x := 0
	var pos_y := 0
	var lod := 0


class EnterWorldAction:
	var world : World = null
	func _init(w):
		world = w
	func exec(chunk):
		chunk.enter_world(world)


class ExitWorldAction:
	func exec(chunk):
		chunk.exit_world()


class TransformChangedAction:
	var transform : Transform
	func _init(t):
		transform = t
	func exec(chunk):
		chunk.parent_transform_changed(transform)


class VisibilityChangedAction:
	var visible := false
	func _init(v):
		visible = v
	func exec(chunk):
		chunk.set_visible(visible and chunk.is_active())


#class DeleteChunkAction:
#	func exec(chunk):
#		pass


class SetMaterialAction:
	var material : Material = null
	func _init(m):
		material = m
	func exec(chunk):
		chunk.set_material(material)


class SetRenderLayerMaskAction:
	var mask: int = 0
	func _init(m: int):
		mask = m
	func exec(chunk):
		chunk.set_render_layer_mask(mask)
