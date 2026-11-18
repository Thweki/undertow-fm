extends SceneTree
const Driver=preload("res://tools/qa/platform_driver.gd")
const Keys={"u":KEY_W,"d":KEY_S,"l":KEY_A,"r":KEY_D,"dodge":KEY_SPACE,"use":KEY_E,"heavy":KEY_K,"jab":KEY_J}
var game
var frame_no=0
var want={}
var held={}
var chapters=[1,3,4,6,7,9,10,12,13,15]
var ix=0
var last=""
var blocked=0
var last_frames=0
func _initialize(): call_deferred("run")
func run():
	game=load("res://game/Main.tscn").instantiate()
	game.prefs.path=OS.get_temp_dir().path_join("undertow-catwalk-qa-%d.cfg"%Time.get_ticks_usec())
	root.add_child(game)
	begin()
	physics_frame.connect(drive)
func begin():
	game.launch(chapters[ix],3,false)
	game.start_interlude({})
	last_frames=frame_no
func mark(k): want[k]=true
func tap(k,n):
	if frame_no%n==0: mark(k)
func drive():
	frame_no+=1
	want={}
	if game.mode!="traverse":
		print("ROUTE ",chapters[ix]," seconds=",snappedf((frame_no-last_frames)/60.0,.01))
		ix+=1
		if ix>=chapters.size():
			print("ALL CATWALKS ",frame_no/60.0," seconds")
			quit()
			return
		begin()
	var s=game.traverse
	var id="%d.%d.%d"%[s.chapter,s.room,s.target]
	if id!=last:
		print(id," frame ",frame_no," x ",s.hero.pos)
		last=id
		blocked=0
	blocked+=1
	if blocked>=2200:
		print("STUCK ",id," state ",s.hero.pos," floor ",s.supported," next ",Driver.next_surface," start ",Driver.start_surface," target ",s.nodes[s.target] if s.target<s.nodes.size() else s.exit_pos)
		quit(1)
		return
	Driver.drive(self)
	for key in Keys:
		if want.has(key)==held.has(key): continue
		var event=InputEventKey.new()
		event.keycode=Keys[key]
		event.physical_keycode=Keys[key]
		event.pressed=want.has(key)
		if event.pressed: held[key]=true
		else: held.erase(key)
		Input.parse_input_event(event)
	Input.flush_buffered_events()
