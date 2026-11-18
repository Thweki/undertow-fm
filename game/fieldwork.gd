extends RefCounted
# Each pair is an address and its relay contact. Different cable runs cross the
# block in different orders, placing fights both ahead of and behind the player.
const LINES=[
	[[218,278],[535,313],[370,259],[724,293],[559,324],[879,259],[1030,305]],
	[[315,317],[176,258],[500,288],[772,320],[591,260],[930,288],[1110,318]],
	[[230,262],[456,320],[665,269],[879,313],[530,296],[740,260],[1010,301]],
	[[293,295],[560,256],[407,321],[675,296],[973,260],[762,320],[1092,280]]
]
const DUTIES=["listen","breaker","pickup","link","listen","breaker","sign"]
const GATES=["crossing","lock","passenger","crossing","lock","passenger"]
var a
var stage=0
var duty=""
var sub=0
var points=[]
var current=Vector2.ZERO
var address=Vector2.ZERO
var from=Vector2.ZERO
var capture=0.0
var dial=0.0
var dial_center=0.45
var lock=0.0
var spawn_gap=0.0
var cart_gate=0
var loading=false
var occupants=0
var message=""
var visual=0.0
var open_nodes=[]
var steps=0
func reset(arena):
	a=arena
	stage=0
	sub=0
	points=[]
	open_nodes=[]
	capture=0
	visual=0
	occupants=0
	lock=0
	spawn_gap=0
	loading=false
	if a.kind not in ["relay","escort"]: return
	if a.kind=="relay":
		for v in LINES[a.chapter%4]: points.append(Vector2(a.base+v[0],v[1]))
		a.goal=points.size()
	else:
		for i in 6:
			points.append(Vector2(a.base+260+i*155,clampf(286+sin(i*1.7+a.chapter)*28,255,325)))
		a.goal=points.size()
	begin()
func begin():
	a.progress=stage
	sub=0
	capture=0
	steps=0
	lock=0.5
	spawn_gap=0.8
	address=points[stage]
	dial_center=[0.32,0.54,0.73][(stage+a.chapter)%3]
	if a.kind=="relay":
		duty=DUTIES[stage]
		current=address
		if duty=="link":
			current=address+Vector2(-105,18)
		a.device=address
	else:
		duty=GATES[stage]
		loading=false
		current=address
		if duty=="passenger": current=address+Vector2(81,24 if address.y<291 else -27)
	a.tell((["一","二","三","四","五","六","七"][stage])+"号"+(a.Book.LOCAL[a.chapter][0] if a.kind=="relay" else "路标"))
func finish_step():
	open_nodes.append(address)
	stage+=1
	visual=0.62
	a.progress=stage
	a.sound.fx("radio",0.66,1+0.025*stage)
	a.burst(current-Vector2(0,24),"spark",8,Color("6dd6c0"))
	a.flux=minf(100,a.flux+5)
	if stage>=points.size():
		a.finish()
		return
	begin()
func report():
	var use="A" if a.game.pad else "E"
	if a.kind=="escort" and loading:
		return "走在车头引路，把"+a.Book.LOCAL[a.chapter][1]+"带到路标"
	if a.jammed: return "接点受干扰 · 清开标记附近的封港队"
	match duty:
		"listen": return "监听接点 · 在亮区按 "+use+" 锁定载波"
		"breaker","lock": return ("用 Y 重击" if a.game.pad else "用 K 重击")+"卡住的闸杆（%d/2）"%steps
		"pickup": return "靠近领取手抄频表 · 按住 "+use if sub==0 else "将频表交给收报员 · 按住 "+use
		"link": return "铺设旁路线 · 从亮起的接头走向下一端"
		"crossing": return "路口被封锁 · 击退本处的守卫"
		"passenger": return "寻找候车街坊 · 按 "+use+" 招呼" if sub==0 else "引导街坊回到车边"
	return "登记本段的呼号 · 按住 "+use
