extends RefCounted
## Named enemies operate on the same belt plane and hit pipeline as lane fighters.
## Stored points and hazard bounds are world coordinates. Drawing uses world.screen().
const RED = Color("#ff906f")
const GOLD = Color("#ffd07a")
const MINT = Color("#85e6c6")
const WHITE = Color("#fff0ce")
const DARK = Color("#152630")
const COLD = Color("#8acfe6")
const BLUE = Color("#426778")
const VIOLET = Color("#d5a1cc")
const ELITE_STYLES = {2:"shears",4:"rail",6:"frost",8:"seal",9:"bell",11:"beam",12:"rail",13:"seal",14:"bell"}
const STYLE_TITLE = {"shears":"剪口","rail":"换轨","frost":"排霜","seal":"冲印","bell":"落锤","beam":"偏波"}
const HP = {"shears":325,"rail":360,"frost":350,"seal":355,"bell":410,"beam":360}
var arena
var lead
var style := ""
var act := 0
var move := ""
var phase := ""
var phase_left := 0.0
var phase_total := 1.0
var serial := 0
var job := 0
var stations := []
var keys_done := false
var charging := 0.0
var lanes := []
var strike := Vector2.ZERO
var origin := Vector2.ZERO
var mark := Vector2.ZERO
var has_fired := false
var was_counter := false
var block_cue := 0.0
var custodians := []
var challenged := {}
var routed := false
var relay_return := false
var second_wind := false
var interlock := false
var last_third_floor := 0
var broken_plates := 0
var guard_meter := 0
var last_hint := ""
var duct_target := Vector2.ZERO

func reset(a):
	arena=a
	lead=null
	style=""
	act=0
	phase=""
	job=0
	stations.clear()
	lanes.clear()
	custodians.clear()
	challenged.clear()
	interlock=false
	second_wind=false
	routed=false
	relay_return=false
	last_hint=""
	block_cue=0.0

func controls(e) -> bool:
	return lead!=null and e==lead and e.alive() and not arena.done

func is_final() -> bool:
	return style=="director"

func _start(e):
	lead=e
	style="director" if e.kind=="boss" else ELITE_STYLES.get(arena.chapter,"shears")
	lead.max_hp=roundi((1580 if is_final() else HP[style]*1.57)*[0.78,1.0,1.19][arena.game.prefs.difficulty])
	lead.hp=lead.max_hp
	lead.special_phase=true
	lead.guard_break=100.0
	act=0
	mark=Vector2(clampf(e.pos.x+96,arena.base+160,arena.extent-150),311 if arena.chapter%2==0 else 267)
	if is_final():
		_set_act(1)
	else:
		serial=0
		job=0
		keys_done=true
		guard_meter=0
		stations=[]
		if style in ["frost","rail","beam"]:
			stations=[mark]
		_phase("hunt",1.25)
		arena.tell(e.role+"  /  "+STYLE_TITLE[style])
		_set_hint()

func _set_act(n:int):
	act=n
	serial=0
	job=0
	guard_meter=0
	charging=0.0
	keys_done=n==3
	var x=arena.base
	if n==1:
		stations=[Vector2(x+362,266),Vector2(x+962,322)]
	elif n==2:
		stations=[Vector2(x+1038,264),Vector2(x+274,323),Vector2(x+819,261),Vector2(x+439,320)]
	else: stations=[]
	# A cutover releases stored energy and leaves a real, optional field dressing.
	if n==3:
		broken_plates=0
		last_third_floor=roundi(lead.max_hp*.255)
	if n>1:
		arena.goods.append({"p":arena.hero.pos+Vector2(14,2),"id":"health","age":0.0})
		arena.flux=minf(100.0,arena.flux+18)
		arena.burst(lead.pos-Vector2(0,26),"spark",15,GOLD)
	lead.pose("idle",1.0)
	_phase("hunt",1.4)
	arena.tell(["","第一幕  /  切断双路干扰","第二幕  /  反接调制器","第三幕  /  抢下播出权"][n])
	arena.sound.fx("alarm",0.55,0.80+0.09*n)
	_set_hint()

