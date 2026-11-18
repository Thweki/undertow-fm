extends SceneTree
# Render genuine game surfaces at the game's native resolution. No writes to player data.
var game
var folder="/tmp/undertow-captures"
func _initialize(): call_deferred("run")
func snap(id):
	for _i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"/"+id+".png")
func run():
	var args=OS.get_cmdline_user_args()
	if args.size()>0: folder=args[0]
	DirAccess.make_dir_recursive_absolute(folder)
	game=load("res://game/Main.tscn").instantiate()
	game.prefs.path=folder+"/capture-profile.cfg"
	root.add_child(game)
	game.change("title")
	game.transition=0
	await snap("title")
	game.launch(0,0,false)
	game.transition=0
	await snap("opening")
	game.change("play")
	await snap("workshop")
	game.launch(1,0,false)
	game.change("play")
	for _i in 180: await physics_frame
	await snap("market")
	game.open_pause()
	await snap("pause")
	game.change("options")
	await snap("options")
	game.launch(15,5,false)
	game.change("play")
	for _i in 145: await physics_frame
	await snap("tower")
	game.change("chapters")
	await snap("chapters")
	root.remove_child(game)
	game.free()
	for _i in 15: await process_frame
	quit()
