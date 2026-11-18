extends SceneTree
# Excerpts are staged at chapter checkpoints and played through the normal key map.
var game
var frame_no=0
var chapter_cut=-1
var count=0
var want={}
var held={}
var output=""
var snaps={}
const MAP={"l":KEY_A,"r":KEY_D,"u":KEY_W,"d":KEY_S,"jab":KEY_J,"heavy":KEY_K,"skill":KEY_L,"use":KEY_E,"dodge":KEY_SPACE}
const CUTS=[150,140,455,290,305,250,350,365,110]
const Climb=preload("res://tools/qa/platform_driver.gd")
func _initialize(): call_deferred("begin")
func begin():
	var args=OS.get_cmdline_user_args()
	output=args[0] if args.size()>0 else "/tmp/undertow-reel"
	DirAccess.make_dir_recursive_absolute(output)
	game=load("res://game/Main.tscn").instantiate()
	game.prefs.path=output+"/temp.cfg"
	root.add_child(game)
	physics_frame.connect(drive)
func mark(k): want[k]=true
func tap(k,n):
	if frame_no%n==0: mark(k)
func start_cut():
	match chapter_cut:
		0:
			game.prefs.chapter=-1
			game.change("title")
		1:
			game.launch(7,0,false)
			game.story_line=1
		2:
			game.launch(1,0,false)
			game.change("play")
		3:
			game.launch(6,4,false)
			game.change("play")
		4:
			game.launch(10,3,false)
			game.start_interlude({"state":{"room":2}})
		5:
			game.launch(8,3,false)
			game.start_interlude({"state":{"zone":1}})
		6:
			game.launch(9,5,false)
			game.start_interlude({"mode":"memory","state":{"room":2,"station":1}})
		7:
			game.launch(15,5,false)
			game.change("play")
		8:
			game.prefs.chapter=-1
			game.change("title")
func steer(v:Vector2):
	if absf(v.x)>4: mark("r" if v.x>0 else "l")
	if absf(v.y)>4: mark("d" if v.y>0 else "u")
func fighter():
	var a=game.arena
	var h=a.hero
	var enemy=null
	var distance=INF
	for e in a.enemies:
		if e.alive() and h.pos.distance_to(e.pos)<distance:
			enemy=e
			distance=h.pos.distance_to(e.pos)
	if chapter_cut==7 and a.duels.guidance()!=Vector2.INF:
		var point=a.duels.guidance()
		if a.is_near(h.pos,point,24): mark("use")
		else: steer(point-h.pos)
		return
	if enemy and (distance<133 or chapter_cut!=3):
		var delta=enemy.pos-h.pos
		steer(Vector2(delta.x if absf(delta.x)>41 else 0,delta.y))
		if absf(delta.x)>1 and h.face!=int(signf(delta.x)): mark("r" if delta.x>0 else "l")
		if absf(delta.x)<60 and absf(delta.y)<20:
			tap("jab",11)
			if frame_no%59==0: mark("heavy")
			if a.flux>=40 and frame_no%122==0: mark("skill")
	else:
		var goal=a.target_point()
		steer(goal-h.pos)
		tap("use",9)
func drive():
	frame_no+=1
	want={}
	if chapter_cut<0 or count>=CUTS[chapter_cut]:
		chapter_cut+=1
		count=0
		if chapter_cut>=CUTS.size():
			game.sound.silence()
			quit()
			return
		start_cut()
	count+=1
	if game.mode in ["play","memory"]: fighter()
	if game.mode=="traverse": Climb.drive(self)
	if game.mode=="switchboard":
		if count%32==0: mark("r")
		if count%45==0: mark("use")
	for k in MAP:
		if held.has(k)==want.has(k): continue
		var e=InputEventKey.new()
		e.physical_keycode=MAP[k]
		e.keycode=MAP[k]
		e.pressed=want.has(k)
		if e.pressed: held[k]=true
		else: held.erase(k)
		Input.parse_input_event(e)
	Input.flush_buffered_events()
	if (chapter_cut in [2,3] and count in [150,201,242,303]) or (chapter_cut in [4,5,6,7] and count==222) or (chapter_cut in [0,1] and count==65):
		snapshot(chapter_cut,count)
func snapshot(scene,num):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/%02d-%03d.png"%[scene,num])
