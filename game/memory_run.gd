extends RefCounted
# SIDE A is a playable counterpoint to the current-night evacuation. Each
# testimony crosses four distinct sites. All locks are opened by player actions.
const STATIONS=[3,6,9,12,15]
const TITLES=["还没盖章的纸","船台上的人","刻度之外","熄灯的命令","第三次敲门"]
const SITES=[
	["电话亭","盐铺后街","旧药房","北端邮筒"],
	["修船棚","锚链机房","船腹小窗","临时登船桥"],
	["测潮井","浮标栈桥","玻璃尺台","高水记录室"],
	["配电后庭","压力仪表室","灯丝库","厂用电母线"],
	["旧台接线间","街巷分线盒","天馈走廊","A 面录音棚"]
]
const INTRO=[
	"十二年前。阿烈接到第一通求救电话，对方不肯报姓名，只说盐铺的灯已经泡在水里。",
	"造船厂还在等放行章。阿烈从车轴下捡起名单，一一去找没能登船的工友。",
	"玻璃尺上的红线是实测位置。控制室要求阿烈重新读取低一米的数字。",
	"总控下令切断民用电。阿烈拆下一组电芯，试图让街上的喇叭再响一分钟。",
	"录音带快走到底了。阿烈把空白撤离表和手抄名单，同时摆在了话筒前。"
]
const ENDINGS=[
	"盐铺老板终于答应署名。后来，他的名字被留在复写纸最薄的一层。",
	"名单少了两个人。阿烈把汽笛拉了三下，让已经离岸的船又折了回来。",
	"他读了真实的三组数，关掉公用话筒，又对着自己的录音机读了一遍。",
	"工厂的灯暗了。居民的收音机却从电池里，接到了一小段没被掐掉的声音。",
	"阿烈确实签了字。他把签过的假表完整念在 A 面，把真名单留在 B 面。他没有替自己删掉那一行。"
]
# An action triplet follows each witness through the location.
const JOBS=[
	[["call","lock","escort"],["lever","sample","send"],["escort","lock","call"],["sample","lever","send"]],
	[["lock","escort","lever"],["sample","lock","send"],["call","escort","lock"],["lever","escort","send"]],
	[["lever","sample","call"],["lock","sample","escort"],["call","lever","sample"],["escort","lock","send"]],
	[["lock","lever","sample"],["sample","call","lock"],["lever","escort","sample"],["lock","lever","send"]],
	[["call","lock","escort"],["lever","sample","call"],["lock","escort","lever"],["sample","call","send"]]
]
const CONTACTS=[
	["盐铺老板","送奶员","药剂师","邮差"],
	["铆工","轮机长","学徒","小船船长"],
	["测绘工","浮标看守","抄表员","档案员"],
	["锅炉工","电表技师","仓库值班员","分线员"],
	["报务员","街坊","天线工","年轻的老岑"]
]
const PATTERNS=[
	["rgr","grs","rsb","ggr"],["rrs","bsr","gbg","sbr"],["trg","rbt","sst","gtr"],
	["gbr","tsb","gbt","tgs"],["sbt","grt","bsg","gtb"]
]
const MAP={"r":"runner","g":"guard","s":"skater","b":"brute","t":"tech"}
var a
var episode=0
var room=0
var station=0
var action=""
var phase=0
var spent=0.0
var node=Vector2.ZERO
var origin=Vector2.ZERO
var delivery=Vector2.ZERO
var timer=0.0
var wave=0
var total=0.0
var step_clock=0.0
var strikes=0
var noise=0.0
var ticket=false
var pending=false
var awaiting=false
var note=""
var entered=0.0
var saved={}
var signal_pattern=[]
var sequence=0
var glowing=0.0
var blocking=0.0
func setup(arena,ch:int,data:Dictionary):
	a=arena
	episode=STATIONS.find(ch)
	room=clampi(int(data.get("room",0)),0,3)
	station=clampi(int(data.get("station",0)),0,2)
	total=float(data.get("elapsed",0.0))
	pending=false
	awaiting=false
	entered=0
	a.memory_mode=true
	a.kind="memory"
	a.hero.skin_override="past"
	a.hero.hp=100
	a.flux=65
	a.hero.speed=131
	load_room(station)
