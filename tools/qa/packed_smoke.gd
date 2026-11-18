extends SceneTree
# Start with the actual export PCK via --main-pack and this external test.
var game
var folder=""
func _initialize(): call_deferred("run")
func key(code,down):
	var e=InputEventKey.new()
	e.physical_keycode=code
	e.keycode=code
	e.pressed=down
	Input.parse_input_event(e)
	Input.flush_buffered_events()
func tap(code):
	key(code,true)
	for i in 4: await physics_frame
	key(code,false)
	for i in 12: await physics_frame
func snap(name):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+name+".png")
func run():
	folder=OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(folder)
	game=load("res://game/Main.tscn").instantiate()
	game.prefs.path=folder+"/pack-test.cfg"
	root.add_child(game)
	for i in 40: await physics_frame
	await snap("pack-title")
	await tap(KEY_ENTER)
	if game.mode!="newgame":
		printerr("New campaign entry failed")
		quit(1)
		return
	await tap(KEY_ENTER)
	if game.mode!="story":
		printerr("Opening story failed")
		quit(1)
		return
	for i in 3: await tap(KEY_ENTER)
	if game.mode!="play":
		printerr("Tutorial entry failed")
		quit(1)
		return
	key(KEY_D,true)
	for i in 30: await physics_frame
	key(KEY_D,false)
	await tap(KEY_J)
	await snap("pack-workshop")
	await tap(KEY_ESCAPE)
	if game.mode!="pause" or game.arena.hero.pos.x<135:
		printerr("Player input or pause failed")
		quit(1)
		return
	await snap("pack-pause")
	var ids=["hero","past","runner","guard","brute","boss","tech","skater"]
	for id in ids:
		for action in ["idle","walk","jab","heavy","skill","dodge","hurt","down"]:
			if not ResourceLoader.exists("res://assets/actors/"+id+"_"+action+".png"):
				printerr("Missing character texture ",id," ",action)
				quit(1)
				return
	for song in ["past","catwalk","title","workshop","market","docks","tower","boss","ending"]:
		if not ResourceLoader.exists("res://assets/audio/"+song+".ogg"):
			quit(1)
			return
	print("PACK PASS: graphical title / physical key mapping / campaign / tutorial / locomotion / pause / asset inventory")
	game.request_exit()
