extends Node2D
const Book=preload("res://game/campaign.gd")
const SignalBook=preload("res://game/broadcasts.gd")
const Fighter=preload("res://game/fighter.gd")
var memory_mode=false
var memory_index=0
var memoryrun=preload("res://game/memory_run.gd").new()
var duels=preload("res://game/duels.gd").new()
var field=preload("res://game/fieldwork.gd").new()
var game
var sound
var rng=RandomNumberGenerator.new()
var hero
var enemies=[]
var civilians=[]
var radio_text=""
var radio_left=0.0
var radio_flags=0
var foot_clock=0.0
var sparks=[]
var hazards=[]
var goods=[]
var spots=[]
var texts=[]
var chapter=0
var section=0
var kind="lesson"
var cam=0.0
var focus=160.0
var base=0.0
var extent=0.0
var timer=0.0
var clock=0.0
var phase_time=0.0
var wave=0
var waves=0
var spawn_time=0.0
var next_hazard=0.0
var goal=0.0
var progress=0.0
var work=0.0
var spot_idx=0
var carry=false
var cargo_count=0
var device=Vector2.ZERO
var destination=Vector2.ZERO
var jammed=false
var near_device=false
var tune_phase=0.0
var tune_lock=0.0
var tune_centers=[0.36,0.70,0.46]
var lesson=0
var lesson_hits=0
var lesson_coord=Vector2.ZERO
var lesson_pulse=0.0
var lesson_wave=0
var lesson_small=0.0
var tip=""
var tip_timer=0.0
var wave_banner=""
var wave_timer=0.0
var combo=0
var combo_timer=0.0
var best_combo=0
var hits_taken=0
var defeated=0
var flux=54.0
var stop_time=0.0
var shake=0.0
var serial=0
var done=false
var done_timer=0.0
var failed_timer=0.0
var tape_pos=Vector2.ZERO
var has_tape=false
var last_target
var last_target_time=0.0
var phase_help=0.0
var save_message=0.0
var active_time=0.0
var chapter_time=0.0
var route_seconds=0.0
var rng_seed=0
var backdrop
func setup(g):
	game=g
	sound=g.sound
	backdrop=preload("res://game/world.gd").new()
	add_child(backdrop)
	backdrop.arena=self
func start(ch:int,part:int,health:int):
	memory_mode=false
	chapter=ch
	section=part
	serial=0
	clock=0
	timer=0
	chapter_time=0
	best_combo=0
	hits_taken=0
	defeated=0
	flux=56
	hero=Fighter.new().init("hero",Vector2(95,296),0,game.prefs.difficulty)
	hero.hp=health
	rng_seed=1079+chapter*647
	backdrop.set_stage(ch)
	setup_section(part,true)
func setup_section(part:int,fresh:bool):
	section=part
	rng.seed=rng_seed+part*193
	base=0 if chapter==0 else section*1230
	extent=base+(740 if chapter==0 else 1250)
	kind="lesson" if chapter==0 else Book.ROUTES[chapter][section]
	enemies.clear()
	civilians.clear()
	radio_left=0
	radio_flags=0
	hazards.clear()
	sparks.clear()
	texts.clear()
	goods.clear()
	spots.clear()
	last_target=null
	if fresh: hero.pos=Vector2(base+104,294)
	else: hero.pos=Vector2(base+78,hero.pos.y)
	hero.pose("idle",1)
	cam=clampf(hero.pos.x-224,base,extent-640)
	phase_time=0
	active_time=0
	spawn_time=1.0
	wave=0
	waves=3 if chapter<4 else 4
	if kind=="elite": waves=3
	if kind=="boss": waves=1
	if chapter==1 and section==0: waves=2
	progress=0
	work=0
	spot_idx=0
	carry=false
	cargo_count=0
	done=false
	done_timer=0
	failed_timer=0
	tune_phase=0
	tune_lock=0
	phase_help=6
	tip_timer=0
	wave_timer=0
	combo=0
	combo_timer=0
	stop_time=0
	shake=0
	save_message=2.2
	next_hazard=8.7
	# A relay transmits actual packets. The operator also crosses the arena for bypasses.
	goal=float(78+(chapter%4)*5)
	device=Vector2(base+340,291)
	destination=Vector2(base+1105,283)
	if kind=="escort":
		device=Vector2(base+153,289)
		goal=destination.x-device.x
		add_local(device+Vector2(-28,-8),true)
	if kind in ["tune","rescue"]:
		for i in 3: spots.append(Vector2(base+280+i*332,[277,318,283][i]))
	if kind=="haul":
		device=Vector2(base+622,290)
		spots=[Vector2(base+299,268),Vector2(base+902,318),Vector2(base+758,260)]
	if kind=="fight" or kind=="elite" or kind=="boss":
		device=Vector2(base+455,290)
	if chapter==0:
		lesson=0
		lesson_hits=0
		lesson_coord=Vector2(224,265)
		device=Vector2(365,286)
		lesson_pulse=0
		lesson_wave=0
		lesson_small=0
	has_tape=chapter>0 and section==2 and not game.prefs.records.has(str(chapter))
	tape_pos=Vector2(base+232,326)
	field.reset(self)
	duels.reset(self)
	if part==0 and not fresh: save_message=0
	if kind=="boss":
		sound.track("boss")
	elif chapter>0: sound.track(Book.PLACES[chapter][1])
