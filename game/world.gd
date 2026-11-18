extends Node2D

const Book = preload("res://game/campaign.gd")
const FONT = preload("res://assets/fonts/FusionPixel.ttf")
const PROP_SHEET = preload("res://assets/world/props.png")
const ARCHIVE_SHEET=preload("res://assets/world/archive_props.png")
const INK = Color("#10212e")
const MINT = Color("#85e6c6")
const FOAM = Color("#f2eacb")
const GOLD = Color("#ffc977")
const ALERT = Color("#ff977b")
const CYAN = Color("#80cfd5")
const VEILS = ["ffffff","fff1da","efe1fa","d5f2fc","d1d9ee","ffead1","d1effa","f9e3d2","dfdbef","e3eddb","d9e5fa","f6dccd","edcbd5","e2e4f9","c6e7ed","ffdab5"]
const RAIN_FALL = [12,23,10,29,46,19,13,43,30,37,19,48,38,53,61,22]
const PROP_ID = {"bag":0,"radio":1,"cart":2,"shelter":3,"console":4,"crate":5,"fuse":6,"medical":7,"tape":8,"exit":9}
var arena
var far_layer: Texture2D
var mid_layer: Texture2D
var road: Texture2D
var landmark: Texture2D
var stage = 0
var district = "workshop"
var tint = Color.WHITE
var offset = Vector2.ZERO
var eye = 0.0
var clock = 0.0

func set_stage(ch: int):
	stage = ch
	district = Book.PLACES[ch][1]
	var prefix = "res://assets/world/" + district
	far_layer = load(prefix + "_far.png")
	mid_layer = load(prefix + "_mid.png")
	road = load(prefix + "_ground.png")
	var id = int(Book.PLACES[ch][-1])
	landmark = load("res://assets/world/landmark_%02d.png" % id) if id > 0 else null
	tint = Color(VEILS[ch])
	if arena.memory_mode:
		mid_layer=load("res://assets/world/past_%d.png"%arena.memory_index)
		landmark=null
		tint=Color("#e4edce")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	queue_redraw()

func screen(p: Vector2) -> Vector2:
	return Vector2(roundf(p.x - eye),roundf(p.y)) + offset

func box(x: float,y: float,w: float,h: float,c: Color):
	draw_rect(Rect2(roundf(x),roundf(y),roundf(w),roundf(h)),c)

func ellipse(p: Vector2, rx: float, ry: float, col: Color, fill = true):
	# Pixel spans keep thin contact shadows and rings on the character pixel grid.
	var iy = maxi(1,roundi(ry))
	for row in range(-iy,iy+1):
		var fraction = float(row) / (iy+0.35)
		var width = maxi(1,roundi(rx*sqrt(maxf(0,1.0-fraction*fraction))))
		if fill:
			box(p.x-width,p.y+row,width*2+1,1,col)
		else:
			var previous = mini(iy,absi(row)+1)
			var next_w = roundi(rx*sqrt(maxf(0,1.0-pow(float(previous)/(iy+0.35),2))))
			var run = width+1 if absi(row)==iy else maxi(1,width-next_w)
			box(p.x-width,p.y+row,run,1,col)
			box(p.x+width-run+1,p.y+row,run,1,col)

func line(points: PackedVector2Array, c: Color, width = 1):
	draw_polyline(points,c,width,false)

func caption(p: Vector2,s: String,c: Color,plate=true,size=12):
	var w = ceilf(FONT.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x)
	var x = clampf(roundf(p.x-w*0.5),4,636-w)
	var y = roundf(p.y)
	if plate:
		box(x-4,y-size,w+8,size+4,Color("#10232de8"))
		box(x-4,y-size,2,size+4,c)
	draw_string(FONT,Vector2(x,y+1)+Vector2(1,1),s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,INK)
	draw_string(FONT,Vector2(x,y+1),s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)

