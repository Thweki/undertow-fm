extends SceneTree
# Black-box inputs and read-only observation of the live campaign.
# godot --headless --fixed-fps 60 --audio-driver Dummy -s tools/qa/pilot.gd -- /tmp/fresh-run
const KEYMAP={"l":KEY_A,"r":KEY_D,"u":KEY_W,"d":KEY_S,"jab":KEY_J,"heavy":KEY_K,"skill":KEY_L,"dodge":KEY_SPACE,"use":KEY_E,"advance":KEY_ENTER,"back":KEY_ESCAPE}
const PADMAP={"l":JOY_BUTTON_DPAD_LEFT,"r":JOY_BUTTON_DPAD_RIGHT,"u":JOY_BUTTON_DPAD_UP,"d":JOY_BUTTON_DPAD_DOWN,"jab":JOY_BUTTON_X,"heavy":JOY_BUTTON_Y,"skill":JOY_BUTTON_RIGHT_SHOULDER,"dodge":JOY_BUTTON_B,"use":JOY_BUTTON_A,"advance":JOY_BUTTON_A,"back":JOY_BUTTON_START}
const Memory=preload("res://tools/qa/memory_driver.gd")
const Duel=preload("res://tools/qa/duel_driver.gd")
const Field=preload("res://tools/qa/field_driver.gd")
const Platform=preload("res://tools/qa/platform_driver.gd")
const Wiring=preload("res://tools/qa/wiring_driver.gd")
const ACTIVE=["combat","movement","interaction"]
var wiring=Wiring.new()
var interlude_stats={}
var observed_inputs={}
var wait_reasons={}
var memories={}
var game
var folder=""
var frame_no=0
var wall_start=0
var held={}
var physical_held={}
var use_pad=false
var want={}
var section_stats={}
var key=""
var modes={}
var finished_sections={}
var retries=0
var retry_counts={}
var roles={}
var moves={}
var objectives={}
var collected={}
var last_mode=""
var lessons={}
var difficulty=1
var ending=0
var exercise_recovery=false
var induced_defeat=false
var resume_stage=0
var input_counts={}
var resumed_checkpoint=""
var snapshot_request={}
var restored={}
var attempted=""

var failed=false

func _initialize():
	call_deferred("start_pilot")

func start_pilot():
	var args=OS.get_cmdline_user_args()
	folder=args[0] if args.size() else OS.get_temp_dir().path_join("undertow-pilot-%d"%Time.get_ticks_usec())
	for arg in args.slice(1):
		match arg:
			"story": difficulty=0
			"hard": difficulty=2
			"measure": ending=1
			"recovery": exercise_recovery=true
			"pad": use_pad=true
			_:
				printerr("Unknown pilot option ",arg)
				quit(2)
				return
	DirAccess.make_dir_recursive_absolute(folder)
	var path=folder.path_join("pilot-profile.cfg")
	if FileAccess.file_exists(path):
		printerr("Pilot requires a fresh output directory.")
		quit(2)
		return
	game=load("res://game/Main.tscn").instantiate()
	game.prefs.path=path
	root.add_child(game)
	wall_start=Time.get_ticks_msec()
	print("PILOT start ",folder)
	physics_frame.connect(drive)

func mark(id):
	want[id]=true

func tap(id, period=9):
	if frame_no%period==0:
		mark(id)

func apply_keys():
	var wanted={}
	var mapping=PADMAP if use_pad else KEYMAP
	for id in want:
		wanted[mapping[id]]=true
		if not held.has(id): input_counts[id]=int(input_counts.get(id,0))+1
	held=want.duplicate()
	var controls=physical_held.merged(wanted)
	for control in controls:
		var down=wanted.has(control)
		if physical_held.has(control)==down: continue
		var event
		if use_pad:
			event=InputEventJoypadButton.new()
			event.device=0
			event.button_index=control
		else:
			event=InputEventKey.new()
			event.physical_keycode=control
			event.keycode=control
		event.pressed=down
		Input.parse_input_event(event)
	physical_held=wanted
	Input.flush_buffered_events()

func go_to(target:Vector2,xtol=4.5,ytol=4.5):
	var v=target-game.arena.hero.pos
	if absf(v.x)>xtol: mark("r" if v.x>0 else "l")
	if absf(v.y)>ytol: mark("d" if v.y>0 else "u")
	return absf(v.x)<=xtol and absf(v.y)<=ytol