func is_near(a:Vector2,b:Vector2,dist:=40.0):
	return absf(a.x-b.x)<dist and absf(a.y-b.y)<26
func live_count():
	var total=0
	for e in enemies:
		if e.alive(): total+=1
	return total
func can_attack(actor):
	var n=0
	for e in enemies:
		if e!=actor and e.state in ["warn","jab","heavy","skill"]: n+=1
	return n<(1 if chapter<=2 or game.prefs.difficulty==0 else 2)
func windup(_actor): pass
func dodge_start():
	sound.fx("dodge",0.75)
	burst(hero.pos+Vector2(0,-4),"mist",7,Color("68c9ce"))
func tip_once(s):
	if tip_timer>0.2 and tip==s: return
	tip=s
	tip_timer=2.3
func tell(s):
	wave_banner=s
	wave_timer=2.8
func burst(p:Vector2,style:String,n:int,color:Color):
	for i in n:
		var ang=rng.randf_range(-PI,PI)
		var vel=Vector2.from_angle(ang)*rng.randf_range(27,135)
		if style=="mist": vel.y=-absf(vel.y)*0.5
		sparks.append({"p":p,"v":vel,"t":rng.randf_range(0.12,0.37),"kind":style,"c":color})
func pop(p:Vector2,s:String,c:Color):
	texts.append({"p":p,"s":s,"c":c,"t":0.72})
func effect(p:Vector2,k:String,face:int):
	sparks.append({"p":p,"v":Vector2(face,0),"t":0.30 if k=="ring" else 0.18,"kind":k,"c":Color.WHITE})
func bank_hit(amount:int):
	game.run_score+=amount*(1+mini(4,combo/8))
	combo+=1
	best_combo=maxi(best_combo,combo)
	combo_timer=1.8
func damage_enemy(e,dmg:int,knock:float,breaker:bool):
	if not e.alive(): return
	dmg=duels.filter_damage(e,dmg,breaker)
	if dmg<=0: return
	var blocked=e.kind=="guard" and e.guard_break<=0 and not breaker and e.face!=hero.face and e.state!="hurt"
	if blocked:
		e.hp=maxi(1,e.hp-2)
		e.push.x=hero.face*28
		sound.fx("guard",0.77)
		burst(e.pos+Vector2(-e.face*2,-34),"spark",5,Color("83d6e1"))
		pop(e.pos-Vector2(0,55),"破防用重击",Color("a4dfeb"))
		flux=minf(100,flux+3)
		return
	if breaker: e.guard_break=2.1
	e.hp=maxi(0,e.hp-dmg)
	e.recent_hit=0.16
	last_target=e
	last_target_time=2.5
	var dir=1 if e.pos.x>=hero.pos.x else -1
	e.push.x=dir*knock
	var armored=(e.kind=="boss" or (e.kind=="brute" and not breaker)) and e.state in ["heavy","skill","warn"] and not (breaker and e.kind!="boss")
	if e.hp<=0:
		e.pose("down",0.56)
		defeated+=1
		game.run_score+=95*(1+mini(4,combo/8))
		sound.fx("ko",0.72,1.0+rng.randf_range(-0.09,0.08))
		if defeated%5==0:
			goods.append({"p":e.pos,"id":"health","age":0.0})
	elif not armored:
		e.pose("hurt",0.27 if breaker else 0.21)
		e.cooldown=maxf(e.cooldown,0.28)
	bank_hit(12 if breaker else 8)
	flux=minf(100,flux+(0 if hero.state=="skill" else 8))
	burst(e.pos+Vector2(-dir*4,-34),"spark",10 if breaker else 7,Color("ffd57a"))
	effect(e.pos+Vector2(-dir*5,-33),"impact",dir)
	shake=maxf(shake,2.4 if breaker else 1.3)
	stop_time=maxf(stop_time,0.046 if breaker else 0.032)
	sound.fx("hit",0.8,1.00+rng.randf_range(-0.13,0.12))
