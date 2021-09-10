tool
extends EditorScript

var shader_path = "res://shaders"

func _get_shader_lines(import_path: String) -> PoolStringArray:
	print("Importing shader " + import_path)
	var result = PoolStringArray([])
	var file = File.new()

	file.open(import_path, File.READ)
	while not file.eof_reached():
		var line = file.get_line()
		# Ignore special lines
		if line.begins_with("shader_type") or line.begins_with("render_mode"):
			continue
		result.append(line)
	file.close()
	return result

func _import_shaders(path: String):
	var result = PoolStringArray([])
	var modified = false
	var file = File.new()

	file.open(path, File.READ)
	while not file.eof_reached():
		var line = file.get_line()
		result.append(line)
		
		if "BEGIN_IMPORT" in line:
			print("Found shader import")
			var parts = line.split("BEGIN_IMPORT", true, 1)
			if parts.size() > 1:
				result.append_array(_get_shader_lines(parts[1].strip_edges()))
				modified = true

				while not file.eof_reached():
					var skip_line = file.get_line()
					if "END_IMPORT" in skip_line:
						result.append(skip_line)
						break
	file.close()
	
	if modified:
		file.open(path, File.WRITE)
		for line in result:
			file.store_line(line)
		file.close()
	
	return modified

func _walk_directory(path: String):
	var dir = Directory.new()
	if dir.open(shader_path) == OK:
		dir.list_dir_begin(true, true)
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				print("Found directory: " + file_name)
#				_walk_directory(file_name)
			else:
				if file_name.ends_with(".gdshader"):
					print("Found shader file: " + file_name)
					var file_path = dir.get_current_dir() + "/"  + file_name
					if _import_shaders(file_path):
						print("MODIFIED! " + file_path)
						# XXX none of these things work, have to alt-tab out of the editor to force a reimport of the shader
#						load(file_path)
#						get_editor_interface().get_resource_filesystem().update_file(file_path)
#						get_editor_interface().get_resource_filesystem().scan()
#						get_editor_interface().get_resource_filesystem().scan_sources()
				else:
					print("Skipped file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the shader path.")

func _run():
	print("Importing shaders ...")
	_walk_directory(shader_path)