func _phase(name:String,duration:float):
	phase=name
	phase_left=duration
	phase_total=maxf(duration,0.01)
	has_fired=false

func _pose(name:String,duration:=1.0):
	lead.pose(name,duration)

func _set_hint():
	var key="A" if arena.game.pad else "E"
	var heavy="Y" if arena.game.pad else "K"
	if is_final():
		if act==1 and not keys_done:
			last_hint="一幕 · 到标记干扰柱按住 "+key+" 断锁  %d/2"%job
		elif act==2 and not keys_done:
			last_hint=["二幕 · 在东缆提取绝缘芯","二幕 · 把绝缘芯送到西调制槽","二幕 · 到北缆反接回波线","二幕 · 南端合闸，切断回充"][job]+"  · "+key
		elif act==3 and phase=="vent":
			last_hint="总监正在回充 · 抢到身边按 "+heavy+" 击断胸甲"
		elif act==3 and phase!="open":
			last_hint="三幕 · 闪过实线攻击，或在金色回充时用重击破甲"
		elif phase=="open":
			last_hint="护甲解除 · 靠近总监，用连段追击"
		else:
			last_hint="回路已切断 · 绕开红线，在攻势间隙反击"
		return
	var tips={"shears":"双剪横扫 · 绕到背后，或错开两道剪线再进攻","rail":"换轨冲锋 · 按住 "+key+" 扳道岔，可将领班逼停","frost":"制冷阀已开 · 按住 "+key+" 排霜，或重击打碎护层","seal":"把落印引到黄黑标靶，或趁压印收招用重击","bell":"锤波向外扩散 · 闪过波峰，从内圈抢攻","beam":"偏波扫线 · 按住 "+key+" 反射天线，或绕到背面截击"}
	last_hint="破绽 · 追击"+lead.role if phase=="open" else tips[style]

func priority_enemy():
	if lead==null or not lead.alive() or arena.done: return null
	var choice=null
	var distance=INF
	for e in custodians:
		if e.alive() and e.pos.distance_squared_to(arena.hero.pos)<distance:
			distance=e.pos.distance_squared_to(arena.hero.pos)
			choice=e
	return choice

func _crew(ids:Array,at:Vector2):
	custodians.clear()
	for i in ids.size():
		var place=at+Vector2((-1 if i==0 else 1)*(54+15*i),20 if i%2==0 else -19)
		var e=arena.spawn_actor(ids[i],clampf(place.x,arena.base+55,arena.extent-55),clampf(place.y,257,328))
		# The key carriers carry distinct amber lamp badges above their foot shadows.
		e.palette=Color("#ffe7bb")
		custodians.append(e)
	arena.sound.fx("radio",.55,.88)

func _watch_crew():
	if not custodians.is_empty() and priority_enemy()==null:
		custodians.clear()
		if routed or (is_final() and act==2 and keys_done):
			_open(4.5)
		arena.pop(arena.hero.pos-Vector2(0,55),"增援中断" if routed or (is_final() and keys_done) else "锁扣钥匙",GOLD)
		arena.flux=minf(100,arena.flux+9)
		arena.sound.fx("confirm",.65)
	if not custodians.is_empty(): return
	var index="%d.%d"%[act,job]
	if is_final() and not keys_done and not challenged.has(index):
		var anchor:Vector2=stations[job]
		var squad:Array=[]
		if act==1: squad=["guard","runner"] if job==0 else ["brute","tech","skater"]
		elif job==0: squad=["skater","tech"]
		elif job==2: squad=["guard","brute","runner"]
		if not squad.is_empty() and absf(arena.hero.pos.x-anchor.x)<195:
			challenged[index]=true
			var retreat=390 if anchor.x<arena.base+610 else -400
			_crew(squad,anchor+Vector2(retreat,0))
	if not is_final() and not second_wind and lead.hp<=roundi(lead.max_hp*.54):
		second_wind=true
		interlock=true
		charging=0
		var side=-1 if arena.hero.pos.x>arena.base+605 else 1
		var offset={"shears":385,"rail":432,"frost":365,"seal":402,"bell":380,"beam":412}[style]
		var station=Vector2(clampf(lead.pos.x+side*offset,arena.base+70,arena.extent-75),261 if lead.pos.y>294 else 322)
		stations=[station]
		var ids={"shears":["runner","skater"],"rail":["guard","runner"],"frost":["tech","guard"],"seal":["runner","tech"],"bell":["brute","runner"],"beam":["skater","guard"]}[style]
		_crew(ids,station)
		arena.goods.append({"p":lead.pos+Vector2(13,-8),"id":"health","age":0.0})
		arena.tell(lead.role+" · 备用回路上线")
		_phase("hunt",0.75)
		_pose("idle",1.0)
		_set_hint()

