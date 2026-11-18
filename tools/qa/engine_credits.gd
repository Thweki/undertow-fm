extends SceneTree
func _initialize():
	var file=FileAccess.open("res://licenses/Godot.txt",FileAccess.WRITE)
	file.store_string(Engine.get_license_text()+"\n")
	var out=FileAccess.open("res://licenses/Engine-Third-Party.txt",FileAccess.WRITE)
	for component in Engine.get_copyright_info():
		out.store_line(component.name)
		for part in component.parts:
			for copyright in part.copyright: out.store_line("  "+copyright)
			out.store_line("  "+part.license)
		out.store_line("")
	var notices=Engine.get_license_info()
	for name in notices:
		out.store_line(name)
		out.store_line(notices[name])
		out.store_line("")
	quit()
