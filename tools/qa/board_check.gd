extends SceneTree
## Isolated normal-input exercise for all fifteen puzzle boards.
const Board=preload("res://game/switchboard.gd")
const Driver=preload("res://tools/qa/wiring_driver.gd")
const KEYS={"r":KEY_D,"l":KEY_A,"u":KEY_W,"d":KEY_S,"use":KEY_E,"heavy":KEY_K,"jab":KEY_J}
var game
var board
var driver=Driver.new()
var frame_no=0
var want={}
var held={}
var chapters=[2,5,8,11,14]
var index=0
var done=false
var bad=false
var snapshots=0
var checks=0

func mark(key): want[key]=true
func tap(key,interval=6):
	if frame_no%interval==0: mark(key)

func _initialize(): call_deferred("start")
func start():
	game=load("res://game/Main.tscn").instantiate()
	game.prefs.path=OS.get_temp_dir().path_join("undertow-board-check-%d.cfg"%Time.get_ticks_usec())
	root.add_child(game)
	game.mode="switchboard"
	board=Board.new()
	game.add_child(board)
	board.finished.connect(func(): done=true)
	board.checkpoint_changed.connect(checkpoint)
	board.setup(game,chapters[0])
	await process_frame
	await test_controls()
	if bad: return
	physics_frame.connect(pilot)
func checkpoint(state):
	snapshots+=1
	# Round-trip the same concrete snapshot through a fresh instance.
	var copy=Board.new()
	copy.setup(game,board.chapter,state)
	if not verify(copy.wire==board.wire and copy.solved==board.solved, "copy.wire==board.wire and copy.solved==board.solved"): return
	if not verify(copy.moves==board.moves and copy.cursor==board.cursor, "copy.moves==board.moves and copy.cursor==board.cursor"): return
	copy.free()
	checks+=1
func pilot():
	frame_no+=1
	want={}
	if done:
		print("PATCH station=",chapters[index]," frames=",frame_no," turns=",board.moves)
		done=false
		index+=1
		if index>=chapters.size():
			print("PATCH PASS 15/15 banks, persisted states=",checks," controlled_seconds=",frame_no/60.0)
			physics_frame.disconnect(pilot)
			game.queue_free()
			cleanup()
			return
		board.setup(game,chapters[index])
	driver.drive(self,board)
	for id in KEYS:
		var down=want.has(id)
		if down==held.has(id): continue
		var e=InputEventKey.new()
		e.physical_keycode=KEYS[id]
		e.keycode=KEYS[id]
		e.pressed=down
		Input.parse_input_event(e)
		if down: held[id]=true
		else: held.erase(id)
	Input.flush_buffered_events()
	if driver.unsolved or frame_no>18000:
		printerr("PATCH STALLED ",board.chapter,"/",board.zone," moves=",board.moves)
		quit(1)
func cleanup():
	for _i in 15: await process_frame
	quit()

func mouse_button(position,button):
	for state in [true,false]:
		var event=InputEventMouseButton.new()
		event.position=position
		event.button_index=button
		event.pressed=state
		root.push_input(event,true)

func press_pad(button,pressed):
	var event=InputEventJoypadButton.new()
	event.device=0
	event.button_index=button
	event.pressed=pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func test_controls():
	var i=board.cursor
	var pos=board.cell_rect(i).get_center()
	var start=board.wire.duplicate()
	var m=board.moves
	mouse_button(pos,MOUSE_BUTTON_LEFT)
	if not verify(board.moves==m+1, "board.moves==m+1"): return
	mouse_button(pos,MOUSE_BUTTON_RIGHT)
	if not verify(board.moves==m+2 and board.wire==start, "board.moves==m+2 and board.wire==start"): return
	press_pad(JOY_BUTTON_A,true)
	press_pad(JOY_BUTTON_A,false)
	if not verify(game.pad and board.moves==m+3, "game.pad and board.moves==m+3"): return
	press_pad(JOY_BUTTON_Y,true)
	press_pad(JOY_BUTTON_Y,false)
	if not verify(board.moves==m+4 and board.wire==start, "board.moves==m+4 and board.wire==start"): return
	press_pad(JOY_BUTTON_DPAD_RIGHT,true)
	for _i in 3: await physics_frame
	press_pad(JOY_BUTTON_DPAD_RIGHT,false)
	if not verify(board.cursor==i+1, "board.cursor==i+1"): return
	board.hide()
	mouse_button(pos,MOUSE_BUTTON_LEFT)
	if not verify(board.moves==m+4, "board.moves==m+4"): return
	board.show()
	game.mode="pause"
	mouse_button(pos,MOUSE_BUTTON_LEFT)
	if not verify(board.moves==m+4, "board.moves==m+4"): return
	game.mode="switchboard"
	game.prefs.difficulty=0
	press_pad(JOY_BUTTON_X,true)
	press_pad(JOY_BUTTON_X,false)
	if not verify(board.hint_idx>=0 and board.hint_age>0, "board.hint_idx>=0 and board.hint_age>0"): return
	game.prefs.difficulty=1
	board.setup(game,chapters[0])
	print("PATCH controls: left/right mouse, pad A/Y, pad directions, easy hint, hidden/pause isolation")

func verify(condition:bool,what:String)->bool:
	if condition: return true
	bad=true
	printerr("PATCH CHECK FAILED: ",what)
	quit(1)
	return false