func _breakaway():
	# The last exchange shifts to the far bank instead of repeating a long health bar.
	var side=-1 if lead.pos.x>arena.base+610 else 1
	duct_target=Vector2(clampf(lead.pos.x+side*480,arena.base+62,arena.extent-65),263 if lead.pos.y>294 else 324)
	var pack={"shears":["skater","runner"],"rail":["guard","skater"],"frost":["brute","tech"],"seal":["guard","runner"],"bell":["brute","skater"],"beam":["guard","tech"]}
	_crew(pack[style] if not is_final() else ["tech","skater","guard"],duct_target)
	_phase("retreat",3.2)
	_pose("walk",1.0)
	arena.tell("总监调用备用调制班" if is_final() else lead.role+" · 转移阵地")
	if not is_final():
		stations=[]
		mark=duct_target+Vector2(-side*58,0)
	_set_hint()

func hint() -> String:
	if priority_enemy()!=null:
		return "截住金灯增援 · 切断增援后反攻" if (routed or (relay_return and is_final() and keys_done)) else "金灯持钥者 · 先击退佩戴钥匙灯的守卫，再操作装置"
	if interlock and lead!=null and lead.alive() and not arena.done: return "拆除备用回路 · 走到金灯配电柱按住 "+("A" if arena.game.pad else "E")
	return last_hint if lead!=null and lead.alive() and not arena.done else ""

func guidance() -> Vector2:
	if lead==null or not lead.alive() or arena.done: return Vector2.INF
	if priority_enemy()!=null: return Vector2.INF
	if is_final() and not keys_done: return stations[job]
	if interlock: return stations[0]
	if not is_final() and style in ["frost","rail","beam"] and phase!="open" and not stations.is_empty():
		return stations[0]
	return Vector2.INF

func _near(p:Vector2,r:=32.0) -> bool:
	return absf(arena.hero.pos.x-p.x)<=r and absf(arena.hero.pos.y-p.y)<=23.0

func _station_tick(dt:float):
	if priority_enemy()!=null: return
	if is_final() and keys_done: return
	if not is_final() and ((phase=="open" and not interlock) or stations.is_empty()): return
	var p:Vector2=stations[job] if is_final() else stations[0]
	if _near(p) and Input.is_action_pressed("use") and arena.hero.can_move():
		charging+=dt
		if charging>=(0.82 if arena.game.prefs.difficulty==0 else 1.05):
			charging=0.0
			arena.sound.fx("radio",0.73,1.12)
			arena.burst(p-Vector2(0,18),"spark",11,MINT)
			if is_final():
				job+=1
				if job>=stations.size():
					keys_done=true
					_open(5.1)
				else:
					arena.pop(p-Vector2(0,36),"已转接",MINT)
					if act==2 and job==1: arena.tell("绝缘芯在手 · 前往西调制槽")
					_set_hint()
			else:
				interlock=false
				_open(5.3)
				mark=Vector2(clampf(lead.pos.x+(174 if p.x<lead.pos.x else -174),arena.base+90,arena.extent-95),264 if p.y>290 else 320)
				if style in ["rail","beam","frost"]: stations[0]=mark
				else: stations=[]
	else:
		charging=maxf(0.0,charging-dt*0.65)