func player_attack(h):
	if memory_mode: memoryrun.impact(h)
	else: field.strike(h)
	var skill=h.state=="skill"
	var heavy=h.state=="heavy"
	var fin=h.chain==3 and h.state=="jab"
	var dmg=34 if skill else (24 if heavy else (19 if fin else 13))
	if game.prefs.difficulty==0: dmg=roundi(dmg*1.16)
	var reach=105 if skill else (68 if heavy else (57 if fin else 51))
	var width=53 if skill else (25 if heavy else 21)
	if h.move_bonus=="chase" and h.state=="jab":
		dmg+=8
		reach+=15
		effect(h.pos+Vector2(-h.face*19,-23),"swish",h.face)
	elif h.move_bonus=="breaker" and heavy:
		dmg+=13
		reach+=13
		effect(h.pos+Vector2(h.face*35,-17),"sweep",h.face)
	effect(h.pos+Vector2(0,-31) if skill else h.pos+Vector2(h.face*(34 if not heavy else 44),-31),"ring" if skill else ("sweep" if heavy else "swish"),h.face)
	for e in enemies:
		if not e.alive(): continue
		var dx=(e.pos.x-h.pos.x)*h.face
		if (skill or dx>=-10) and absf(dx)<=reach and absf(e.pos.y-h.pos.y)<=width:
			damage_enemy(e,dmg,110 if skill or heavy or fin else 38,skill or heavy)
	if chapter==0 and lesson in [1,2,4]:
		var dx=(device.x-h.pos.x)*h.face
		if absf(dx)<=reach+7 and (skill or dx>=-9) and absf(device.y-h.pos.y)<=width+3:
			sound.fx("guard",0.7)
			burst(device-Vector2(0,36),"spark",11,Color("ffc86d"))
			shake=1.6
			if (lesson==1 and h.state=="jab") or (lesson==2 and heavy) or (lesson==4 and skill):
				lesson_hits+=1
				if lesson!=1 or lesson_hits>=3: next_lesson()
func enemy_attack(e):
	var d=hero.pos-e.pos
	var area=e.state=="skill"
	var rad=115 if e.kind=="boss" else 91
	effect(e.pos+Vector2(0,-25) if area else e.pos+Vector2(e.face*38,-28),"hostile" if area else "sweep",e.face)
	if ((area and absf(d.x)<rad and absf(d.y)<39) or (not area and d.x*e.face>=-12 and absf(d.x)<e.reach+11 and absf(d.y)<23)):
		take_hit(e.damage,e.face,e.kind)
func take_hit(dmg:int,dir:int,origin:String):
	if not hero.alive(): return
	if hero.invincible>0:
		if hero.state=="dodge" and not hero.perfect:
			hero.perfect=true
			if chapter>=11:
				hero.hp=mini(hero.max_hp,hero.hp+5)
				hero.cooldown=minf(hero.cooldown,0.12)
			flux=minf(100,flux+19)
			pop(hero.pos-Vector2(0,54),"精准闪避",Color("7befd7"))
			sound.fx("radio",0.54,1.22)
		return
	hero.hp=maxi(0,hero.hp-dmg)
	hits_taken+=1
	combo=0
	hero.hurt_by=origin
	hero.recent_hit=0.25
	hero.invincible=0.80
	hero.push.x=dir*97
	hero.pose("down" if hero.hp==0 else "hurt",0.62 if hero.hp==0 else 0.27)
	sound.fx("hurt",0.8)
	shake=3.0
	burst(hero.pos-Vector2(0,32),"spark",8,Color("ff997b"))
	stop_time=0.046
func boss_turn():
	tell("总监切换紧急频段 · 留意环形脉冲")
	sound.fx("alarm",0.65)
func spawn_actor(id:String,x:float,y:float,champ:=""):
	serial+=1
	var e=Fighter.new().init(id,Vector2(x,y),serial,game.prefs.difficulty,champ)
	enemies.append(e)
	return e
func roster(i:int):
	var groups=SignalBook.PACKS[chapter]
	var pattern:String=groups[(wave+section)%groups.size()]
	if chapter==1 and section<2: return "runner"
	return SignalBook.MAP[pattern[(wave+i)%pattern.length()]]
