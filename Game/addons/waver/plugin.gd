tool
extends EditorPlugin

const WaterSurface = preload("./water_surface.gd")


static func get_icon(name: String) -> Texture:
	return load("res://addons/zylann.hterrain/tools/icons/icon_" + name + ".svg") as Texture


func _enter_tree():
	# XXX HTerrainWater class is from the HTerrain plugin, but loading order for plugins is undefined.
	# "Spatial" as base class seems to work fine, the WaterSurface script loads its own base correctly.
#	add_custom_type("WaterSurface", "HTerrainWater", WaterSurface, get_icon("heightmap_node"))
	add_custom_type("WaterSurface", "Spatial", WaterSurface, get_icon("heightmap_node"))


func _exit_tree():
	remove_custom_type("WaterSurface")