func _open(duration:float):
	lanes.clear()
	guard_meter=0
	charging=0.0
	lead.guard_break=duration+1.0
	lead.push=Vector2.ZERO
	_pose("hurt",0.28)
	_phase("open",duration+(.9 if arena.game.prefs.difficulty==0 else 0.0))
	arena.burst(lead.pos-Vector2(0,32),"spark",10,MINT)
	arena.pop(lead.pos-Vector2(0,65),"破绽",MINT)
	arena.sound.fx("guard",0.72,0.78)
	_set_hint()

func _blocked(text:String):
	if block_cue<=0.0:
		arena.pop(lead.pos-Vector2(0,58),text,GOLD)
		arena.sound.fx("guard",0.6,0.9)
		arena.burst(lead.pos-Vector2(0,32),"spark",5,GOLD)
		block_cue=1.5

func filter_damage(e,dmg:int,breaker:bool) -> int:
	if not controls(e): return dmg
	if interlock or priority_enemy()!=null:
		_blocked("拆除备用回路" if interlock else "先取锁扣钥匙")
		return 0
	if is_final() and not keys_done:
		_blocked("断开干扰柱" if act==1 else "反接调制器")
		return 0
	var back=(arena.hero.pos.x-e.pos.x)*e.face < -5
	if phase=="vent" and breaker:
		_open(4.0 if is_final() else 4.8)
	elif not is_final() and back and style in ["shears","beam"] and phase!="open":
		_open(3.6)
	elif not is_final() and style=="frost" and breaker and phase!="open":
		guard_meter+=1
		if guard_meter>=3: _open(4.2)
	if phase!="open" and not (is_final() and act<=2 and phase=="vent"):
		if is_final():
			_blocked("等回充 · 用重击" if phase=="vent" else "护甲闭合")
			return 0
		# A heavy jab can chip any elite. Movement and counterplay break it much faster.
		if breaker: guard_meter+=1
		if guard_meter>=5:
			_open(3.6)
		else:
			_blocked("破甲 %d/5"%guard_meter if breaker else "护甲闭合")
			return mini(dmg,3 if breaker else 1)
	var actual=dmg
	if is_final():
		var floor_hp=roundi(lead.max_hp*(0.67 if act==1 else (0.34 if act==2 else 0.0)))
		if act==3: floor_hp=last_third_floor
		if act==2 and not relay_return: floor_hp=roundi(lead.max_hp*.51)
		actual=mini(actual,maxi(0,lead.hp-floor_hp))
	elif not second_wind:
		actual=mini(actual,maxi(0,lead.hp-roundi(lead.max_hp*.54)))
	elif not routed:
		actual=mini(actual,maxi(0,lead.hp-roundi(lead.max_hp*.22)))
	return actual

