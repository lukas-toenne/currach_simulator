tool
extends Node

const WaterSurface = preload("../water_surface.gd")

var _water : WaterSurface = null


func _enter_tree():
	pass


func _exit_tree():
	# Make sure we release all references to edited stuff
	release_water()


func connect_water(water):
	if _water != null:
		_water.disconnect("tree_exited", self, "_water_exited_scene")
	
	_water = water
	
	if _water != null:
		_water.connect("tree_exited", self, "_water_exited_scene")


func release_water():
	if _water != null:
		_water.disconnect("tree_exited", self, "_water_exited_scene")
	
	_water = null


func forward_water_input(p_camera: Camera, p_event: InputEvent) -> bool:
	if _water == null || _water.get_data() == null:
		return false

	_water._update_viewer_position(p_camera)

	return false


func _water_exited_scene():
	release_water()
