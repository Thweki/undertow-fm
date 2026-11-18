extends Node2D
signal finished
signal checkpoint_changed(data)
const Fighter=preload("res://game/fighter.gd")
const Book=preload("res://game/campaign.gd")
# Routes ascend through a different series of roofs, cable trays and floodgates.
const ROUTES={
	1:["沿街传声筒",["鱼筐天桥","雨棚横梁","铜铃支架","冰厂二楼","鱼灯楼顶"],[0,1,2,3,4]],
	3:["末班车顶",["闸机上盖","缓冲月台","检票天桥","电缆夹层","司机瞭望台","终点道岔"],[2,5,4,6,1,7]],
	4:["桥腹检修道",["索头平台","铆工踏板","双层桁架","桥下风箱","回车灯柱","桥北机架"],[3,6,0,7,5,2]],
	6:["冷库风井",["顶置机组","氨管通廊","融霜盘","风机环廊","红灯舱门","冷库外墙"],[4,0,7,2,6,3]],
	7:["船坞上层",["轮机顶桥","压舱水管","货舱桁车","吊索跨口","驾驶层","艏部雾钟"],[5,2,3,1,7,4]],
	9:["实测仪表廊",["低潮刻度","铅锤滑轨","测量尺台","校表栈桥","浮尺机架","实测记录室"],[6,4,1,5,2,7]],
	10:["泵房泄压线",["吸水井盖","阀座平台","减压室","泵轴跨道","电缆背架","排水塔"],[1,7,5,3,4,6]],
	12:["高压绝缘廊",["门极机架","双联电容","四路母线","电刷架","绝缘吊桥","合闸窗"],[7,3,6,2,5,0]],
	13:["回水巷屋脊",["晒台后窗","玻璃天井","鸽舍横梁","挂灯外廊","邻家屋檐","祖屋山墙"],[0,6,4,1,7,5]],
	15:["主塔天馈桥",["塔底主梁","馈线检修井","风压平台","旁路母线","发射机顶","公共天线"],[5,7,2,6,3,4]]
}
# Rectangles form one-way ledges. Columns contain [x,width,tread height].
const SHAPES=[
	[[54,140,244],[161,139,198],[269,145,154],[439,135,209]],
	[[72,136,249],[216,160,206],[385,144,158],[440,148,244]],
	[[40,141,242],[201,148,216],[307,135,171],[443,129,220]],
	[[85,147,238],[231,130,189],[384,140,148],[411,169,233]],
	[[35,128,253],[163,157,213],[279,144,166],[423,149,218]],
	[[62,148,245],[201,129,196],[336,135,150],[461,125,207]],
	[[72,130,248],[169,154,201],[287,154,151],[426,145,206]],
	[[46,151,244],[191,138,199],[315,158,151],[471,110,222]]
]
# Ordered stations form a maintenance circuit. Numbers refer to the ledges,
# with 4 and 5 designating safe ground on either side of the break.
const TASKS=[
	[[0,"fuse"],[2,"socket"],[3,"lever"]],
	[[3,"fuse"],[1,"drone"],[0,"socket"]],
	[[1,"lever"],[3,"lock"],[2,"socket"]],
	[[2,"drone"],[0,"fuse"],[3,"socket"]],
	[[3,"lever"],[1,"fuse"],[2,"lock"],[5,"socket"]],
	[[0,"fuse"],[2,"drone"],[3,"socket"],[1,"lever"]],
	[[2,"lock"],[3,"fuse"],[0,"socket"]],
	[[3,"drone"],[0,"lever"],[2,"fuse"],[5,"socket"]]
]
var game
var chapter=1
var room=0
var room_name=""
var room_count=0
var clock=0.0
var hero
var grounded=false
var vy=0.0
var shield=0.0
var jumps=0
var platforms=[]
var hazards=[]
var nodes=[]
var particles=[]
var exit_pos=Vector2(602,294)
var target=0
var hp=4
var hint=""
var elapsed=0.0
var view
var control_lock=0.0
var grace=0.0
var jump_buffer=0.0
var fall_origin=Vector2(23,294)
var energy=0.0
var feedback=""
var feedback_time=0.0
var room_pulse=0.0
var skip_ledge=-1
var drop_timer=0.0
var supported=-1
var completed=false
func setup(g,ch:int,data={}):
	game=g
	chapter=ch
	room=clampi(int(data.get("room",0)),0,ROUTES[ch][1].size()-1)
	hp=clampi(int(data.get("hp",4)),1,4)
	elapsed=float(data.get("elapsed",0.0))
	energy=float(data.get("energy",0.0))
	room_count=ROUTES[ch][1].size()
	completed=false
	if not view and DisplayServer.get_name()!="headless":
		view=load("res://game/catwalk_view.gd").new()
		view.stage=self
		add_child(view)
	load_room()
	target=clampi(int(data.get("target",0)),0,nodes.size())
	for i in target: nodes[i].done=true
	if target>0:
		hero.pos=nodes[target-1].p
		fall_origin=hero.pos
	update_hint()
	show()