func tick(dt:float):
	if arena==null or arena.kind not in ["elite","boss"] or arena.done or not arena.hero.alive(): return
	if lead==null:
		for e in arena.enemies:
			if e.alive() and e.role!="":
				_start(e)
				break
	if lead==null or not lead.alive(): return
	block_cue=maxf(0,block_cue-dt)
	lead.timers(dt)
	lead.guard_break=20.0
	if is_final() and keys_done:
		if act==1 and lead.hp<=roundi(lead.max_hp*.67): _set_act(2)
		elif act==2 and lead.hp<=roundi(lead.max_hp*.34): _set_act(3)
		elif act==3 and last_third_floor>0 and lead.hp<=last_third_floor:
			broken_plates+=1
			last_third_floor=roundi(lead.max_hp*[0.255,0.17,0.085,0.0][broken_plates])
			# A broken ceramic plate stays broken. He retreats to the next live stand.
			var side=-1 if lead.pos.x>arena.base+625 else 1
			duct_target=Vector2(clampf(lead.pos.x+side*325,arena.base+68,arena.extent-70),264 if lead.pos.y>292 else 321)
			_phase("retreat",2.4)
			_pose("walk",1.0)
			arena.pop(lead.pos-Vector2(0,58),"胸甲脱落",MINT)
			arena.tell("总监转移到备用话筒 · 从另一侧截击")
	if is_final() and act==2 and not relay_return and keys_done and lead.hp<=roundi(lead.max_hp*.51):
		relay_return=true
		_breakaway()
	elif not is_final() and second_wind and not routed and lead.hp<=roundi(lead.max_hp*.22):
		routed=true
		_breakaway()
	_watch_crew()
	_station_tick(dt)
	phase_left-=dt
	match phase:
		"retreat":
			lead.face=1 if duct_target.x>=lead.pos.x else -1
			lead.pos=lead.pos.move_toward(duct_target,dt*167)
			if lead.pos.distance_squared_to(duct_target)<3 or phase_left<=0:
				_phase("hunt",0.65)
		"hunt":
			_hunt(dt)
			if phase_left<=0:
				_prepare()
		"wind":
			if phase_left<=0: _fire()
		"strike":
			_active(dt)
			if phase_left<=0:
				lanes.clear()
				if was_counter:
					_open(4.6)
				else:
					var d=2.7 if is_final() and act==3 else 1.65
					if not is_final() and style in ["bell","shears"]: d=2.2
					_phase("vent",d)
					_pose("idle",1.0)
					_set_hint()
		"vent":
			if phase_left<=0:
				if (not is_final() and style in ["bell","shears"]) or (is_final() and act<3 and keys_done):
					_open(3.0)
				else:
					_phase("hunt",0.8)
					_set_hint()
		"open":
			if lead.state=="hurt" and lead.time>=lead.length: _pose("idle",1.0)
			if phase_left<=0:
				_phase("hunt",0.9)
				_set_hint()

func _hunt(dt):
	var h:Vector2=arena.hero.pos
	var delta:Vector2=h-lead.pos
	lead.face=1 if delta.x>=0 else -1
	var slot=h-Vector2(lead.face*(40 if style!="rail" else 95),0)
	var dir:Vector2=slot-lead.pos
	if dir.length()>4:
		lead.pos=lead.pos.move_toward(slot,dt*(136 if absf(delta.x)>148 else 78))
		if lead.state!="walk": _pose("walk",1.0)
	elif lead.state!="idle": _pose("idle",1.0)
	# Keep contact combat local, while tower emitters and sirens work across the belt.
	if (not is_final() or keys_done) and absf(delta.x)>130 and phase_left<0.25:
		phase_left=0.25

func _prepare():
	serial+=1
	was_counter=false
	origin=lead.pos
	strike=arena.hero.pos
	lead.face=1 if strike.x>=origin.x else -1
	move=style
	if second_wind and not is_final() and serial%2==0:
		move={"shears":"seal","rail":"shears","frost":"beam","seal":"bell","bell":"rail","beam":"frost"}[style]
	if is_final():
		var sequences={1:["beam","rail","seal"],2:["shears","frost","beam","seal"],3:["rail","bell","shears","beam"]}
		var sequence=sequences[act]
		move=sequence[(serial-1)%sequence.size()]
	var wind=1.25 if arena.game.prefs.difficulty==0 else (0.97 if arena.game.prefs.difficulty==1 else 0.78)
	if priority_enemy()!=null: wind+=0.62
	if move in ["seal","frost","shears"]: wind+=0.24
	if move=="bell": wind+=0.15
	lanes.clear()
	match move:
		"rail":
			# Stay in the belt of the engine, within its announced end stop.
			var end_x=clampf(origin.x+lead.face*270,arena.base+26,arena.extent-26)
			_line(origin-Vector2(lead.face*9,0),Vector2(end_x,origin.y),13.0)
		"beam":
			var skew=0.18 if strike.y<294 else -0.18
			_line(strike-Vector2(235,235*skew),strike+Vector2(235,235*skew),9.0)
		"shears":
			_line(strike-Vector2(143,42),strike+Vector2(143,42),8.0)
			_line(strike-Vector2(143,-42),strike+Vector2(143,-42),8.0)
		"frost":
			var side=1 if strike.y<294 else -1
			_line(strike-Vector2(143,0),strike+Vector2(143,0),10.0)
			_line(strike+Vector2(-143,side*46),strike+Vector2(143,side*46),8.0)
		"seal":
			# Three pressure plates are strobed together on a single downbeat.
			for dx in [-92,0,92]:
				var c=strike+Vector2(dx,0 if dx==0 else (12 if serial%2==0 else -12))
				lanes.append({"a":c,"b":c,"r":15.0,"disk":true})
		"bell":
			strike=origin
	lead.attack_type="heavy" if move in ["rail","bell","seal"] else "skill"
	_pose("warn",wind)
	_phase("wind",wind)
	arena.sound.fx("alarm",0.42,0.93 if move=="rail" else 1.12)