func tutorial():
	var a=game.arena
	lessons[str(a.lesson)]=true
	match a.lesson:
		0: go_to(a.lesson_coord,10,9)
		1,2,4:
			var h=a.hero
			var delta=a.device-h.pos
			if absf(delta.x)>42 or absf(delta.y)>12:
				go_to(a.device-Vector2(30 if delta.x>=0 else -30,0),5,6)
			else:
				if h.face!=int(signf(delta.x)) and absf(delta.x)>2:
					mark("r" if delta.x>0 else "l")
				tap({1:"jab",2:"heavy",4:"skill"}[a.lesson],7)
		3:
			if a.lesson_pulse>1.11 and a.lesson_pulse<1.50:
				tap("dodge",4)
		5:
			if a.is_near(a.hero.pos,a.device,33): tap("use",5)
			else: go_to(a.device)

func fight(enemy):
	var a=game.arena
	var h=a.hero
	var delta=enemy.pos-h.pos
	var side=1 if delta.x>=0 else -1
	var clustered=0
	var imminent=false
	for e in a.enemies:
		if not e.alive(): continue
		var v=e.pos-h.pos
		if absf(v.x)<94 and absf(v.y)<45: clustered+=1
		if absf(v.x)>e.reach+14 or absf(v.y)>26: continue
		if e.state in ["jab","heavy","skill"] and not e.struck and e.time>e.length*0.10:
			imminent=true
		elif e.state=="warn" and e.time>e.length-.10 and e.kind in ["boss","brute","tech"]:
			imminent=true
	var can_buffer=h.can_move() or (h.state in ["jab","heavy","skill"] and h.struck and h.time>h.length*.58)
	if imminent and h.invincible<.06 and h.cooldown<=0 and (h.can_move() or h.state in ["heavy","jab"]):
		if h.pos.y<292: mark("d")
		else: mark("u")
		tap("dodge",3)
		return
	var use_pulse=a.flux>=40 and (clustered>=2 or (a.flux>=79 and clustered>0) or (imminent and clustered))
	if use_pulse and can_buffer:
		tap("skill",4)
		return
	if absf(delta.y)>8: mark("d" if delta.y>0 else "u")
	var heavy=enemy.kind in ["guard","brute","boss"] or (absf(delta.x)>46 and absf(delta.x)<62)
	var reach=59 if heavy else 43
	if absf(delta.x)>reach-5 or (h.face!=side and absf(delta.x)>1):
		mark("r" if side>0 else "l")
	if absf(delta.x)<=reach and absf(delta.y)<=17 and can_buffer:
		tap("heavy" if heavy else "jab",5)

func play_arena():
	var a=game.arena
	var h=a.hero
	if h==null or not h.alive(): return
	if a.done:
		if a.section<5 and a.chapter>0: go_to(a.destination,9,10)
		return
	if a.chapter==0:
		tutorial()
		return
	var item_pos=null
	var item_dist=INF
	if h.hp<74:
		for g in a.goods:
			var dist=h.pos.distance_to(g.p)
			if dist<190 and dist<item_dist:
				item_pos=g.p
				item_dist=dist
	if item_pos!=null:
		go_to(item_pos,6,6)
		return
	if a.has_tape and h.pos.distance_to(a.tape_pos)<240:
		go_to(a.tape_pos,9,6)
		return
	if Field.drive(self): return
	if Duel.drive(self): return
	var enemy=null
	var cost=INF
	for e in a.enemies:
		if not e.alive(): continue
		roles[e.kind]=true
		var v=e.pos-h.pos
		var distance=absf(v.x)+absf(v.y)*1.35
		if distance<cost:
			cost=distance
			enemy=e
	var fighting=a.kind in ["fight","elite","boss"]
	if enemy!=null and (fighting or cost<133 or a.jammed):
		fight(enemy)
		return
	var target=a.target_point()
	if fighting:
		if h.pos.x<a.base+334: go_to(Vector2(a.base+337,287),12,8)
		return
	if a.kind in ["relay","escort"]:
		if a.kind=="relay" and a.spot_idx<a.spots.size():
			if a.is_near(h.pos,target,35): tap("use",5)
			else: go_to(target,8,8)
		else: go_to(target,20,12)
		return
	if not a.is_near(h.pos,target,34):
		go_to(target,9,8)
	elif a.kind=="tune":
		var val=a.tune_phase if a.tune_phase<=1.0 else 2.0-a.tune_phase
		if absf(val-a.tune_centers[a.spot_idx])<0.115: tap("use",4)
	else:
		mark("use")