func tile(tex: Texture2D, travel: float, color: Color, mirror_alternate=false):
	if not tex: return
	var w = tex.get_width()
	var x = -floori(fposmod(travel,float(w)))
	for i in range(-1,2):
		var left = x+i*w
		if left>=644 or left+w< -4: continue
		if mirror_alternate and posmod(floori(travel/w)+i,2)==1:
			draw_set_transform(Vector2(left+w,0)+offset,0,Vector2(-1,1))
			draw_texture(tex,Vector2.ZERO,color)
			draw_set_transform(Vector2.ZERO)
		else: draw_texture(tex,Vector2(left,0)+offset,color)

func draw_background():
	tile(far_layer, eye*0.19+stage*113.0,tint,true)
	# Twilight uplink blinks and gulls crossing in the upper layers.
	for i in range(3):
		var x = fposmod(i*184.0+104+clock*(6+i)-eye*0.25+stage*173,688)-24
		var y = 65+i*14+roundf(3*sin(clock*0.6+i))
		var wing = roundf(sin(clock*4+i)*2.1)
		line([Vector2(x-5,y+wing),Vector2(x-2,y-1),Vector2(x,y+1),Vector2(x+3,y-1),Vector2(x+6,y+wing-1)],Color("#334954"))
	tile(mid_layer,eye*0.74+stage*171,tint)
	if landmark:
		# One recognizable landmark at this block's approach. Blocks have different
		# camera starts and alternate the focal point between near and far ends.
		var j = arena.section
		var anchor = arena.base + [427,875,588,772,452,932][j%6]
		var x = screen(Vector2(anchor,0)).x-160
		if x<640 and x+320>0:
			draw_texture(landmark,Vector2(x,50+offset.y),tint)
	tile(road,eye+stage*93.0,tint)
	if stage>0 and not arena.memory_mode:
		var marker = screen(Vector2(arena.base+108,249))
		if marker.x>-80 and marker.x<730:
			box(marker.x-2,marker.y-35,4,35,Color("#4c6265"))
			box(marker.x-19,marker.y-47,39,17,INK)
			box(marker.x-18,marker.y-46,37,1,Color("#95aaa0"))
			caption(marker+Vector2(0,-34),"%02d · %02d"%[stage,arena.section+1],Color("#c2cfb5"),false,10)

func rain():
	if arena.game.prefs.calm: return
	if arena.memory_mode and arena.memory_index in [2,3]:
		for i in range(13):
			var xx=fposmod(i*87.0-eye*.32+clock*.7,656)-8
			var yy=55+fposmod(i*43.0+clock*(2+i%3),197)
			box(xx,yy,1,1,Color(.75,.82,.64,.22))
		return
	var n = int(RAIN_FALL[stage])
	for i in range(n):
		var speed = 112+(i*17)%113
		var x = fposmod(i*217.0 - eye*(0.35+float(i%4)*0.16)-clock*speed*(0.16+0.03*(stage%4)),666)-12
		var y = fposmod(i*119.0 + clock*speed,384)-12
		var length = 3+i%5
		draw_line(Vector2(roundf(x),roundf(y)),Vector2(roundf(x)-2,roundf(y)+length),Color(0.69,0.82,0.82,0.15+0.04*(i%3)),1,false)
	for i in range(n/2):
		var loop = fposmod(clock*.84+i*.401,1.0)
		if loop>.58: continue
		var x = fposmod(i*193.0-eye,660)-10
		var y = 253+(i*23)%82
		var w = roundf(1+loop*10)
		var c = Color(0.70,0.84,0.80,(.58-loop)*.39)
		box(x-w,y,w-1,1,c);box(x+1,y,w,1,c)
		if loop<.13: box(x,y-2,1,2,c)

func danger_corners(rect: Rect2, c: Color):
	box(rect.position.x,rect.position.y,rect.size.x,rect.size.y,Color(c,.045))
	for dx in [-1,1]:
		for dy in [-1,1]:
			var corner=rect.get_center()+rect.size*.5*Vector2(dx,dy)
			line([corner-Vector2(dx*6,0),corner,corner-Vector2(0,dy*3)],c)