func _line(a:Vector2,b:Vector2,r:float):
	lanes.append({"a":a,"b":b,"r":r,"disk":false})

func _fire():
	var t=1.15 if move=="bell" else (0.72 if move=="rail" else 0.42)
	_pose(lead.attack_type,t)
	_phase("strike",t)
	arena.sound.fx("heavy" if move in ["bell","rail","seal"] else "skill",0.53,0.82)
	if move=="seal" and style=="seal" and _seal_on_mark():
		was_counter=true
		arena.burst(mark-Vector2(0,3),"spark",10,GOLD)

func _seal_on_mark() -> bool:
	for line in lanes:
		if _flat_dist(line.a,mark)<26: return true
	return false

func _flat_dist(a:Vector2,b:Vector2) -> float:
	return Vector2(a.x-b.x,(a.y-b.y)*1.65).length()

func _within_line(p:Vector2,s) -> bool:
	if s.disk: return _flat_dist(p,s.a)<=s.r*2.0
	var axis:Vector2=s.b-s.a
	var unit=axis.normalized()
	var offset:Vector2=p-s.a
	var along=offset.dot(unit)
	return along>=0.0 and along<=axis.length() and absf(offset.cross(unit))<=s.r

func _active(dt:float):
	var frac=clampf(1.0-phase_left/phase_total,0,1)
	var target:Vector2=arena.hero.pos
	var touching=false
	if move=="rail":
		var lane=lanes[0]
		lead.pos=origin.lerp(lane.b,minf(1.0,frac*1.25))
		touching=absf(lead.pos.x-target.x)<29 and _within_line(target,lane)
	elif move=="bell":
		var radius=24.0+frac*201.0
		touching=absf(_flat_dist(target,origin)-radius)<=10.0
	else:
		for lane in lanes:
			if _within_line(target,lane): touching=true
	if is_final() and act==2 and job==2 and move=="seal":
		lead.pos=lead.pos.move_toward(strike,dt*83.0)
	if touching and not has_fired:
		has_fired=true
		var dodge=arena.hero.state=="dodge" and arena.hero.invincible>0
		var damage=([5,8,12] if is_final() else [4,7,10])[arena.game.prefs.difficulty]
		arena.take_hit(damage,lead.face,"总控阵列" if is_final() else lead.role)
		if dodge:
			was_counter=true
			arena.burst(arena.hero.pos-Vector2(0,22),"mist",7,MINT)