func activity():
	var a=game.arena
	var h=a.hero
	if not h.alive() or h.state=="hurt": return "recovery"
	if want.has("use"): return "interaction"
	if h.state in ["jab","heavy","skill","dodge"] or want.has("jab") or want.has("heavy") or want.has("skill") or want.has("dodge"):
		return "combat"
	if want.has("l") or want.has("r") or want.has("d") or want.has("u"): return "movement"
	if a.done: return "transition"
	return "waiting"

func preserve_checkpoint(kind,expected):
	var dir=folder.path_join("restart-"+kind)
	DirAccess.make_dir_recursive_absolute(dir)
	var error=DirAccess.copy_absolute(game.prefs.path,dir.path_join("pilot-profile.cfg"))
	if error!=OK:
		printerr("Could not preserve the isolated checkpoint: ",error)
		complete(false)
		return
	var meta=expected.duplicate(true)
	meta.score=game.prefs.score
	meta.records=game.prefs.records.duplicate(true)
	meta.difficulty=game.prefs.difficulty
	meta.broadcast=game.prefs.broadcast_pending
	var file=FileAccess.open(dir.path_join("expected.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(meta,"  "))
	file.close()

func save_relaunch(kind):
	resumed_checkpoint="%02d.%d"%[game.arena.chapter,game.arena.section]
	var state=game.prefs.interlude.get("state",{}).duplicate(true)
	snapshot_request={"kind":kind,"chapter":game.arena.chapter,"section":game.arena.section,"saved":state}
	want={}
	mark("back")
	resume_stage=1

func restore_matches()->bool:
	var kind=snapshot_request.kind
	if game.arena.chapter!=snapshot_request.chapter or game.arena.section!=snapshot_request.section: return false
	var old=snapshot_request.saved
	match kind:
		"traverse": return game.traverse.room==int(old.room) and game.traverse.target==int(old.target)
		"switchboard": return game.board.zone==int(old.zone) and game.board.turns==old.rotations and game.board.moves==int(old.moves)
		"memory": return game.arena.memoryrun.room==int(old.room) and game.arena.memoryrun.station==int(old.station)
	return true

func drive():
	frame_no+=1
	want={}
	var mode=game.mode
	if resume_stage==2 and mode==snapshot_request.kind:
		if not restore_matches():
			printerr("Saved checkpoint did not round-trip ",snapshot_request)
			complete(false)
			return
		restored[mode]=resumed_checkpoint
		print("PILOT restored ",mode," ",resumed_checkpoint)
		resume_stage=0
	modes[mode]=modes.get(mode,0)+1
	if last_mode!=mode:
		if exercise_recovery and mode=="broadcast":
			preserve_checkpoint("broadcast",{"kind":"broadcast","chapter":game.arena.chapter,"section":game.arena.section,"saved":{}})
		if mode=="fail":
			retries+=1
			if exercise_recovery and game.arena.chapter==3:
				induced_defeat=true
			retry_counts[attempted]=retry_counts.get(attempted,0)+1
			print("PILOT retry ",attempted," #",retry_counts[attempted])
		if mode=="credits" and game.prefs.completed:
			complete(true)
			return
		last_mode=mode
	if mode=="play":
		var a=game.arena
		var next_key="%02d.%d"%[a.chapter,a.section]
		if next_key!=key or not section_stats.has(key):
			if key!="":
				finished_sections[key]=true
				print_section(key)
			key=next_key
			section_stats[key]={"kind":a.kind,"frames":0,"combat":0,"movement":0,"interaction":0,"recovery":0,"transition":0,"waiting":0,"kos_start":a.defeated,"peak_combo":0,"low_hp":100}
			objectives[a.kind]=true
		attempted=next_key
		if exercise_recovery and a.chapter==2 and a.section==2 and resume_stage==0 and not restored.has("play"):
			save_relaunch("play")
		elif exercise_recovery and a.chapter==3 and a.kind=="fight" and not induced_defeat:
			pass
		else:
			play_arena()
		var entry=section_stats[key]
		entry.frames+=1
		var label=activity()
		entry[label]+=1
		meter_inputs(entry,label,a.hero,a.stop_time>0)
		if label=="waiting":
			var why="other"
			if a.kind=="tune" and a.near_device: why="tuner timing"
			elif a.live_count()>0: why="opponent approach"
			elif a.kind in ["fight","elite","boss"]: why="wave arrival"
			elif a.kind in ["relay","escort"]: why="field objective"
			elif a.chapter==0: why="tutorial timing"
			wait_reasons[why]=int(wait_reasons.get(why,0))+1
		entry.peak_combo=maxi(entry.peak_combo,a.combo)
		entry.low_hp=mini(entry.low_hp,a.hero.hp)
		moves[a.hero.state]=true
		collected=game.prefs.records.duplicate()
		if int(entry.frames)%7200==0:
			print("PILOT watchdog ",key," kind=",a.kind," lesson=",a.lesson," sec=",entry.frames/60," hp=",a.hero.hp," hero=",a.hero.pos," target=",a.target_point()," live=",a.live_count()," progress=",a.progress)
		if entry.frames>60*360 or int(retry_counts.get(key,0))>11:
			complete(false)
			return
	elif mode=="memory":
		var a=game.arena
		var run=a.memoryrun
		var id="%02d.memory.%02d"%[a.chapter,run.room]
		var job="%02d.%d.%d"%[run.episode,run.room,run.station]
		memories[job]=true
		if not interlude_stats.has(id):
			interlude_stats[id]={"kind":"memory","frames":0,"combat":0,"movement":0,"interaction":0,"recovery":0,"transition":0,"waiting":0}
		attempted=id
		if exercise_recovery and not restored.has("memory") and a.chapter==3 and run.room==1 and run.station==1:
			save_relaunch("memory")
		elif a.hero.alive(): Memory.drive(self)
		var label=activity()
		var entry=interlude_stats[id]
		entry.frames+=1
		entry[label]+=1
		meter_inputs(entry,label,a.hero,a.stop_time>0)
		if entry.frames%3600==0: print("PILOT memory ",id," station=",run.station," action=",run.action," hp=",a.hero.hp," phase=",run.phase," target=",run.node," hero=",a.hero.pos," live=",a.live_count()," sequence=",run.sequence," wanted=",want.keys()," jammed=",a.jammed," done=",a.done," remaining=",run.signal_pattern)
		if entry.frames>60*210:
			complete(false)
			return
	elif mode in ["traverse","switchboard"]:
		var unit=game.traverse if mode=="traverse" else game.board
		var room=unit.room if mode=="traverse" else unit.zone
		var name="%02d.%s.%02d"%[unit.chapter,mode,room]
		if not interlude_stats.has(name):
			interlude_stats[name]={"kind":mode,"frames":0,"combat":0,"movement":0,"interaction":0,"recovery":0,"transition":0,"waiting":0}
		attempted=name
		if exercise_recovery and not restored.has(mode) and ((mode=="traverse" and unit.chapter==1 and unit.target>=1) or (mode=="switchboard" and unit.chapter==2 and unit.zone==1 and unit.moves>=9)):
			save_relaunch(mode)
		elif mode=="traverse": Platform.drive(self)
		else: wiring.drive(self,unit)
		var label="waiting"
		var actor=unit.hero if mode=="traverse" else null
		if mode=="traverse" and unit.control_lock>0: label="recovery"
		elif want.has("use") or (mode=="switchboard" and want.has("heavy")): label="interaction"
		elif mode=="traverse" and (actor.state in ["jab","heavy","skill"] or want.has("heavy") or want.has("jab") or want.has("skill")): label="combat"
		elif mode=="traverse" and (not unit.grounded or want.has("dodge")): label="movement"
		elif want.has("r") or want.has("l") or want.has("d") or want.has("u"): label="movement"
		var entry=interlude_stats[name]
		entry.frames+=1
		entry[label]+=1
		meter_inputs(entry,label,actor,false)
		if entry.frames%3600==0:
			print("PILOT interlude ",name," frames=",entry.frames," goal=",unit.target if mode=="traverse" else wiring.selected," pos=",unit.hero.pos if mode=="traverse" else unit.cursor)
		if entry.frames>60*240 or wiring.unsolved:
			complete(false)
			return
	elif mode=="pause" and resume_stage==1:
		if game.cursor<game.items().size()-1: tap("d",9)
		else: tap("advance",9)
	elif mode=="title" and resume_stage==1:
		# Simulate relaunch after the menu saved. Only the isolated profile crosses sessions.
		want={}
		apply_keys()
		preserve_checkpoint(snapshot_request.kind,snapshot_request)
		var path=game.prefs.path
		root.remove_child(game)
		game.free()
		game=load("res://game/Main.tscn").instantiate()
		game.prefs.path=path
		root.add_child(game)
		resume_stage=2
	elif mode=="newgame" and game.cursor!=difficulty:
		tap("d",9)
	elif mode=="broadcast" and game.cursor!=ending:
		tap("d",9)
	elif mode in ["title","newgame","results","fail","broadcast","ending","memory_intro","memory_outro"]:
		tap("advance",11)
	elif mode=="story" and game.story_age>=.52:
		tap("advance",4)
	apply_keys()
	if frame_no>60*20000:
		complete(false)

func meter_inputs(entry,label,actor,hit_stop):
	var keys=want.keys()
	var direct=not keys.is_empty()
	var audit=entry.get("audit",{})
	var cls="keys" if direct else "hands_off"
	audit[cls]=int(audit.get(cls,0))+1
	if hit_stop: audit["hit_stop"]=int(audit.get("hit_stop",0))+1
	if label in ACTIVE and not hit_stop:
		audit["active_excluding_hit_stop"]=int(audit.get("active_excluding_hit_stop",0))+1
	if not direct and actor!=null:
		var reason=actor.state
		if actor.state in ["jab","heavy","skill"]: reason="attack_followthrough" if actor.struck else "attack_windup"
		audit["hands_off_"+reason]=int(audit.get("hands_off_"+reason,0))+1
	entry.audit=audit
	for field in keys: observed_inputs[field]=int(observed_inputs.get(field,0))+1

func print_section(id):
	var s=section_stats[id]
	print("PILOT section ",id," ",s.kind," seconds=",snapped(s.frames/60.0,.1)," active=",snapped((s.combat+s.movement+s.interaction)/60.0,.1)," waiting=",snapped(s.waiting/60.0,.1))

func complete(success):
	if failed: return
	failed=true
	if key!="":
		print_section(key)
		if success: finished_sections[key]=true
	var chapter_stats={}
	var totals={}
	var entries=section_stats.merged(interlude_stats)
	for id in entries:
		var ch=id.split(".")[0]
		if not chapter_stats.has(ch): chapter_stats[ch]={}
		for field in ["frames","combat","movement","interaction","recovery","transition","waiting"]:
			var value=entries[id][field]
			chapter_stats[ch][field]=int(chapter_stats[ch].get(field,0))+value
			totals[field]=int(totals.get(field,0))+value
	var expected_interludes=0
	for ch in game.traverse.ROUTES: expected_interludes+=game.traverse.ROUTES[ch][1].size()
	for ch in game.board.BANKS: expected_interludes+=game.board.BANKS[ch].size()
	for rooms in game.arena.memoryrun.SITES: expected_interludes+=rooms.size()
	var covered=finished_sections.size()==91 and lessons.size()==6 and collected.size()==16 and interlude_stats.size()==expected_interludes and memories.size()==60
	if success and (not covered or (exercise_recovery and (not induced_defeat or restored.size()!=4))): success=false
	var report={"success":success,"all_route_coverage":covered,"ending_choice":game.ending_order,"exercise_recovery":exercise_recovery,"relaunch_checkpoint":resumed_checkpoint,"restored_checkpoints":restored,"induced_defeat":induced_defeat,"input_counts":input_counts,"held_key_frames":observed_inputs,"wait_reasons":wait_reasons,"interlude_sections":interlude_stats,"board_rotations":wiring.turns_sent,"memory_jobs":memories.keys(),"chapter_frames":chapter_stats,"total_frames":totals,"engine":Engine.get_version_info().string,"difficulty":game.prefs.difficulty,"controller":"gamepad" if use_pad else "keyboard","physics_fps":Engine.physics_ticks_per_second,"wall_seconds":(Time.get_ticks_msec()-wall_start)/1000.0,"simulated_seconds":frame_no/60.0,"sections":section_stats,"finished_sections":finished_sections.keys(),"retries":retries,"retries_by_section":retry_counts,"mode_frames":modes,"archive_tapes":collected.keys(),"enemies_seen":roles.keys(),"player_states_seen":moves.keys(),"objectives_seen":objectives.keys(),"tutorial_steps":lessons.keys(),"score":game.run_score,"route_game_seconds":game.prefs.active_seconds}
	var output=FileAccess.open(folder.path_join("pilot.json"),FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	output.close()
	print("PILOT ",("PASS" if success else "STOP")," route=",game.prefs.active_seconds," simulated=",frame_no/60.0," wall=",report.wall_seconds," sections=",section_stats.size())
	quit(0 if success else 1)
