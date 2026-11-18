extends Node2D
const Book=preload("res://game/campaign.gd")
const InputSetup=preload("res://game/controls.gd")
var prefs=preload("res://game/profile.gd").new()
var sound=preload("res://game/sound.gd").new()
var arena=preload("res://game/arena.gd").new()
var ui=preload("res://game/interface.gd").new()
var board=preload("res://game/switchboard.gd").new()
var traverse=preload("res://game/catwalk.gd").new()
var paused_from="play"
var closing=false
var mode="title"
var parent_menu="title"
var cursor=0
var story_line=0
var story_age=0.0
var scene_age=0.0
var real_time=0.0
var transition=0.0
var pad=false
var mouse_active=false
var manual_page=0
var archive_page=0
var chapter_page=0
var current_record=0
var launch_index=0
var confirm_action=""
var confirm_text=""
var launch_mode="new"
var last_result={}
var run_score=0
var start_score=0
var ending_order=0
var credits_from="title"
var journal_from="archive"
var was_playing=false
var stick_lock=false
var ready_for_input=false
func _ready():
	InputSetup.install()
	prefs.read()
	if prefs.fullscreen and DisplayServer.get_name()!="headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	add_child(sound)
	sound.setup(prefs)
	add_child(arena)
	arena.setup(self)
	for subgame in [board,traverse]:
		subgame.hide()
		add_child(subgame)
		subgame.finished.connect(finish_interlude)
		subgame.checkpoint_changed.connect(save_interlude)
	get_tree().auto_accept_quit=false
	ui.game=self
	add_child(ui)
	arena.hide()
	sound.track("title")
	ready_for_input=true
func _physics_process(dt):
	real_time+=dt
	scene_age+=dt
	story_age+=dt
	transition=maxf(0,transition-dt*2.8)
	if mode in ["play","memory"]: arena.tick(dt)
	elif mode=="traverse": traverse.tick(dt)
	elif mode=="switchboard": prefs.active_seconds+=dt
	ui.queue_redraw()
func change(m:String,idx:=0):
	mode=m
	cursor=idx
	scene_age=0
	transition=1.0 if m in ["title","story","results","ending","credits"] else 0
	sound.duck=0.60 if m in ["story","pause","options","manual","results","record"] else 1.0
	arena.visible=m in ["play","memory","memory_intro","memory_outro","story","pause","results","fail","broadcast","ending"] or (m in ["options","manual","confirm"] and parent_menu=="pause")
	var backing=m in ["pause","manual","options","confirm"] and paused_from in ["traverse","switchboard"] and (m=="pause" or parent_menu=="pause")
	board.visible=m=="switchboard" or (backing and paused_from=="switchboard")
	traverse.visible=m=="traverse" or (backing and paused_from=="traverse")
	if board.visible or traverse.visible: arena.hide()
	if m=="title": sound.track("title")
	ui.queue_redraw()
func launch(ch:int,part:int,from_checkpoint:bool):
	launch_index=ch
	if not from_checkpoint:
		prefs.chapter=ch
		prefs.route_stats={}
		prefs.interlude={}
		prefs.broadcast_pending=false
		prefs.section=part
		prefs.checkpoint_health=100
		prefs.score=run_score
		prefs.unlock=maxi(prefs.unlock,ch)
		prefs.save()
	else: run_score=prefs.score
	start_score=run_score
	arena.start(ch,part,prefs.checkpoint_health)
	sound.track("workshop" if ch==0 else ("boss" if arena.kind=="boss" else Book.PLACES[ch][1]))
	if from_checkpoint and not prefs.route_stats.is_empty():
		var data=prefs.route_stats
		arena.hits_taken=int(data.get("hits",0))
		arena.best_combo=int(data.get("combo",0))
		arena.chapter_time=float(data.get("seconds",0))
		arena.defeated=int(data.get("ko",0))
		start_score=int(data.get("start_score",run_score))
	if from_checkpoint and not prefs.interlude.is_empty():
		start_interlude(prefs.interlude)
		return
	if from_checkpoint and prefs.broadcast_pending:
		change("broadcast")
		return
	if part==0:
		story_line=0
		story_age=0
		change("story")
	else: change("play")