func reinforce(n:int):
	var point=hero.pos.x
	for i in n:
		var dir=1 if (wave+i)%3!=1 else -1
		var x=clampf(point+dir*(215+i*34),base+14,extent-26)
		if absf(x-point)<135: x=clampf(point-dir*(177+i*27),base+18,extent-20)
		spawn_actor(roster(i),x,rng.randf_range(259,324))
func tick(dt):
	if hero==null: return
	clock+=dt
	backdrop.queue_redraw()
	if stop_time>0:
		stop_time-=dt
		return
	timer+=dt
	phase_time+=dt
	chapter_time+=dt
	game.prefs.active_seconds+=dt
	shake=maxf(0,shake-9.5*dt)
	radio_left=maxf(0,radio_left-dt)
	tip_timer=maxf(0,tip_timer-dt)
	wave_timer=maxf(0,wave_timer-dt)
	phase_help=maxf(0,phase_help-dt)
	save_message=maxf(0,save_message-dt)
	last_target_time=maxf(0,last_target_time-dt)
	combo_timer=maxf(0,combo_timer-dt)
	if combo_timer<=0: combo=0
	handle_debris(dt)
	hero.hero_update(dt,self)
	if hero.state=="walk":
		foot_clock+=dt
		if foot_clock>0.36:
			foot_clock=0
			sound.fx("step",0.28,0.94+rng.randf()*0.14)
	tick_civilians(dt)
	if not memory_mode and chapter>0 and not done and section in [1,3,5] and phase_time>3.8 and radio_flags==0:
		radio_flags=1
		radio_text=SignalBook.CALLS[chapter][[1,3,5].find(section)]
		radio_left=5.5
		sound.fx("radio",0.44)
	hero.pos=hero.pos.clamp(Vector2(base+16,252),Vector2(extent-20,334))
	if not hero.alive():
		failed_timer+=dt
		if failed_timer>1.1: game.failure()
		return
	if memory_mode: memoryrun.tick(dt)
	elif chapter==0: tick_lesson(dt)
	elif not done: tick_objective(dt)
	if not done:
		duels.tick(dt)
		for e in enemies:
			if not duels.controls(e): e.enemy_update(dt,self)
			e.pos=e.pos.clamp(Vector2(base+9,251),Vector2(extent-12,335))
		separate_enemies(dt)
		tick_hazards(dt)
	for i in range(enemies.size()-1,-1,-1):
		var e=enemies[i]
		if done and e.state=="down": e.time+=dt
		if e.state=="down" and e.time>0.90: enemies.remove_at(i)
	if has_tape and is_near(hero.pos,tape_pos,30):
		has_tape=false
		game.prefs.records[str(chapter)]=true
		game.prefs.save()
		sound.fx("radio")
		tip_once("收录磁带《"+Book.PLACES[chapter][9]+"》")
	if done:
		done_timer+=dt
		if chapter==0 or section==5:
			if done_timer>=1.2: game.section_finished()
		else:
			if is_near(hero.pos,destination,50) or (hero.pos.x>=destination.x-18):
				game.section_finished()
	var desired=clampf(hero.pos.x-252,base,extent-640)
	cam=lerpf(cam,desired,1-exp(-dt*7.0))
func separate_enemies(dt):
	for i in enemies.size():
		var a=enemies[i]
		if not a.alive(): continue
		for j in range(i+1,enemies.size()):
			var b=enemies[j]
			if not b.alive(): continue
			var v=a.pos-b.pos
			if absf(v.x)<21 and absf(v.y)<13:
				var n=v.normalized() if v.length_squared()>0.1 else Vector2.UP
				a.pos+=n*dt*20
				b.pos-=n*dt*20
func handle_debris(dt):
	for i in range(sparks.size()-1,-1,-1):
		var s=sparks[i]
		s.t-=dt
		if s.kind in ["spark","mist"]:
			s.p+=s.v*dt
			s.v.y+=dt*182
		if s.t<=0: sparks.remove_at(i)
	for i in range(texts.size()-1,-1,-1):
		texts[i].t-=dt
		texts[i].p.y-=dt*17
		if texts[i].t<=0: texts.remove_at(i)
	for i in range(goods.size()-1,-1,-1):
		var g=goods[i]
		g.age+=dt
		if g.age>0.28 and hero.hp<hero.max_hp and is_near(hero.pos,g.p,32):
			hero.hp=mini(100,hero.hp+19)
			pop(hero.pos-Vector2(0,50),"体力 +19",Color("93eac5"))
			sound.fx("confirm",0.53)
			goods.remove_at(i)
