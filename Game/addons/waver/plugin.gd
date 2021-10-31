tool
extends EditorPlugin

const WaterSurface = preload("./water_surface.gd")
const WaveParticles = preload("./wave_particles.gd")
const WaterTool = preload("./tools/water_tool.gd")

var _water_tool: WaterTool = null


static func get_icon(name: String) -> Texture:
	return load("res://addons/zylann.hterrain/tools/icons/icon_" + name + ".svg") as Texture


func _enter_tree():
	# XXX HTerrainWater class is from the HTerrain plugin, but loading order for plugins is undefined.
	# "Spatial" as base class seems to work fine, the WaterSurface script loads its own base correctly.
#	add_custom_type("WaterSurface", "HTerrainWater", WaterSurface, get_icon("heightmap_node"))
	add_custom_type("WaterSurface", "Spatial", WaterSurface, get_icon("heightmap_node"))
	add_custom_type("WaveParticles", "Node", WaveParticles, get_icon("heightmap_node"))
	
	if Engine.is_editor_hint():
		_water_tool = WaterTool.new()
		add_child(_water_tool)


func _exit_tree():
	remove_custom_type("WaterSurface")
	remove_custom_type("WaveParticles")

	if _water_tool:
		remove_child(_water_tool)
		_water_tool = null


static func _get_water_from_object(object):
	if object != null and object is Spatial:
		if not object.is_inside_tree():
			return null
		if object is WaterSurface:
			return object
	return null


func handles(object):
	return _get_water_from_object(object) != null


func edit(object):
	if _water_tool:
		_water_tool.connect_water(_get_water_from_object(object))


func forward_spatial_gui_input(p_camera: Camera, p_event: InputEvent) -> bool:
	if _water_tool:
		return _water_tool.forward_water_input(p_camera, p_event)
	return false