func draw_ground(w):
	if lead==null or not lead.alive() or arena.done: return
	for e in custodians:
		if not e.alive(): continue
		var fp:Vector2=w.screen(e.pos)-Vector2(0,83)
		if fp.x<1 or fp.x>639: continue
		w.ellipse(fp,6,6,DARK)
		w.ellipse(fp,4,4,GOLD,false)
		w.box(fp.x-1,fp.y-2,2,6,GOLD)
		w.box(fp.x+1,fp.y+1,2,2,GOLD)
	if is_final() and not keys_done:
		for i in stations.size():
			if i>job+1 or i<job-1: continue
			var point:Vector2=stations[i]
			var p:Vector2=w.screen(point)
			if p.x < -55 or p.x>695: continue
			var live=i==job
			_station_art(w,p,live,i<job,i)
		if act==2 and job==1:
			var p:Vector2=w.screen(arena.hero.pos)
			w.box(p.x-11,p.y-29,10,12,DARK)
			w.box(p.x-10,p.y-27,8,8,BLUE)
			w.box(p.x-8,p.y-27,3,8,MINT)
	elif not is_final():
		if style=="seal" and not interlock:
			var p:Vector2=w.screen(mark)
			w.ellipse(p,30,11,Color(GOLD,0.14))
			w.ellipse(p,30,11,GOLD,false)
			w.ellipse(p,18,6,Color(GOLD,0.7),false)
			w.line([p-Vector2(9,0),p+Vector2(9,0)],GOLD)
			w.line([p-Vector2(0,3),p+Vector2(0,3)],GOLD)
		if not stations.is_empty():
			var p:Vector2=w.screen(stations[0])
			if p.x>=-40 and p.x<=680: _station_art(w,p,phase!="open" or interlock,false,0)
	var pos:Vector2=w.screen(lead.pos)
	if is_final() and act==3:
		for i in 3:
			var chip=pos+Vector2(-10+i*7,-72)
			w.box(chip.x,chip.y,6,4,DARK)
			w.box(chip.x+1,chip.y+1,4,2,MINT if i<broken_plates else GOLD)
	if phase=="wind" or phase=="strike":
		var active=phase=="strike"
		var elapsed=clampf(1.0-phase_left/phase_total,0.0,1.0)
		var tone=GOLD if move=="bell" else (COLD if move=="frost" else RED)
		if move=="bell":
			var radius=24.0+elapsed*201.0 if active else 24.0
			var p:Vector2=w.screen(origin)
			w.ellipse(p,225,136,Color(tone,.30),false)
			w.ellipse(p,radius,radius/1.65,tone,false)
			w.ellipse(p,radius+4,(radius+4)/1.65,Color(tone,0.66),false)
			if not active:
				for i in 8:
					var v=Vector2.from_angle(PI*i/4.0)
					var at=p+Vector2(v.x*43,v.y*26)
					w.line([at,at+Vector2(v.x*7,v.y*5)],tone,2)
		else:
			for lane in lanes:
				_band(w,lane,tone,active,elapsed)
		if pos.x>0 and pos.x<640:
			w.caption(pos-Vector2(0,84),{"rail":"直轨突进","frost":"双排冷流","seal":"三点落印","shears":"交错剪线","bell":"扩散锤波","beam":"斜向扫频"}[move],tone,true)
	elif phase=="open" or phase=="vent":
		var tone=MINT if phase=="open" else GOLD
		w.ellipse(pos,23,7,Color(tone,0.6),false)
		if pos.x>0 and pos.x<640:
			var title="抢攻" if phase=="open" else "回充 · 重击"
			w.caption(pos-Vector2(0,83),title,tone,true)
			w.box(pos.x-13,pos.y-79,26,2,DARK)
			w.box(pos.x-13,pos.y-79,26*maxf(0,phase_left)/phase_total,2,tone)