func tick(dt):
	if a.done: return
	visual=maxf(0,visual-dt)
	lock=maxf(0,lock-dt)
	dial=fmod(dial+dt*0.66,2)
	var h=a.hero
	var near=a.is_near(h.pos,current,42)
	a.near_device=near
	a.jammed=false
	for e in a.enemies:
		if e.alive() and a.is_near(e.pos,current,34): a.jammed=true
	if spawn_gap>0:
		spawn_gap-=dt
		if spawn_gap<=0:
			a.wave+=1
			var count=2 if a.chapter<4 else 3
			if a.live_count()>=2: count=1
			for i in count:
				var ex=clampf(address.x+(-1 if i%2==0 else 1)*(69+14*i),a.base+16,a.extent-18)
				a.spawn_actor(a.roster(i),ex,clampf(address.y+(i-1)*14,255,329))
	if a.kind=="escort":
		if loading:
			# Walking alongside or just ahead guides the driver. The vehicle
			# catches up quickly, letting players deal with the next roadblock.
			var dx=h.pos.x-a.device.x
			if dx>-50 and absf(h.pos.y-a.device.y)<52:
				var speed=clampf(63+dx*0.31,54,133)
				a.device=a.device.move_toward(address,speed*dt)
			current=address if dx<160 else a.device
			if a.device.distance_to(address)<3: finish_step()
			return
		elif h.pos.x>a.device.x and a.device.x<address.x-64:
			a.device.x=minf(address.x-64,move_toward(a.device.x,h.pos.x-17,66*dt))
			a.device.y=move_toward(a.device.y,address.y,14*dt)
	if lock>0: return
	if duty=="crossing":
		if a.live_count()==0 and spawn_gap<=0 and h.pos.distance_to(address)<98:
			cleared()
		return
	if duty in ["breaker","lock"]: return
	if not near or a.jammed:
		capture=maxf(0,capture-dt)
		return
	match duty:
		"listen":
			if Input.is_action_just_pressed("use"):
				var value=dial if dial<=1.0 else 2.0-dial
				if absf(value-dial_center)<=window():
					cleared()
				else:
					lock=0.24
					a.sound.fx("guard",0.35)
		"pickup":
			if Input.is_action_pressed("use") and h.can_move():
				capture+=dt
				if capture>=0.60:
					if sub==0:
						sub=1
						capture=0
						current=address+Vector2(163 if stage%2==0 else -163,-18 if address.y>=289 else 21)
						a.sound.fx("select")
					else: cleared()
		"link":
			if sub==0:
				sub=1
				current=address+Vector2(81,-10)
				a.sound.fx("select")
			else: cleared()
		"passenger":
			if sub==0:
				if Input.is_action_just_pressed("use"):
					sub=1
					a.add_local(current,false)
					a.civilians[-1].role="passenger"
					current=a.device
					a.sound.fx("confirm",0.6)
			else:
				current=a.device
				if a.is_near(h.pos,a.device,35):
					for c in a.civilians:
						if c.role=="passenger": c.role="cart"
					occupants+=1
					cleared()
		"sign":
			if Input.is_action_pressed("use") and h.can_move():
				capture+=dt
				if capture>=1.0: cleared()
func window(): return 0.22 if a.game.prefs.difficulty==0 else 0.16
func cleared():
	if a.kind=="escort":
		loading=true
		current=address
		a.sound.fx("confirm",0.69)
		lock=0.30
	else: finish_step()
func strike(h):
	if a.done or loading or a.kind not in ["escort","relay"] or duty not in ["breaker","lock"]: return
	if h.state not in ["heavy","skill"]: return
	var dx=(current.x-h.pos.x)*h.face
	if absf(dx)>73 or (h.state!="skill" and dx< -12) or absf(current.y-h.pos.y)>29: return
	a.sound.fx("guard",0.76,0.91+0.13*steps)
	a.burst(current-Vector2(0,34),"spark",10,Color("f4c176"))
	a.shake=1.8
	steps+=1
	if steps>=2: cleared()
func ground(w):
	if a.done or a.kind not in ["escort","relay"]: return
	for at in open_nodes:
		var p=w.screen(at)
		if p.x>0 and p.x<640:
			w.box(p.x-8,p.y-2,17,2,Color("#73beaa"))
	var p=w.screen(current)
	if p.x< -20 or p.x>660: return
	var gold=Color("#ffd17e")
	var mint=Color("#8ae0be")
	var col=gold if a.jammed else mint
	if duty in ["lock","breaker"] and not loading:
		w.box(p.x-13,p.y-34,27,34,w.INK)
		w.box(p.x-10,p.y-31,21,27,Color("#754d46"))
		w.box(p.x-7,p.y-27,14,6,gold)
		var dir=1 if steps==0 else -1
		w.draw_line(p+Vector2(0,-12),p+Vector2(dir*8,-26),mint,3)
		w.box(p.x-1+dir*8,p.y-28,5,4,w.FOAM)
	else:
		w.ellipse(p,19,5,Color(col,0.67),false)
		var top=p+Vector2(0,-28)
		w.box(top.x-1,top.y,3,25,col)
		w.draw_colored_polygon([top-Vector2(0,9),top+Vector2(10,-5),top],col)
	if duty=="listen" and not loading and a.near_device:
		var x=p.x-35
		var y=p.y-70
		w.box(x,y,70,12,w.INK)
		w.box(x+3,y+4,64,4,Color("#3b5961"))
		w.box(x+3+(dial_center-window())*64,y+2,window()*128,8,mint)
		var value=dial if dial<=1.0 else 2.0-dial
		w.box(x+3+value*64,y+1,2,10,gold)
