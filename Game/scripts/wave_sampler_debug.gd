extends MeshInstance

#func draw_line3d(node, camera: Camera, from: Vector3, to: Vector3, color: Color):
#	var from_screen = camera.unproject_position(from)
#	var to_screen = camera.unproject_position(to)
#	var width = 1.0
#	node.draw_line(from_screen, to_screen, color, width)
#	node.draw_triangle(to_screen, from_screen.direction_to(to_screen), width*2, color)
#
#func _draw():
#	var camera = get_viewport().get_camera()
##	get_editor_interface()
#	print("Hello")
#	draw_line3d(self, camera, Vector3(1, 0, 3), Vector3(-2, 0, 4), Color.red)

func _ready():
	var viewport: Viewport = get_parent().get_node("WaveSampler").viewport
	var tex = viewport.get_texture()
	get_active_material(0).albedo_texture = tex