func _station_art(w,p:Vector2,live:bool,closed:bool,i:int):
	var c=MINT if live else BLUE
	var shadow=Color("#13212b")
	w.ellipse(p+Vector2(2,1),18,5,Color(shadow,.66))
	if live:
		w.ellipse(p,23,8,Color(MINT,.4),false)
		if _near(stations[job] if is_final() else stations[0]):
			w.ellipse(p,18,6,Color(MINT,.6),false)
	var short=style in ["rail","frost"] or (is_final() and act==2)
	var height=23 if short else 37
	w.box(p.x-10,p.y-height,20,height,shadow)
	w.box(p.x-8,p.y-height+2,15,height-5,BLUE)
	w.box(p.x-7,p.y-height+3,4,height-8,Color("#7b9393"))
	w.box(p.x+3,p.y-height+3,3,height-7,Color("#293e48"))
	w.box(p.x-11,p.y-3,23,3,shadow)
	w.box(p.x-10,p.y-4,18,2,Color("#90a8a2"))
	if short:
		if style=="rail" or (is_final() and job>1):
			var anchor=p+Vector2(0,-height+6)
			var end=anchor+Vector2(7 if not closed else -6,-10)
			w.line([anchor,end],shadow,4)
			w.line([anchor,end],GOLD if live else BLUE,2)
			w.box(end.x-3,end.y-2,6,3,c)
		else:
			var center=p+Vector2(0,-height+2)
			w.ellipse(center,6,6,shadow)
			w.ellipse(center,5,5,c,false)
			w.line([center-Vector2(4,0),center+Vector2(4,0)],c)
			w.line([center-Vector2(0,4),center+Vector2(0,4)],c)
	else:
		w.box(p.x-1,p.y-height-11,2,11,shadow)
		w.box(p.x-7,p.y-height-7,14,2,c)
		w.box(p.x-4,p.y-height-10,8,1,c)
		w.box(p.x-6,p.y-height+5,12,7,shadow)
		w.box(p.x-4,p.y-height+7,7,2,c)
		w.box(p.x-5,p.y-height+17,9,1,shadow)
		w.box(p.x-5,p.y-height+20,9,1,shadow)
	if live:
		var label=""
		if is_final():
			label=("干扰柱 %d"%(i+1)) if act==1 else ["绝缘芯","西调制槽","北回波线","南侧合闸"][i]
		elif interlock: label="备用回路"
		else: label={"rail":"道岔","frost":"排霜阀","beam":"反射天线"}.get(style,"转接点")
		if p.x>14 and p.x<626:
			w.caption(p-Vector2(0,height+16),label,c,true)
			if charging>0:
				w.box(p.x-12,p.y-height-13,24,3,shadow)
				w.box(p.x-12,p.y-height-13,24*minf(1.0,charging/(0.82 if arena.game.prefs.difficulty==0 else 1.05)),3,c)

func _band(w,s,c:Color,active:bool,t:float):
	var a:Vector2=w.screen(s.a)
	var b:Vector2=w.screen(s.b)
	if maxf(a.x,b.x)<-65 or minf(a.x,b.x)>705: return
	if s.disk:
		w.ellipse(a,s.r*2,s.r*2/1.65,Color(c,0.31 if active else 0.13))
		w.ellipse(a,s.r*2,s.r*2/1.65,c,false)
		w.ellipse(a,maxf(2,s.r*1.8*t),maxf(1,s.r*t),Color(c,0.78),false)
		w.line([a-Vector2(5,0),a+Vector2(5,0)],WHITE)
		w.line([a-Vector2(0,3),a+Vector2(0,3)],WHITE)
		return
	var u=(b-a).normalized()
	var n=Vector2(-u.y,u.x)*s.r
	w.draw_colored_polygon(PackedVector2Array([a+n,b+n,b-n,a-n]),Color(c,0.27 if active else 0.11))
	w.line([a+n,b+n],c,2 if active else 1)
	w.line([a-n,b-n],c,2 if active else 1)
	w.line([a+n,a-n],c)
	w.line([b+n,b-n],c)
	if active:
		w.line([a,b],WHITE,2)
	else:
		# Static diagonal hatching identifies a live attack even with reduced effects.
		var d=11.0
		while d<a.distance_to(b)-5:
			var mid=a+u*d
			w.line([mid+n*.45-u*3,mid-n*.45+u*3],Color(c,.56))
			d+=18