func tick_hazards(dt):
	if not memory_mode and chapter>=5 and kind not in ["boss","tune"]:
		next_hazard-=dt
		if next_hazard<=0:
			next_hazard=rng.randf_range(9.0,15.0)
			var pos=hero.pos+Vector2(rng.randf_range(-14,14),0)
			hazards.append({"p":pos,"age":0.0,"hit":false})
	for i in range(hazards.size()-1,-1,-1):
		var h=hazards[i]
		h.age+=dt
		if h.age>=1.35 and not h.hit:
			h.hit=true
			burst(h.p-Vector2(0,14),"mist",12,Color("9fe1db"))
			if absf(hero.pos.x-h.p.x)<44 and absf(hero.pos.y-h.p.y)<13:
				take_hit(5 if game.prefs.difficulty==0 else 9,hero.face,"环境")
		if h.age>=1.75: hazards.remove_at(i)
func next_lesson():
	lesson+=1
	lesson_hits=0
	lesson_small=0
	lesson_pulse=0
	sound.fx("confirm",0.66)
	if lesson==4: flux=100
	if lesson==5: device=Vector2(615,283)
func tick_lesson(dt):
	if done: return
	match lesson:
		0:
			if is_near(hero.pos,lesson_coord,25): next_lesson()
		3:
			lesson_pulse=fmod(lesson_pulse+dt,2.6)
			if lesson_pulse>1.10 and lesson_pulse<1.55 and hero.state=="dodge":
				next_lesson()
		5:
			if is_near(hero.pos,device,40) and Input.is_action_just_pressed("use"):
				game.prefs.records["0"]=true
				finish()
func tutorial_text():
	var pad=game.pad
	var j="X" if pad else "J"
	var k="Y" if pad else "K"
	var l="RB" if pad else "L"
	var d="B" if pad else "空格"
	var use="A" if pad else "E"
	return [
		("左摇杆" if pad else "WASD / 方向键")+" 移动，沿纵深走到青色标记。",
		"靠近沙袋，面朝它按 "+j+" 连打三拳（%d/3）。"%lesson_hits,
		"按 "+k+" 重踢沙袋。重击可击破盾卫的正面防御。",
		"观察地面扫描线，在琥珀色窗口按 "+d+" 闪避。",
		"靠近沙袋按 "+l+" 释放脉冲。每次消耗 40 频能。",
		"走到右侧收发机，按 "+use+" 发出今晚的第一次呼号。"
	][clampi(lesson,0,5)]
func finish():
	if done: return
	done=true
	done_timer=0
	hero.hp=mini(100,hero.hp+(14 if chapter<=2 else 9))
	game.run_score+=200
	for e in enemies:
		if e.alive():
			e.hp=0
			e.pose("down",0.48)
	hazards.clear()
	sound.fx("clear",0.80)
	tell("频段已接通")
	if chapter>0 and section<5:
		destination=Vector2(clampf(hero.pos.x+226,base+610,extent-50),hero.pos.y)
func target_point():
	if memory_mode: return memoryrun.node
	if done: return destination
	if kind in ["relay","escort"]: return field.current
	if kind=="lesson": return lesson_coord if lesson==0 else device
	if kind in ["rescue","tune"] and spot_idx<spots.size(): return spots[spot_idx]
	if kind=="haul" and cargo_count<spots.size(): return device if carry else spots[cargo_count]
	if kind=="relay" and spot_idx<spots.size(): return spots[spot_idx]
	return device