func warning_ground(e):
	if e.state!="warn" or arena.duels.controls(e): return
	var p = screen(e.pos)
	var t = clampf(e.time/e.length,0,1)
	var pulse = Color(ALERT,0.15+t*0.23)
	if e.attack_type=="skill":
		var radius = 115 if e.kind=="boss" else 91
		danger_corners(Rect2(p-Vector2(radius,39),Vector2(radius*2,78)),Color(ALERT,.42+t*.32))

		ellipse(p,radius,27,Color(ALERT,0.08))
		ellipse(p,radius,27,pulse,false)
		ellipse(p,radius*(0.3+0.7*t),27*(0.3+0.7*t),Color(ALERT,0.45+t*.37),false)
	else:
		var reach = e.reach+11
		var x = p.x-12 if e.face==1 else p.x-reach
		danger_corners(Rect2(x,p.y-23,reach+12,46),Color(ALERT,.42+t*.32))
		box(x,p.y-4,reach+12,9,pulse)
		box(x,p.y+4,reach,1,Color(ALERT,0.7))
		for j in range(3):
			var xx = p.x+e.face*(14+j*12+roundf(4*t))
			line([Vector2(xx-e.face*3,p.y-3),Vector2(xx,p.y),Vector2(xx-e.face*3,p.y+3)],Color(ALERT,.55+t*.4))

func fighter(e):
	var p = screen(e.pos)
	if p.x < -65 or p.x > 705: return
	var anim = e.attack_type if e.state=="warn" else e.state
	if e.kind=="hero" and anim=="jab" and e.chain>=2:
		anim = "cross" if e.chain==2 else "upper"
	var tex: Texture2D = e.texture_for(anim)
	if not tex and e.state=="jab": tex=e.texture_for("jab")
	if tex:
		var idx = e.frame_id()
		var src = Rect2(idx*96,0,96,88)
		var mod = e.palette
		if e.state=="down" and e.kind!="hero": mod.a = clampf((.90-e.time)*4.0,0,1)
		elif e.invincible>.05 and e.state=="hurt": mod = Color(1.25,1.14,1.03,1)
		elif e.recent_hit>.10: mod=Color(1.5,1.35,1.15)
		var flip = Vector2(e.face,1)
		if e.state=="dodge" and not arena.game.prefs.calm:
			for j in range(2,0,-1):
				draw_set_transform((p-e.vector*float(j*8)).round(),0,flip)
				draw_texture_rect_region(tex,Rect2(-48,-80,96,88),src,Color(.40,1.0,.97,.14+j*.025))
		draw_set_transform(p,0,flip)
		draw_texture_rect_region(tex,Rect2(-48,-80,96,88),src,mod)
		draw_set_transform(Vector2.ZERO)
	if e.kind in ["runner","guard","brute","skater","tech","boss"] and e.alive():
		var h = -77 if e.kind in ["boss","brute"] else -63
		if e.state=="warn":
			var m = p+Vector2(0,h-5)
			if e.attack_type=="skill": m.x+=10*e.face
			draw_colored_polygon([m+Vector2(0,-6),m+Vector2(5,-1),m+Vector2(0,4),m+Vector2(-5,-1)],ALERT)
			box(m.x-1,m.y-4,2,4,INK);box(m.x-1,m.y+1,2,1,INK)
		elif e.role!="" and e.kind!="boss":
			line([p+Vector2(-5,h),p+Vector2(-3,h+3),p+Vector2(0,h-1),p+Vector2(3,h+3),p+Vector2(5,h)],GOLD)
		if e.hp<e.max_hp and e.kind!="boss":
			box(p.x-13,p.y+h+5,26,4,INK);box(p.x-12,p.y+h+6,24*float(e.hp)/e.max_hp,2,ALERT)
	if e.kind=="hero" and arena.carry:
		var q=p+Vector2(-e.face*11,-36)
		draw_texture_rect_region(PROP_SHEET,Rect2(q.x-16,q.y-26,32,40),Rect2(PROP_ID.crate*64,0,64,80))

