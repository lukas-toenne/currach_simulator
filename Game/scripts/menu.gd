extends Control

@onready var global = get_node("/root/Global")

func _process(_delta):
	pass


func _on_StartGame_pressed():
	global.load_scene("res://assets/skiff/skiff.tscn")
	hide()