func tick_objective(dt):
	if phase_time<0.50: return
	tune_lock=maxf(0,tune_lock-dt)
	var living=live_count()
	match kind:
		"fight","elite","boss":
			if living==0:
				spawn_time-=dt
				if wave>=waves:
					finish()
					return
				if spawn_time<=0:
					wave+=1
					spawn_time=0.85
					if kind=="boss":
						spawn_actor("boss",clampf(hero.pos.x+218,base+120,extent-150),288,Book.DUELS[chapter])
						tell(Book.DUELS[chapter])
					elif kind=="elite" and wave==waves:
						var id=["guard","skater","brute","tech"][chapter%4]
						spawn_actor(id,clampf(hero.pos.x+210,base+80,extent-80),287,Book.DUELS.get(chapter,"警备领班"))
						reinforce(1)
						tell(Book.DUELS.get(chapter,"警备领班"))
					else:
						reinforce(2 if chapter<4 or wave==1 else 3)
		"escort","relay": field.tick(dt)
		"rescue","tune","haul":
			var target=target_point()
			near_device=is_near(hero.pos,target,40)
			jammed=false
			for e in enemies:
				if e.alive() and is_near(e.pos,target,49): jammed=true
			if wave==0 or (living==0 and spawn_time<=0 and wave<4):
				wave+=1
				reinforce(1 if chapter<3 else 2)
				spawn_time=20.8
			spawn_time-=dt
			tune_phase=fmod(tune_phase+dt*(0.61 if game.prefs.difficulty==0 else 0.74),2.0)
			if kind=="tune":
				if near_device and not jammed and Input.is_action_just_pressed("use") and tune_lock<=0:
					var val=tune_phase if tune_phase<=1 else 2-tune_phase
					var w=0.21 if game.prefs.difficulty==0 else 0.15
					if absf(val-tune_centers[spot_idx])<w:
						complete_spot()
					else:
						tune_lock=0.28
						sound.fx("guard",0.42)
						tip_once("听准频点 · 光标进入亮区时按下接入")
			elif near_device and not jammed and Input.is_action_pressed("use") and hero.can_move():
				work+=dt
				if work>=(0.78 if kind=="haul" else 1.35):
					work=0
					sound.fx("confirm",0.75)
					if kind=="rescue": complete_spot()
					elif carry:
						carry=false
						cargo_count+=1
						if cargo_count>=3: finish()
					else: carry=true
			else: work=maxf(0,work-dt)
func complete_spot():
	if kind=="rescue": add_local(spots[spot_idx],false)
	sound.fx("radio",0.76)
	burst(spots[spot_idx]-Vector2(0,26),"spark",9,Color("86dec7"))
	spot_idx+=1
	work=0
	if spot_idx>=spots.size(): finish()
	elif live_count()<3:
		wave+=1
		reinforce(1 if chapter<4 else 2)
func briefing():
	if memory_mode: return memoryrun.goal_text()
	if duels.hint()!="": return duels.hint()
	if chapter==0: return tutorial_text()
	if kind in ["relay","escort"]: return field.report()
	var item=Book.LOCAL[chapter]
	var use="A" if game.pad else "E"
	match kind:
		"fight": return "击退沿线封锁队"
		"elite": return "击退警备队与"+Book.DUELS.get(chapter,"警备领班")
		"boss": return "夺回总控台 · 红环出现时拉开距离"
		"relay":
			if spot_idx<spots.size(): return "前往旁路接点，按 "+use+" 复位"
			return ("赶到" if not near_device else ("击退靠近设备的敌人 · " if jammed else "守住"))+item[0]
		"escort": return ("靠近" if not near_device else ("清除拦路者 · " if jammed else "护送"))+item[1]
		"rescue": return ("清开门口的敌人 · " if jammed else "靠近并按住 "+use+" 开启")+item[2]
		"tune": return ("排除频点附近的干扰 · " if jammed else "亮区按 "+use+" 校准")+item[0]
		"haul": return ("清除物资旁的敌人" if jammed else ("送往接收台，按住 "+use+" 卸载" if carry else "按住 "+use+" 搬起"+item[3]))
	return ""

func add_local(where:Vector2,travelling:bool):
	var citizen=Fighter.new()
	citizen.kind=["elder","worker","child"][(chapter+spot_idx)%3]
	citizen.pos=where
	citizen.index=chapter+spot_idx
	citizen.face=1
	citizen.role="cart" if travelling else "exit"
	citizen.pose("idle",1)
	civilians.append(citizen)
func tick_civilians(dt):
	for i in range(civilians.size()-1,-1,-1):
		var c=civilians[i]
		c.time+=dt
		var target=Vector2(extent+70,c.pos.y)
		var pace=62.0
		if c.role=="passenger":
			target=hero.pos+Vector2(-hero.face*16,4)
			pace=118.0
		if c.role=="cart":
			target=device+Vector2(-25-9*(i%3),-3+(i%3)*6)
			pace=49.0
		var delta=target-c.pos
		if delta.length_squared()>3:
			c.pos=c.pos.move_toward(target,pace*dt)
			c.face=1 if delta.x>=0 else -1
			if c.state!="walk": c.pose("walk",1)
		elif c.state!="idle": c.pose("idle",1)
		if c.role=="exit" and c.pos.x>cam+720: civilians.remove_at(i)