func checkpoint():
	prefs.chapter=arena.chapter
	prefs.section=arena.section
	prefs.route_stats={"hits":arena.hits_taken,"combo":arena.best_combo,"seconds":arena.chapter_time,"ko":arena.defeated,"start_score":start_score}
	prefs.checkpoint_health=clampi(arena.hero.hp,55,100)
	prefs.score=run_score
	prefs.save()
func section_finished():
	if arena.chapter==0 or arena.section==5:
		var grade="S" if arena.hits_taken<=4 else ("A" if arena.hits_taken<=15 else "B")
		var key=str(arena.chapter)
		var pts=run_score-start_score
		if pts>int(prefs.best.get(key,0)): prefs.best[key]=pts
		last_result={"grade":grade,"score":pts,"combo":arena.best_combo,"time":arena.chapter_time,"ko":arena.defeated}
		prefs.score=run_score
		if arena.chapter==15:
			prefs.broadcast_pending=true
			prefs.save()
			change("broadcast")
		else:
			prefs.route_stats={}
			prefs.chapter=arena.chapter+1
			prefs.section=0
			prefs.unlock=maxi(prefs.unlock,prefs.chapter)
			prefs.checkpoint_health=100
			prefs.save()
			change("results")
		return
	var branch=arena.section==2
	var past=arena.section==4 and arena.chapter in arena.memoryrun.STATIONS
	arena.setup_section(arena.section+1,false)
	checkpoint()
	if branch: start_interlude({})
	elif past: start_interlude({"mode":"memory"})
func failure():
	sound.fx("alarm",0.65)
	change("fail")
func back_to_title():
	prefs.save()
	change("title")
func items()->Array:
	match mode:
		"title":
			var a=[]
			if prefs.chapter>=0: a.append(["continue","继续接力"])
			a.append_array([["new","开始新航线"],["chapters","章节重播"],["archive","声音档案"],["options","设置"],["credits","制作名单"],["quit","退出"]])
			return a
		"pause": return [["resume","回到现场"],["manual","操作手册"],["options","设置"],["retry","重试本段"],["home","回到标题"]]
		"options": return [["music","音乐"],["effects","音效"],["difficulty","难度"],["tremor","屏幕震动"],["calm","低动态画面"],["fullscreen","全屏"],["back","返回"]]
		"record","credits": return [["back","返回"]]
		"manual": return [["manual_prev","上一页"],["manual_next","下一页"],["back","返回"]]
		"confirm": return [["cancel","取消"],["yes","确定"]]
		"fail": return [["retry_now","从本段重试"],["options","调整设置"],["home","回到标题"]]
		"results": return [["next","前往下一站"],["home","回到标题"]]
		"broadcast": return [["names","先读出被遗漏的名字"],["measure","先播出未经删改的潮位"]]
		"memory_intro": return [["read_tape","播放现场录音"]]
		"memory_outro": return [["close_tape","回到今夜"]]
		"ending": return [["closing","听完最后一段广播"]]
		"newgame": return [["easy","故事 · 宽容的战斗"],["normal","街机 · 标准战斗"],["hard","暴潮 · 强敌压境"],["back","返回"]]
		"archive","chapters":
			var a=[]
			var page=archive_page if mode=="archive" else chapter_page
			for i in range(page*5,mini(page*5+5,16)):
				a.append([str(i),Book.PLACES[i][9] if mode=="archive" else Book.PLACES[i][0]])
			a.append(["page_prev","上一页"])
			a.append(["page_next","下一页"])
			a.append(["back","返回"])
			return a
	return []
func _notification(what):
	if what==NOTIFICATION_WM_CLOSE_REQUEST and ready_for_input:
		request_exit()
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and mode in ["play","memory","switchboard","traverse"] and ready_for_input:
		open_pause()
func open_pause():
	paused_from=mode
	parent_menu="pause"
	change("pause")
