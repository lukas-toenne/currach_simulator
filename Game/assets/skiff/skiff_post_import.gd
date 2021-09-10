tool
extends EditorScenePostImport

func post_import(scene):
	iterate(scene)
	return scene # Remember to return the imported scene

func anim_filter(node: AnimationPlayer, name: String, allowed_tracks):
	var anim = node.get_animation(name)
	# Reverse loop to avoid shifting indices of unhandled tracks
	for i in range(anim.get_track_count()-1, -1, -1):
		if not (anim.track_get_path(i).get_subname(0) in allowed_tracks):
			print("Removing track '" + anim.track_get_path(i) + "' from animation '" + name + "'")
			anim.remove_track(i)
	print("'" + name + "' track count " + str(node.get_animation(name).get_track_count()))

func iterate(node: Node):
	if node != null:
		# XXX does not work, removed tracks get back in somehow, have to use the clumsy filter script
#		if node.is_class("AnimationPlayer"):
#			anim_filter(node, "SkiffIdleL", ["oar_l"])
#			anim_filter(node, "SkiffRowL", ["oar_l"])
#			anim_filter(node, "SkiffBackL", ["oar_l"])
#			anim_filter(node, "SkiffBrakeL", ["oar_l"])
#			anim_filter(node, "SkiffIdleR", ["oar_r"])
#			anim_filter(node, "SkiffRowR", ["oar_r"])
#			anim_filter(node, "SkiffBackR", ["oar_r"])
#			anim_filter(node, "SkiffBrakeR", ["oar_r"])

		if node.name == "SkiffCover":
			var holdout_mat = ShaderMaterial.new()
			holdout_mat.shader = load("res://shaders/holdout.gdshader")
			var mesh: MeshInstance = node
			mesh.mesh.surface_set_material(0, holdout_mat)

		for child in node.get_children():
			iterate(child)