func prop(p: Vector2,id: String,completed=false):
	if p.x < -45 or p.x > 685: return
	if arena.memory_mode and id in ["console","tape","radio"] and not arena.memoryrun.pending:
		var job=arena.memoryrun.action
		var cell={"call":0,"lock":1,"lever":2,"sample":5 if arena.memoryrun.ticket else 3,"send":4}.get(job,-1)
		if cell>=0:
			draw_texture_rect_region(ARCHIVE_SHEET,Rect2(p.x-32,p.y-78,64,80),Rect2(cell*64,0,64,80))
			return
	var bob = 0
	if id in ["tape","medical"]: bob=roundi(2.2*sin(clock*4+p.x))
	draw_texture_rect_region(PROP_SHEET,Rect2(p.x-32,p.y-78+bob,64,80),Rect2(PROP_ID[id]*64,0,64,80),Color("#9cafa3") if completed else Color.WHITE)
	if id in ["console","radio","fuse"]:
		var h = {"radio":68,"console":60,"fuse":13}[id]
		if sin(clock*4 + p.y*.2)>0 and not completed: box(p.x+2,p.y-h,3,2,MINT)

func objects() -> Array:
	var list=[]
	if arena.chapter==0:
		list.append([Vector2(365,286),"bag",false])
		list.append([Vector2(615,283),"radio",false])
	match arena.kind:
		"relay":
			if arena.field.duty=="listen": list.append([arena.device,"radio",false])
			elif arena.field.duty not in ["breaker","lock"]: list.append([arena.device,"fuse",false])
		"escort":
			list.append([arena.device,"cart",false])
			list.append([arena.destination,"exit",false])
		"rescue","tune":
			for i in arena.spots.size(): list.append([arena.spots[i],"shelter" if arena.kind=="rescue" else "console",i<arena.spot_idx])
		"haul":
			list.append([arena.device,"cart",false])
			for i in range(arena.cargo_count,arena.spots.size()):
				if i==arena.cargo_count and arena.carry: continue
				list.append([arena.spots[i],"crate",false])
	if arena.has_tape: list.append([arena.tape_pos,"tape",false])
	for g in arena.goods: list.append([g.p,"medical",false])
	if arena.done and arena.chapter>0 and arena.section<5:
		list.append([arena.destination,"exit",false])
	return list

func guidance_point() -> Vector2:
	if arena.memory_mode: return arena.memoryrun.node
	var waypoint=arena.duels.guidance()
	if waypoint!=Vector2.INF: return waypoint
	var warden=arena.duels.priority_enemy()
	if warden!=null: return warden.pos
	if arena.kind in ["fight","boss","elite"] and not arena.done:
		var best = INF
		var point = arena.hero.pos
		for e in arena.enemies:
			if e.alive() and e.pos.distance_squared_to(arena.hero.pos)<best:
				best = e.pos.distance_squared_to(arena.hero.pos)
				point=e.pos
		return point
	return arena.target_point()

func guide_ground():
	if arena.kind in ["fight","boss","elite"] and not arena.done: return
	if arena.done and (stage==0 or arena.section==5): return
	var t = guidance_point()
	var p = screen(t)
	if p.x<-115 or p.x>755: return
	var relay = arena.kind in ["relay","escort"] and t==arena.device
	var band = GOLD if arena.jammed and stage>0 else MINT
	if arena.kind=="lesson" and arena.lesson==3:
		scan_lesson()
		return
	var r = 39 if relay else (25 if arena.kind=="lesson" and arena.lesson==0 else 22)
	var w = r+roundf(3*sin(clock*3))
	ellipse(p,w,7,Color(band,0.15))
	ellipse(p,w,7,Color(band,.78),false)
	for side in [-1,1]:
		line([p+Vector2(side*(r+8),-3),p+Vector2(side*(r+4),0),p+Vector2(side*(r+8),3)],band)
	if arena.done or (arena.kind=="lesson" and arena.lesson==0):
		var up = p+Vector2(0,-17+roundf(sin(clock*5)*2))
		line([up+Vector2(-5,-3),up+Vector2(0,1),up+Vector2(5,-3)],MINT,2)