func snapshot():
	return {"room":room,"station":station,"elapsed":total}
func load_room(index:int):
	pending=false
	a.base=room*1680.0
	a.extent=a.base+1580
	a.enemies.clear()
	a.sparks.clear()
	a.hazards.clear()
	a.texts.clear()
	a.goods.clear()
	a.civilians.clear()
	a.has_tape=false
	a.done=false
	a.done_timer=0
	a.jammed=false
	a.combo=0
	a.combo_timer=0
	a.hero.pos=Vector2(a.base+72+index*420,291)
	a.hero.pose("idle",1)
	a.hero.hp=maxi(65,a.hero.hp)
	a.hero.invincible=1
	a.cam=clampf(a.hero.pos.x-218,a.base,a.extent-640)
	a.clock=0
	a.phase_time=0
	a.tip_timer=0
	a.wave_timer=0
	a.radio_left=0
	a.last_target=null
	a.shake=0
	a.stop_time=0
	a.duels.reset(a)
	begin_station(index)
func begin_station(idx:int):
	station=idx
	phase=0
	spent=0
	timer=0
	wave=0
	strikes=0
	noise=0
	sequence=0
	blocking=0
	glowing=0
	ticket=false
	action=JOBS[episode][room][station]
	node=Vector2(a.base+283+station*430,265+((episode*3+room*2+station)%4)*18)
	origin=node
	delivery=node+Vector2(201 if station<2 else 168,39 if node.y<280 else -24)
	sequence=0
	signal_pattern=[1,-1,1] if (room+station)%2==0 else [-1,1,-1]
	step_clock=0
	a.wave_timer=0
	a.tell(SITES[episode][room]+"  /  "+CONTACTS[episode][room])
func objective_point(): return node
func goal_text():
	var key="A" if a.game.pad else "E"
	if pending: return "沿路线抵达右侧亮灯出口"
	if phase==0: return "打通前路，击退驻守"+SITES[episode][room]+"的封港队"
	if a.jammed: return "清开设备旁的守卫"
	match action:
		"call": return "找到公共电话，按 "+key+" 拨出呼号"
		"send": return "护住记录原件 · 按住 "+key+" 送入发报机"
		"lock": return "重击封条后按 "+key+" 取回记录" if strikes<2 else "封条已破 · 按 "+key+" 取出原件"
		"lever": return "面向闪烁箭头，再按 "+key+" 拨闸   "+("←" if signal_pattern[sequence]<0 else "→")
		"sample": return ("按 "+key+" 拾取原始记录" if not ticket else "携带档案，前往发报箱按 "+key+" 投递")
		"escort": return ("靠近并按 "+key+" 招呼证人" if not ticket else "带证人到亮灯的避难点，按 "+key+" 登记")
	return ""