func _input(e):
	if not ready_for_input: return
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and absf(e.axis_value)>0.25):
		pad=true
		mouse_active=false
	elif e is InputEventKey or e is InputEventMouseButton:
		pad=false
		mouse_active=false
	if e is InputEventKey and e.echo: return
	if e is InputEventKey and e.pressed and e.keycode==KEY_F11:
		set_option("fullscreen",1)
		return
	if mode in ["play","memory","switchboard","traverse"]:
		if e.is_action_pressed("back"): open_pause()
		return
	if e is InputEventMouseMotion:
		mouse_active=true
		var hover=ui.hit(e.position)
		if hover>=0: cursor=hover
		return
	if e is InputEventMouseButton and e.pressed and e.button_index==MOUSE_BUTTON_LEFT:
		if mode=="story":
			advance_story()
			return
		var clicked=ui.hit(e.position)
		if clicked>=0:
			cursor=clicked
			activate()
		return
	if e is InputEventJoypadMotion:
		if absf(e.axis_value)<0.25: stick_lock=false
		if stick_lock or absf(e.axis_value)<0.7: return
		if e.axis not in [JOY_AXIS_LEFT_X,JOY_AXIS_LEFT_Y]: return
		stick_lock=true
	if e.is_action_pressed("back") or (e is InputEventJoypadButton and e.pressed and e.button_index==JOY_BUTTON_B):
		go_back()
		return
	if mode=="story":
		if e.is_action_pressed("advance"): advance_story()
		return
	var a=items()
	if a.is_empty(): return
	if e.is_action_pressed("upward") or e.is_action_pressed("downward"):
		var inc=1 if e.is_action_pressed("downward") else -1
		cursor=posmod(cursor+inc,a.size())
		sound.fx("select",0.55)
	elif e.is_action_pressed("leftward") or e.is_action_pressed("rightward"):
		var dir=1 if e.is_action_pressed("rightward") else -1
		if mode=="options": set_option(a[cursor][0],dir)
		elif mode in ["archive","chapters"]: turn_page(dir)
		elif mode=="manual": manual_page=posmod(manual_page+dir,4)
		else:
			cursor=posmod(cursor+dir,a.size())
			sound.fx("select",0.55)
	elif e.is_action_pressed("advance"): activate()
func advance_story():
	if story_age<0.16: return
	story_line+=1
	story_age=0
	sound.fx("radio",0.37,1.12)
	if story_line>=3: change("play")
func turn_page(d:int):
	if mode=="archive": archive_page=posmod(archive_page+d,4)
	else: chapter_page=posmod(chapter_page+d,4)
	cursor=0
	sound.fx("select",0.6)
func go_back():
	match mode:
		"story": change("play")
		"pause": change(paused_from)
		"record": change("archive",current_record%5)
		"options","manual","confirm": change(parent_menu)
		"archive","chapters","newgame": change("title")
		"credits": change("title")
		"results","fail": back_to_title()
		"ending": close_ending()
		"memory_intro": change("memory")
		"memory_outro": finish_interlude()
		"broadcast": pass
		"title":
			parent_menu="title"
			ask("quit","结束今晚的播送并退出游戏？")
func ask(act:String,msg:String):
	confirm_action=act
	confirm_text=msg
	change("confirm")
func set_option(id:String,d:int):
	match id:
		"music": prefs.music=clampi(prefs.music+d,0,10)
		"effects": prefs.effects=clampi(prefs.effects+d,0,10)
		"difficulty": prefs.difficulty=posmod(prefs.difficulty+d,3)
		"tremor": prefs.tremor=not prefs.tremor
		"calm": prefs.calm=not prefs.calm
		"fullscreen":
			prefs.fullscreen=not prefs.fullscreen
			if DisplayServer.get_name()!="headless": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if prefs.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		_: return
	sound.fx("select",0.60)
	prefs.save()
