extends SceneTree
const Profile=preload("res://game/profile.gd")
func _initialize():
	var path=OS.get_temp_dir().path_join("undertow-profile-check-%d.cfg"%Time.get_ticks_usec())
	var first=Profile.new()
	first.path=path
	first.chapter=4
	first.section=2
	first.score=1085
	first.save()
	first.chapter=5
	first.save()
	var primary=Profile.new()
	primary.path=path
	primary.read()
	if primary.chapter!=5:
		printerr("Primary checkpoint mismatch")
		quit(1)
		return
	var f=FileAccess.open(path,FileAccess.WRITE)
	f.store_string("[unfinished")
	f.close()
	var restored=Profile.new()
	restored.path=path
	restored.read()
	if restored.chapter!=4 or restored.section!=2 or restored.score!=1085:
		printerr("Backup restore mismatch")
		quit(1)
		return
	restored.save()
	print("PASS primary checkpoint, rotation, corrupted-primary fallback and repair")
	for fpath in [path,path+".bak"]:
		DirAccess.remove_absolute(fpath)
	quit()