func scan_lesson():
	var p = screen(arena.hero.pos)
	var t = arena.lesson_pulse
	var window = t>=1.10 and t<=1.55
	var left = p.x-60
	box(left,p.y+4,120,6,Color(INK,.85))
	var fraction = t/2.6
	box(left+1,p.y+5,118,4,Color("#43676e"))
	box(left+50,p.y+5,21,4,GOLD)
	box(left+118*fraction,p.y+3,2,8,FOAM)
	if window:
		ellipse(p,31,8,Color(GOLD,.8),false)

func prompt():
	if arena.memory_mode: return
	var duel_waypoint=arena.duels.guidance()!=Vector2.INF
	var fight=arena.kind in ["fight","elite","boss"] and not arena.done and not duel_waypoint
	if arena.done and (stage==0 or arena.section==5): return
	if fight and arena.live_count()==0: return
	var target = guidance_point()
	var p=screen(target)
	if p.x<10 or p.x>630:
		var d = 1 if p.x>630 else -1
		var side = 10 if d<0 else 630
		var y = clampf(p.y-48,188,279)
		var col = ALERT if fight else MINT
		var xx=side+(-3 if d>0 else 3)
		draw_colored_polygon([Vector2(xx+5*d,y),Vector2(xx-3*d,y-5),Vector2(xx-3*d,y+5)],col)
		var label = "敌" if fight else ("出口" if arena.done else "目标")
		caption(Vector2(side-17*d,y-6),label,col,true)
		return
	if fight: return
	if arena.done:
		caption(p+Vector2(0,-55),"前进  >",MINT,true)
		return
	if arena.kind=="lesson":
		if arena.lesson==0: return
		if arena.lesson==3:
			if arena.lesson_pulse>1.10 and arena.lesson_pulse<1.55:
				caption(screen(arena.hero.pos)+Vector2(0,-85),"现在闪避",GOLD,true)
			return
		if arena.lesson==5:
			caption(p+Vector2(0,-81),("A" if arena.game.pad else "E")+"  发报",MINT,true)
		elif not arena.is_near(arena.hero.pos,target,77):
			caption(p+Vector2(0,-81),"练习沙袋",GOLD,true)
		return
	var key = "A" if arena.game.pad else "E"
	var near = arena.is_near(arena.hero.pos,target,45)
	var tag = ""
	var c = MINT
	if duel_waypoint:
		# The duel controller draws both the station and its engagement cue.
		return
	var height = 64
	match arena.kind:
		"escort","relay":
			var f=arena.field
			height=51
			if f.loading:
				tag="随车引路"
			elif arena.jammed and f.duty not in ["lock","breaker"]:
				tag="清除干扰";c=ALERT
			else:
				match f.duty:
					"listen":
						tag=key+" 锁频" if near else "监听接点"
						height=87
					"lock","breaker":
						tag=("Y" if arena.game.pad else "K")+" 重击 %d/2"%f.steps
						height=49
					"pickup": tag=("按住 "+key) if near else ("领取频表" if f.sub==0 else "提交频表")
					"link": tag="连接旁路"
					"crossing": tag="清开路口"
					"passenger": tag=key+" 招呼" if f.sub==0 else "引回车边"
					"sign": tag="按住 "+key+" 登记"
			if f.capture>0:
				var by=p.y-height+6
				box(p.x-15,by,30,4,INK)
				box(p.x-14,by+1,28*minf(1.0,f.capture/(.6 if f.duty=="pickup" else 1.0)),2,MINT)

		"rescue","haul","tune":
			height = {"rescue":86,"haul":58 if arena.carry else 35,"tune":72}[arena.kind]
			if arena.jammed: tag="清除干扰";c=ALERT
			elif arena.kind=="tune":
				tag=key+" 校频" if near else "待校频"
			elif arena.kind=="rescue": tag="按住 "+key+" 开门" if near else "待救援"
			else: tag=("按住 "+key if near else "")+(" 卸载" if arena.carry else " 搬起")
	if tag!="": caption(p+Vector2(0,-height),tag,c,true)
	if arena.kind=="tune" and near and not arena.jammed and arena.spot_idx<arena.spots.size():
		var v = arena.tune_phase if arena.tune_phase<1 else 2-arena.tune_phase
		var target_val = arena.tune_centers[arena.spot_idx]
		var width = 0.21 if arena.game.prefs.difficulty==0 else 0.15
		var left = p.x-34
		var y = p.y-height+6
		box(left-1,y-1,70,8,INK);box(left,y,68,6,Color("#4e6a6e"))
		box(left+(target_val-width)*68,y,2*width*68,6,GOLD)
		box(left+v*66,y-2,2,10,FOAM)
	elif arena.work>0:
		var y=p.y-height+6
		box(p.x-20,y,40,4,INK);box(p.x-19,y+1,38*arena.work/(.78 if arena.kind=="haul" else 1.35),2,MINT)