func tick(dt):
	total+=dt
	entered+=dt
	step_clock+=dt
	glowing=maxf(0,glowing-dt)
	blocking=maxf(0,blocking-dt)
	if awaiting: return
	if pending:
		if a.hero.pos.x>=a.extent-90:
			if room==3:
				awaiting=true
				a.game.memory_outro()
			else:
				room+=1
				load_room(0)
				a.game.save_interlude(snapshot())
		return
	if phase==0:
		if a.live_count()==0:
			timer+=dt
			if timer>=0.34:
				if wave>=2:
					phase=1
					timer=0
					a.tell("线路已清 · 取回现场记录")
				else:
					wave+=1
					timer=0
					spawn_team(2 if wave==1 else (2 if episode==0 else 3))
		return
	a.jammed=false
	for e in a.enemies:
		if e.alive() and a.is_near(e.pos,node,36): a.jammed=true
	if a.jammed: return
	var near=a.is_near(a.hero.pos,node,37)
	var tap=Input.is_action_just_pressed("use")
	if not near:
		spent=0
		return
	match action:
		"call":
			if tap: complete()
		"lock":
			if strikes>=2 and tap: complete()
		"send":
			if Input.is_action_pressed("use"):
				spent+=dt
				if spent>=1.0: complete()
			else: spent=0
		"lever":
			if tap:
				var dir=Input.get_axis("leftward","rightward")
				if absf(dir)<0.2: dir=a.hero.face
				if dir!=0 and int(signf(dir))==signal_pattern[sequence]:
					sequence+=1
					glowing=0.28
					a.sound.fx("select",0.73,0.90+0.09*sequence)
					if sequence>=signal_pattern.size(): complete()
				else: blocking=0.32
		"sample","escort":
			if tap and not ticket:
				ticket=true
				a.sound.fx("confirm",0.72)
				if action=="escort":
					a.add_local(node,false)
					a.civilians[-1].role="passenger"
				node=delivery
				spawn_team(2)
			elif tap and ticket:
				if action=="escort":
					for c in a.civilians:
						if c.role=="passenger": c.role="exit"
				complete()
func spawn_team(n):
	var pattern=PATTERNS[episode][(room+station+wave)%4]
	for i in n:
		var dir=1 if (i+station)%3!=2 else -1
		var x=clampf(a.hero.pos.x+dir*(193+i*21),a.base+18,a.extent-18)
		if absf(x-a.hero.pos.x)<85: x=a.hero.pos.x-dir*184
		var pos=Vector2(x,clampf(261+(room*19+station*7+i*25)%68,253,329))
		a.spawn_actor(MAP[pattern[(i+wave)%pattern.length()]],pos.x,pos.y)
func impact(h):
	if phase!=1 or action!="lock" or strikes>=2 or h.state not in ["heavy","skill"]: return
	var dx=(node.x-h.pos.x)*h.face
	if absf(dx)<=68 and dx> -12 and absf(h.pos.y-node.y)<28:
		strikes+=1
		glowing=0.36
		a.burst(node-Vector2(0,32),"spark",10,Color("#f5ca7f"))
		a.sound.fx("guard",0.78)
func complete():
	a.game.run_score+=180
	a.hero.hp=mini(100,a.hero.hp+11)
	a.flux=minf(100,a.flux+13)
	a.sound.fx("radio",0.8)
	a.burst(node-Vector2(0,24),"spark",10,Color("#8ee5bd"))
	if station==2:
		pending=true
		node=Vector2(a.extent-54,290)
		a.tell("录音已封存 · 前往下一地点")
	else:
		begin_station(station+1)
		a.game.save_interlude(snapshot())
func render(w):
	if not a.memory_mode: return
	var p=w.screen(node)
	if p.x< -48 or p.x>686:
		var side=1 if p.x>320 else -1
		w.caption(Vector2(602 if side==1 else 36,171),"记录  >" if side==1 else "<  记录",Color("#ffda83"))
		return
	var tint=Color("#eed397")
	if pending:
		w.prop(p,"exit")
		w.caption(p-Vector2(0,57),"下一处  >",tint)
		return
	var item="radio"
	if action=="lock": item="console"
	if action=="escort": item="shelter" if not ticket else "exit"
	if action=="sample": item="tape" if not ticket else "console"
	w.prop(p,item)
	if phase==0:
		w.caption(p-Vector2(0,69),"封锁中",Color("#ff9b7d"))
	elif action=="lever":
		w.caption(p-Vector2(0,74),["左","右"][1 if signal_pattern[sequence]>0 else 0]+" + "+("A" if a.game.pad else "E"),Color("#ff8f73") if blocking>0 else tint)
	else:
		w.caption(p-Vector2(0,72),("原始记录" if action!="escort" else "目击证人"),tint)
	if spent>0:
		w.box(p.x-15,p.y-84,30,4,w.INK)
		w.box(p.x-14,p.y-83,28*spent,2,tint)