func activate():
	var a=items()
	if a.is_empty() or cursor>=a.size(): return
	var id:String=a[cursor][0]
	sound.fx("confirm",0.53)
	if mode=="options" and id!="back":
		set_option(id,1)
		return
	if mode in ["archive","chapters"] and id.is_valid_int():
		var number=int(id)
		if mode=="archive":
			if prefs.records.has(id):
				current_record=number
				change("record")
		else:
			if number<=prefs.unlock:
				launch_index=number
				parent_menu="chapters"
				ask("replay","从《"+Book.PLACES[number][0]+"》重新出发？接力进度将切换至此站。")
		return
	match id:
		"read_tape": change("memory")
		"close_tape": finish_interlude()
		"continue": launch(prefs.chapter,prefs.section,true)
		"new":
			if prefs.chapter>=0:
				parent_menu="title"
				ask("new","重新开始主线？当前接力将被替换，已收录的磁带保留。")
			else: change("newgame",prefs.difficulty)
		"easy","normal","hard":
			prefs.difficulty=["easy","normal","hard"].find(id)
			run_score=0
			prefs.active_seconds=0
			launch(0,0,false)
		"chapters":
			chapter_page=prefs.unlock/5
			change("chapters")
		"archive":
			archive_page=0
			change("archive")
		"page_prev": turn_page(-1)
		"page_next": turn_page(1)
		"manual_prev","manual_next": manual_page=posmod(manual_page+(1 if id=="manual_next" else -1),4)
		"options","manual":
			if id=="manual": manual_page=2 if paused_from=="traverse" else (3 if paused_from=="switchboard" else 0)
			parent_menu=mode
			change(id)
		"credits": change("credits")
		"quit":
			parent_menu="title"
			ask("quit","结束今晚的播送并退出游戏？")
		"yes":
			match confirm_action:
				"quit":
					request_exit()
				"new": change("newgame",prefs.difficulty)
				"replay":
					run_score=0
					launch(launch_index,0,false)
				"retry": launch(prefs.chapter,prefs.section,true)
		"cancel","back": go_back()
		"resume": change(paused_from)
		"home": back_to_title()
		"retry":
			parent_menu="pause"
			ask("retry","从本段接点重新开始？")
		"retry_now": launch(prefs.chapter,prefs.section,true)
		"next": launch(prefs.chapter,0,false)
		"names","measure":
			ending_order=0 if id=="names" else 1
			story_line=0
			prefs.completed=true
			prefs.broadcast_pending=false
			prefs.unlock=15
			prefs.chapter=-1
			prefs.section=0
			prefs.save()
			sound.track("ending")
			change("ending")
		"closing":
			if story_line<2:
				story_line+=1
				story_age=0
			else: close_ending()
func close_ending():
	prefs.save()
	change("credits")

func start_interlude(saved):
	var station=arena.chapter
	if saved.get("mode","")=="memory":
		arena.memory_index=arena.memoryrun.STATIONS.find(station)
		arena.memoryrun.setup(arena,station,saved.get("state",{}))
		arena.backdrop.set_stage(station)
		sound.track("past")
		change("memory_outro" if saved.get("outro",false) else ("memory" if saved.has("state") else "memory_intro"))
		if not saved.get("outro",false): save_interlude(arena.memoryrun.snapshot())
		return
	var part="switchboard" if station in [2,5,8,11,14] else "traverse"
	change(part)
	if part=="traverse": sound.track("catwalk")
	var controller=board if part=="switchboard" else traverse
	controller.setup(self,station,saved.get("state",{}))
	save_interlude(controller.checkpoint_state())
func save_interlude(data):
	prefs.interlude={"state":data,"mode":"memory" if arena.memory_mode else mode}
	prefs.score=run_score
	prefs.save()
func memory_outro():
	prefs.interlude={"state":arena.memoryrun.snapshot(),"mode":"memory","outro":true}
	prefs.save()
	change("memory_outro")
func finish_interlude():
	if arena.memory_mode:
		var arc=arena.chapter
		var part=arena.section
		arena.start(arc,part,prefs.checkpoint_health)
		arena.hits_taken=int(prefs.route_stats.get("hits",0))
		arena.best_combo=int(prefs.route_stats.get("combo",0))
		arena.chapter_time=float(prefs.route_stats.get("seconds",0))
		arena.defeated=int(prefs.route_stats.get("ko",0))
	prefs.interlude={}
	change("play")
	sound.track("boss" if arena.kind=="boss" else Book.PLACES[arena.chapter][1])
	arena.tip_once("线路恢复 · 继续前往下一个接点")
	checkpoint()
func request_exit():
	if closing: return
	closing=true
	prefs.save()
	sound.silence()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()