func flood_warning(h):
	var p=screen(h.p)
	if h.age<1.35:
		var t=h.age/1.35
		danger_corners(Rect2(p-Vector2(44,13),Vector2(88,26)),Color(ALERT,.5))
		ellipse(p,44,12,Color(ALERT,.12))
		ellipse(p,44,12,Color(ALERT,.72),false)
		ellipse(p,44*(1-t*.67),12*(1-t*.67),Color(GOLD,.4+t*.4),false)
		for d in [-1,1]:
			line([p+Vector2(d*46,-3),p+Vector2(d*42,0),p+Vector2(d*46,3)],ALERT)
		box(p.x-1,p.y-7,2,6,GOLD);box(p.x-1,p.y+1,2,2,GOLD)
	else:
		var t = (h.age-1.35)/.40
		for i in range(11):
			var d = (i-5)*7.0
			var hei=(1-absf(d)*.015)*(1.0-t)*(19+posmod(i*17,21))
			var q=p+Vector2(d,roundf(3*sin(i*1.8)))
			if hei >= 2:
				draw_colored_polygon([q+Vector2(-4,0),q+Vector2(roundf(d*.13),-roundf(hei)),q+Vector2(4,0)],Color(CYAN,.80-t*.43))
			box(q.x+d*.13,q.y-hei,2,3,FOAM)
		ellipse(p,41+t*8,9+t*3,Color(CYAN,.72*(1-t)),false)

func slash(p: Vector2,face: float,t: float,heavy: bool):
	var length = 22 if heavy else 14
	var turn = 0.87 if heavy else 0.37
	var previous=Vector2.ZERO
	for j in range(9):
		var a=-1.4+turn+t*.75+j*.19
		var point=(p+Vector2(cos(a)*length*face,sin(a)*length)).round()
		if j>0 and point!=previous:
			var stroke_width=1+roundi(2.1*sin((j-.5)*PI/8))
			draw_line(previous,point,Color(GOLD if heavy else FOAM,1.0-t*.63),stroke_width,false)
		previous=point