func checkpoint_state(): return {"room":room,"hp":hp,"target":target,"elapsed":elapsed,"energy":energy}
func load_room():
	hero=Fighter.new().init("hero",Vector2(28,294),0,game.prefs.difficulty)
	room_name=ROUTES[chapter][1][room]
	particles.clear()
	hazards.clear()
	platforms.clear()
	nodes.clear()
	target=0
	vy=0
	jumps=0
	supported=-1
	grounded=true
	fall_origin=hero.pos
	shield=1.2
	jump_buffer=0
	grace=0.12
	control_lock=0.15
	room_pulse=1.8
	var shape:int=ROUTES[chapter][2][room]
	for v in SHAPES[shape]: platforms.append(Rect2(v[0],v[2],v[1],13))
	var gap=249+(shape%3)*19
	platforms.append(Rect2(-16,294,gap+16,85))
	platforms.append(Rect2(gap+57,294,670-gap-57,85))
	for task in TASKS[shape]:
		var rect:Rect2=platforms[task[0]]
		var xpos=rect.get_center().x
		if task[0]==5: xpos=542
		var p=Vector2(roundf(xpos),rect.position.y)
		nodes.append({"p":p,"kind":task[1],"done":false,"hp":2 if task[1] in ["lock","drone"] else 1})
	var danger_platform=platforms[1 if shape%2==0 else 3]
	hazards.append({"rect":Rect2(danger_platform.position.x+12,danger_platform.position.y-6,26,7),"phase":0.8+shape*0.31})
	if chapter>=7: hazards.append({"rect":Rect2(366,287,30,7),"phase":1.3+shape*0.21})
	update_hint()
func update_hint():
	if target>=nodes.size():
		hint="线路通畅 · 到右端出口按 "+("A" if game.pad else "E")
		return
	var act="A" if game.pad else "E"
	match nodes[target].kind:
		"fuse": hint="取下亮起的备用熔芯 · "+act
		"lever": hint="切换标记的分流扳杆 · "+act
		"socket": hint="接通标记的线路插座 · "+act
		"lock": hint="靠近卡住的锁头，面向它用 "+("Y" if game.pad else "K")+" 重击"
		"drone": hint="移动到同一高度，用拳脚击落亮起的干扰器"
func advance_node():
	var node=nodes[target]
	node.done=true
	burst(node.p-Vector2(0,26),Color("#a1e8c7"))
	game.sound.fx("radio",0.66,1+target*0.035)
	target+=1
	energy=minf(100,energy+15)
	game.run_score+=48
	feedback="回路已通" if target>=nodes.size() else "接点已校验"
	feedback_time=1.1
	if grounded: fall_origin=hero.pos
	checkpoint_changed.emit(checkpoint_state())
	update_hint()
func burst(pos,c):
	for i in 11:
		var ang=(i+0.37)*TAU/11
		particles.append({"p":pos,"v":Vector2(cos(ang)*49,sin(ang)*39-12),"t":0.45,"c":c})