func effects():
	for s in arena.sparks:
		var p=screen(s.p)
		if p.x<-140 or p.x>780: continue
		match s.kind:
			"spark","mist":
				var c=Color(s.c,clampf(s.t*6,0,1))
				var trail=(s.v*.026).round()
				draw_line(p,p-trail,c,2 if s.kind=="spark" else 1,false)
				box(p.x,p.y,2,1,FOAM if s.t>.18 and s.kind=="spark" else c)
			"ring","hostile":
				var friendly=s.kind=="ring"
				var t=clampf(1.0-s.t/(.30 if friendly else .18),0,1)
				var radius=(103 if friendly else 92)*sqrt(t+.01)
				var c=MINT if friendly else ALERT
				ellipse(p,radius,6+radius*.28,Color(c,(1-t)*.82),false)
				ellipse(p,radius*.86,4+radius*.24,Color(FOAM,(1-t)*.60),false)
				for i in range(10):
					var a=i*TAU/10+0.17
					var dir=Vector2(cos(a),sin(a)*.59)
					draw_line((p+dir*radius*.63).round(),(p+dir*radius*.92).round(),Color(c,1-t),2)
			"impact":
				var t = 1.0-s.t/.18
				for j in range(8):
					var a=TAU*j/8+.22
					var dir=Vector2.from_angle(a)
					var w=dir.orthogonal()*2
					var spot=p+dir*(3+t*9)
					draw_colored_polygon([spot-w,spot+dir*(6+t*3),spot+w],Color(FOAM if j%2 else GOLD,1-t*.8))
			"sweep","swish":
				slash(p,s.v.x,1.0-s.t/.18,s.kind=="sweep")
	for t in arena.texts:
		var p=screen(t.p)
		caption(p,t.s,Color(t.c,clampf(t.t*6,0,1)),false)

func hero_locator(actors):
	var h=arena.hero
	if not h.alive(): return
	for other in actors:
		if other==h or not other.alive(): continue
		if absf(other.pos.x-h.pos.x)<20 and other.pos.y>=h.pos.y and other.pos.y-h.pos.y<24:
			var p=screen(h.pos)
			var c=Color(MINT,.82)
			line([p+Vector2(-14,-2),p+Vector2(-17,0),p+Vector2(-14,2)],c)
			line([p+Vector2(14,-2),p+Vector2(17,0),p+Vector2(14,2)],c)
			return

func _draw():
	if not arena or not arena.hero or not far_layer: return
	clock=arena.clock
	eye=arena.cam
	offset=Vector2.ZERO
	if arena.game.prefs.tremor and arena.shake>.1:
		offset=Vector2(roundf(sin(clock*144)*arena.shake*.8),roundf(cos(clock*108)*arena.shake*.6))
	draw_background()
	guide_ground()
	for h in arena.hazards: flood_warning(h)
	arena.field.ground(self)
	arena.duels.draw_ground(self)
	if arena.memory_mode: arena.memoryrun.render(self)
	var actors = [arena.hero]
	actors.append_array(arena.enemies)
	var people = arena.get("civilians")
	if people: actors.append_array(people)
	var order=[]
	for o in objects():
		var p=screen(o[0])
		if p.x < -48 or p.x > 688: continue
		ellipse(p,17 if o[1] not in ["cart","shelter"] else 27,4,Color(INK,.42))
		order.append([o[0].y,0,o])
	for actor in actors:
		var p=screen(actor.pos)
		if p.x<-64 or p.x>704: continue
		var size=22 if actor.kind in ["brute","boss"] else 16
		ellipse(p+Vector2(1,1),size+4,4,Color(INK,.26))
		ellipse(p+Vector2(0,1),size,3,Color(INK,.53))
		warning_ground(actor)
		order.append([actor.pos.y,1,actor])
	order.sort_custom(func(a,b): return a[0]<b[0] if a[0]!=b[0] else a[1]<b[1])
	for draw_item in order:
		if draw_item[1]==0:
			var o=draw_item[2]
			prop(screen(o[0]),o[1],o[2])
		else: fighter(draw_item[2])
	hero_locator(actors)
	effects()
	rain()
	prompt()