func tick(dt):
	if completed: return
	clock+=dt
	elapsed+=dt
	game.prefs.active_seconds+=dt
	room_pulse=maxf(0,room_pulse-dt)
	feedback_time=maxf(0,feedback_time-dt)
	control_lock=maxf(0,control_lock-dt)
	shield=maxf(0,shield-dt)
	for i in range(particles.size()-1,-1,-1):
		var fx=particles[i]
		fx.p+=fx.v*dt
		fx.v.y+=93*dt
		fx.t-=dt
		if fx.t<=0: particles.remove_at(i)
	if view: view.queue_redraw()
	if control_lock>0: return
	update_hint()
	var direction=Input.get_axis("leftward","rightward")
	var jump=Input.is_action_just_pressed("upward") or Input.is_action_just_pressed("dodge")
	drop_timer=maxf(0,drop_timer-dt)
	var dropping=jump and Input.is_action_pressed("downward") and grounded and supported>=0 and supported<4
	if dropping:
		skip_ledge=supported
		drop_timer=0.35
		hero.pos.y+=2
		grounded=false
		grace=0
		vy=55
	jump_buffer=0.14 if jump and not dropping else maxf(0,jump_buffer-dt)
	if grounded: grace=0.11
	else: grace=maxf(0,grace-dt)
	if jump_buffer>0 and (grounded or grace>0 or jumps<2):
		jumps=1 if grounded or grace>0 else jumps+1
		vy=-251 if jumps==1 else -224
		jump_buffer=0
		grace=0
		grounded=false
		hero.pose("dodge",0.36)
		game.sound.fx("dodge",0.50,1.06+0.13*jumps)
		burst(hero.pos,Color("#569eab"))
	if absf(direction)>0.13: hero.face=int(signf(direction))
	var requested=""
	if Input.is_action_just_pressed("jab"): requested="jab"
	if Input.is_action_just_pressed("heavy"): requested="heavy"
	if Input.is_action_just_pressed("skill") and energy>=40: requested="skill"
	if requested!="" and (hero.state not in ["jab","heavy","skill"] or hero.time>=hero.length*0.85):
		hero.pose(requested,0.45 if requested=="heavy" else 0.32)
		if requested=="skill": energy-=40
		game.sound.fx(requested,0.61)
	hero.time+=dt
	var attacking=hero.state in ["jab","heavy","skill"]
	if attacking and not hero.struck and hero.time>hero.length*0.37:
		hero.struck=true
		strike()
	var was=hero.pos
	var run_speed=124.0 if attacking and grounded else 153.0
	hero.pos.x=clampf(hero.pos.x+direction*run_speed*dt,8,633)
	vy=minf(377,vy+dt*593)
	hero.pos.y+=vy*dt
	grounded=false
	supported=-1
	if vy>=0:
		var surface=INF
		for i in platforms.size():
			var rect:Rect2=platforms[i]
			if i==skip_ledge and drop_timer>0: continue
			if hero.pos.x>=rect.position.x-2 and hero.pos.x<=rect.end.x+2 and was.y<=rect.position.y+0.01 and hero.pos.y>=rect.position.y:
				if rect.position.y<surface:
					surface=rect.position.y
					supported=i
		if supported>=0:
			hero.pos.y=surface
			vy=0
			grounded=true
			jumps=0
			if not attacking: hero.state="walk" if absf(direction)>0.13 else "idle"
	if not attacking and not grounded: hero.state="dodge"
	if attacking and hero.time>=hero.length: hero.pose("idle" if grounded else "dodge",0.4)
	if hero.pos.y>367:
		damage(true)
		return
	for h in hazards:
		if danger_on(h) and h.rect.grow(3).has_point(hero.pos) and shield<=0: damage(false)
	if target<nodes.size():
		var node=nodes[target]
		if node.kind=="drone" and shield<=0 and fmod(clock+room*0.8,3.4)>2.92 and absf(hero.pos.y-node.p.y)<10 and absf(hero.pos.x-node.p.x)<57:
			damage(false)
		if node.kind not in ["lock","drone"] and Input.is_action_just_pressed("use") and near(node.p):
			advance_node()
	elif near(exit_pos) and Input.is_action_just_pressed("use"):
		if room==room_count-1:
			completed=true
			game.sound.fx("clear",0.8)
			finished.emit()
			return
		room+=1
		hp=mini(4,hp+1)
		load_room()
		checkpoint_changed.emit(checkpoint_state())
		game.sound.fx("confirm",0.64)
func danger_on(h): return fmod(clock+h.phase,3.5)>2.86
func near(p:Vector2): return absf(hero.pos.x-p.x)<28 and absf(hero.pos.y-p.y)<16
func strike():
	if target>=nodes.size(): return
	var node=nodes[target]
	if node.kind not in ["lock","drone"]: return
	var dx=(node.p.x-hero.pos.x)*hero.face
	var reach=94 if hero.state=="skill" else (63 if hero.state=="heavy" else 48)
	if dx< -11 or dx>reach or absf(node.p.y-hero.pos.y)>28: return
	if node.kind=="lock" and hero.state=="jab":
		game.sound.fx("guard",0.62)
		return
	node.hp-=2 if hero.state in ["skill","heavy"] else 1
	game.sound.fx("hit",0.70)
	burst(node.p-Vector2(0,27),Color("#ffd178"))
	if node.hp<=0: advance_node()
func damage(fell:bool):
	if not fell and shield>0: return
	hp-=1
	shield=1.7
	game.sound.fx("hurt",0.63,1.05)
	if fell or hp<=0:
		hero.pos=fall_origin
		vy=0
		grounded=true
		jumps=0
		control_lock=0.23
		if hp<=0:
			hp=4
			game.run_score=maxi(0,game.run_score-90)
	feedback="安全绳已回收" if fell else "绝缘受损"
	feedback_time=1.0
