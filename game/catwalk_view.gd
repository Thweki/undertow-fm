extends Node2D

const FONT=preload("res://assets/fonts/FusionPixel.ttf")
const INK=Color("#112430")
const DARK=Color("#263d49")
const METAL=Color("#577176")
const STEEL=Color("#819591")
const MINT=Color("#8debc8")
const GOLD=Color("#ffc97c")
const HOT=Color("#ff987d")
const WHITE=Color("#ece9cd")
const ACCENTS={1:"#ce9d75",3:"#8baaaa",4:"#899d9e",6:"#a0c6c1",7:"#bc967b",9:"#aeb69d",10:"#c29672",12:"#a49fac",13:"#c19e83",15:"#d2ae86"}
var stage
var sky_tex:Texture2D
var loaded_chapter=-1
var calm=false
var accent=GOLD
var shift=Vector2.ZERO

func box(x,y,w,h,c):
	draw_rect(Rect2(roundf(x),roundf(y),roundf(w),roundf(h)),c)

func stroke(points:PackedVector2Array,c,width=1):
	draw_polyline(points,c,width,false)

func text(p:Vector2,s:String,c:Color,size=12):
	draw_string(FONT,p.round(),s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,c)

func label(p:Vector2,s:String,c:Color):
	var width=ceilf(FONT.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)
	var x=clampf(roundf(p.x-width*.5),3,637-width)
	box(x-3,p.y-12,width+6,15,Color("#112731ed"))
	box(x-3,p.y-12,2,15,c)
	text(Vector2(x,p.y),s,c)

func background():
	if stage.chapter!=loaded_chapter:
		loaded_chapter=stage.chapter
		sky_tex=load("res://assets/world/height_%02d.png"%stage.chapter)
		accent=Color(ACCENTS[stage.chapter])
	var offset=-roundf(12+posmod(stage.room*17+stage.chapter*9,94)+stage.hero.pos.x*.025)
	if sky_tex: draw_texture(sky_tex,Vector2(offset,0),Color.WHITE)
	# Grounded wiring and cables visually support the upper work decks.
	for i in range(3):
		var pts=PackedVector2Array()
		var x=-145+i*298+stage.room*5
		var y=22+posmod(stage.room*7+i*9,21)
		for j in range(19):
			var f=j/18.0
			pts.append(Vector2(roundf(x+f*314),roundf(y+f*10+4*52*f*(1-f))))
		stroke(pts,Color("#334855"),2)
		for j in [4,13]:
			var at=pts[j]
			box(at.x-1,at.y,2,6,DARK)
			box(at.x-3,at.y+5,6,3,accent.darkened(.24))
			box(at.x-2,at.y+8,4,1,Color("#c9bf96"))
	if calm: return
	for i in range(25):
		var x=fposmod(i*137.0-stage.clock*(21+i%5),664)-9
		var y=fposmod(i*79.0+stage.clock*(112+i%13*3),384)-8
		draw_line(Vector2(roundf(x),roundf(y)),Vector2(roundf(x)-1,roundf(y)+4+i%4),Color(.66,.78,.79,.19),1,false)

func floor_block(r:Rect2):
	var x=r.position.x
	var y=r.position.y
	var w=r.size.x
	box(x,y,w,r.size.y,INK)
	box(x+2,y+8,w-4,r.size.y-8,Color("#334954"))
	for i in range(int(x)+3,int(r.end.x)-8,43):
		box(i,y+14,34,24,Color("#405660"))
		box(i+2,y+16,30,20,Color("#354b55"))
		box(i+2,y+16,30,1,Color("#576d72"))
		box(i+3,y+17,2,1,STEEL)
		box(i+30,y+34,2,1,STEEL)
		if posmod(i,3)==0:
			for j in range(3):box(i+8,y+21+j*4,16,2,INK)
	box(x,y+4,w,4,accent.darkened(.4))
	box(x,y+1,w,3,STEEL)
	box(x,y,w,1,Color("#c1c5ad"))
	for i in range(int(x)+4,int(r.end.x)-2,8):
		box(i,y+2,4,1,Color("#586f73"))
	# Safety markings are confined to the actual edge of the drop.
	var left_edge=x>0
	var edge=x+2 if left_edge else r.end.x-24
	for j in range(3):
		var ex=edge+j*7
		draw_colored_polygon([Vector2(ex,y+5),Vector2(ex+3,y+5),Vector2(ex+6,y+9),Vector2(ex+3,y+9)],GOLD)

func steel_deck(r:Rect2,k:int):
	var x=r.position.x
	var y=r.position.y
	var w=r.size.x
	# Background handrail is narrow and muted to preserve one-way collision cues.
	var rail=Color("#566b6d")
	for i in range(int(x)+9,int(r.end.x)-3,35):
		box(i,y-16,2,16,rail)
		box(i,y-16,2,2,STEEL)
	box(x+8,y-16,w-17,1,rail)
	box(x+8,y-9,w-17,1,Color("#465d63"))
	# Main girders have a continuous, brighter walking surface and an open web.
	box(x,y,w,3,Color("#aeb6a6"))
	box(x,y+3,w,4,accent.darkened(.26))
	box(x+2,y+7,w-4,4,Color("#354b56"))
	box(x+1,y+10,w-2,3,INK)
	for i in range(int(x)+3,int(r.end.x)-5,9):
		box(i,y+1,5,1,Color("#5b7276"))
	for i in range(int(x)+5,int(r.end.x)-8,20):
		box(i,y+5,2,1,Color("#b7b6a0"))
	# Cross braces leave genuine negative space below each platform.
	var deep=11 if k%2==0 else 8
	for i in range(int(x)+6,int(r.end.x)-22,24):
		stroke([Vector2(i,y+12),Vector2(i+11,y+12+deep),Vector2(i+22,y+12)],Color("#425960"),2)
	box(x+7,y+12+deep,w-15,2,Color("#344b55"))
	for edge in [x,x+w-6]:
		box(edge,y,6,2,GOLD)
		box(edge+1,y+3,3,3,Color("#dcc08b"))

	if stage.chapter in [1,13]:
		for i in range(int(x)+3,int(r.end.x)-5,13):
			box(i,y+2,9,2,Color("#a6957a"))
			box(i+1,y+3,4 if i%2 else 6,1,Color("#6e7063"))
	elif stage.chapter==6:
		for i in range(int(x)+4,int(r.end.x)-7,19):
			box(i,y-1,8,2,Color("#c0d8cc"))
			stroke([Vector2(i+3,y+1),Vector2(i+4,y+6+(i%3))],Color("#94b7b3"))
	elif stage.chapter in [10,12]:
		for i in range(int(x)+5,int(r.end.x)-7,13):
			stroke([Vector2(i,y+6),Vector2(i+3,y+3)],accent,2)
	elif stage.chapter==7:
		stroke([Vector2(x+3,y+13+deep),Vector2(x+w-7,y+13+deep)],accent.darkened(.45))

func door(p:Vector2,exit:bool):
	var open=exit and stage.target>=stage.nodes.size()
	var x=p.x-16
	var y=p.y-54
	box(x-3,y+3,39,49,INK)
	box(x,y,32,54,METAL)
	box(x+2,y+2,28,50,STEEL)
	box(x+4,y+3,24,49,INK)
	if open:
		box(x+5,y+4,5,47,Color("#5b847e"))
		box(x+6,y+4,1,46,MINT)
		box(x+10,y+49,17,2,Color("#6fa393"))
		var c=MINT
		stroke([p+Vector2(-4,-32),p+Vector2(4,-26),p+Vector2(-4,-20)],c,2)
	else:
		box(x+5,y+4,22,47,Color("#4a6268"))
		box(x+7,y+7,18,12,Color("#81988f"))
		for i in range(3):box(x+7+i*6,y+7,2,12,Color("#50686d"))
		box(x+8,y+24,15,2,Color("#6c8480"))
		box(x+7,y+32,15,2,DARK)
		box(x+19,y+28,5,3,accent)
	box(x+4,y-5,25,5,INK)
	box(x+7,y-3,18,2,MINT if open else accent)
	box(x-4,p.y-1,40,2,Color("#d2c3a1"))
	if open: label(p-Vector2(0,66),("A" if stage.game.pad else "E")+" 出口",MINT)

func flash_band(p:Vector2,radius:int,t:float,col:Color):
	var span=roundi(radius*clampf(t,0,1))
	box(p.x-span,p.y-2,span*2+1,4,Color(col,.15))
	box(p.x-span,p.y-2,2,4,col);box(p.x+span-1,p.y-2,2,4,col)

func hazard(h):
	var r:Rect2=h.rect
	var x=r.position.x
	var y=r.position.y
	var w=r.size.x
	var clock=fmod(stage.clock+h.phase,3.5)
	var live=stage.danger_on(h)
	var warning=clock>2.08 and not live
	var col=HOT if live else (GOLD if warning else Color("#7b9796"))
	box(x-2,y+3,w+4,5,INK);box(x,y+4,w,2,METAL)
	for i in range(int(x)+2,int(x+w)-1,6):
		box(i,y,3,6,Color("#455e69"))
		box(i,y,3,2,col)
	if warning:
		box(x,y-3,w*clampf((clock-2.08)/.78,0,1),1,GOLD)
	if live:
		box(x-2,y-3,w+4,r.size.y+5,Color(HOT,.22))
		var pts=PackedVector2Array()
		for i in range(9):
			var wave=2+((i*5+(0 if calm else floori(stage.clock*19)))%6)
			pts.append(Vector2(roundf(x+i*w/8),roundf(y-((wave if i%2 else 0)))))
		stroke(pts,HOT,2);stroke(pts,WHITE)

func terminal(n,idx:int):
	var p:Vector2=n.p
	var active=idx==stage.target
	var col=MINT if n.done else (GOLD if active else Color("#698b8d"))
	var x=p.x
	var y=p.y
	match n.kind:
		"fuse":
			box(x-9,y-5,19,4,INK);box(x-7,y-9,15,4,STEEL)
			box(x-5,y-25,10,17,INK);box(x-3,y-22,6,11,Color("#6c9793"))
			box(x-2,y-20,2,8,col);box(x-6,y-26,12,4,STEEL);box(x-6,y-12,12,4,METAL)
		"socket":
			box(x-10,y-22,21,22,INK);box(x-8,y-20,17,17,METAL)
			box(x-6,y-18,12,10,DARK);box(x-4,y-16,3,5,col);box(x+1,y-16,3,5,col)
			box(x-7,y-4,13,2,STEEL)
		"lever":
			box(x-11,y-16,22,16,INK);box(x-9,y-14,18,10,METAL)
			draw_line(p-Vector2(0,9),p+Vector2(-6 if n.done else 7,-25),INK,5)
			draw_line(p-Vector2(0,9),p+Vector2(-6 if n.done else 7,-25),col,2)
			box(x+(-10 if n.done else 3),y-28,9,4,col);box(x-2,y-10,4,4,STEEL)
		"lock":
			box(x-11,y-23,23,22,INK);box(x-9,y-20,19,16,Color("#836952") if not n.done else METAL)
			stroke([p+Vector2(-6,-22),p+Vector2(-6,-31),p+Vector2(-3,-34),p+Vector2(5,-34),p+Vector2(7,-31),p+Vector2(7,-24 if not n.done else -28)],STEEL,3)
			box(x-3,y-17,7,7,col);box(x-1,y-14,3,6,INK)
		"drone":
			var wave=fmod(stage.clock+stage.room*.8,3.4)
			if active and wave>2.21:
				flash_band(p,57,clampf((wave-2.21)/.71,.12,1),HOT if wave>2.92 else GOLD)
			var bob=0 if calm else roundi(2.7*sin(stage.clock*3.0))
			var cy=y-30+bob if not n.done else y-4
			draw_colored_polygon([Vector2(x-11,cy-1),Vector2(x-7,cy-7),Vector2(x+5,cy-7),Vector2(x+12,cy-1),Vector2(x+7,cy+5),Vector2(x-7,cy+5)],INK)
			box(x-7,cy-4,15,6,METAL);box(x-3,cy-2,8,3,HOT if active else col)
			for side in [-1,1]:
				var sx=x+side*13
				draw_line(Vector2(x+side*7,cy-1),Vector2(sx,cy-5),STEEL,2)
				box(sx-6,cy-7,13,2,DARK)
				box(sx-5+(0 if calm else floori(stage.clock*12)%3),cy-8,8,1,STEEL)
	if n.done:
		stroke([p+Vector2(-4,-13),p+Vector2(-1,-10),p+Vector2(4,-16)],MINT,2)

func active_cue():
	if stage.target>=stage.nodes.size(): return
	var n=stage.nodes[stage.target]
	var p:Vector2=n.p
	var float_y=0 if calm else roundi(sin(stage.clock*4)*2)
	var high=46 if n.kind in ["lock","drone"] else 37
	var near=stage.near(p)
	if near: high=72
	var marker=p+Vector2(0,-high+float_y)
	draw_colored_polygon([marker+Vector2(-4,-3),marker+Vector2(4,-3),marker+Vector2(0,1)],GOLD)
	if near:
		var key={"fuse":"A" if stage.game.pad else "E","socket":"A" if stage.game.pad else "E","lever":"A" if stage.game.pad else "E","lock":"Y" if stage.game.pad else "K","drone":"X / Y" if stage.game.pad else "J / K"}[n.kind]
		label(marker-Vector2(0,8),key,GOLD)

func player():
	var h=stage.hero
	var p=h.pos.round()
	var anim=h.state
	var frame=h.frame_id()
	if not stage.grounded and anim not in ["jab","heavy","skill"]:
		anim="leap"
		frame=clampi(floori((stage.vy+251)/100),0,5)
	var tex:Texture2D=h.texture_for(anim)
	if not tex:
		tex=h.texture_for("dodge" if anim=="leap" else "idle")
		frame=clampi(frame,0,5)
	if not tex: return
	var color=Color.WHITE
	if stage.shield>0 and stage.feedback_time>.2 and stage.feedback in ["绝缘受损","安全绳已回收"]:
		color=Color(1.35,1.03,.9,1.0 if calm else (.64 if floori(stage.clock*8)%2==0 else 1.0))
	if stage.grounded:
		box(p.x-11,p.y-1,22,2,Color(INK,.53))
	draw_set_transform(p+shift,0,Vector2(h.face,1))
	draw_texture_rect_region(tex,Rect2(-48,-80,96,88),Rect2(frame*96,0,96,88),color)
	draw_set_transform(shift)
	if h.state in ["jab","heavy","skill"] and h.time>.32*h.length and h.time<.67*h.length:
		var f=clampf((h.time/h.length-.32)/.35,0,1)
		if h.state=="skill":
			for j in range(12):
				var ang=j*TAU/12
				var normal=Vector2(cos(ang),sin(ang)*.43)
				draw_line((p+Vector2(0,-30)+normal*(23+f*63)).round(),(p+Vector2(0,-30)+normal*(32+f*65)).round(),Color(MINT,1.0-f*.6),2)
		else:
			var org=p+Vector2(h.face*(34 if h.state=="jab" else 39),-30)
			stroke([org+Vector2(-h.face*4,-8),org+Vector2(h.face*4,-3),org+Vector2(h.face*7,3),org+Vector2(h.face*6,7)],Color(WHITE,.88-f*.55),2)
func hud():
	var title=stage.ROUTES[stage.chapter][0]
	var right_text="%s   %02d / %02d"%[stage.room_name,stage.room+1,stage.room_count]
	var right_w=ceilf(FONT.get_string_size(right_text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)+18
	box(8,7,170,41,Color("#112430ed"))
	box(8,7,3,41,MINT)
	text(Vector2(16,21),title,WHITE,12)
	for i in range(4):
		box(16+i*13,27,11,5,Color("#40545c"))
		if i<stage.hp: box(17+i*13,28,9,3,GOLD)
	box(72,28,93,3,Color("#415c63"))
	box(72,28,93*stage.energy/100.0,3,MINT)
	box(72+93*.4,27,1,5,INK)
	var jumps_left=2 if stage.grounded else maxi(0,2-stage.jumps)
	for i in range(2):
		var xx=18+i*10
		stroke([Vector2(xx,43),Vector2(xx+3,39),Vector2(xx+6,43)],MINT if i<jumps_left else METAL)
	text(Vector2(42,45),"空中余跳",Color("#a6c2b4"),10)
	text(Vector2(108,45),"频能 %02d"%roundi(stage.energy),Color("#a6c2b4"),10)
	box(632-right_w,7,right_w,21,Color("#112430ef"))
	text(Vector2(640-right_w,22),right_text,WHITE)
	var nodes_n=stage.nodes.size()
	for i in range(nodes_n):
		var xx=630-((nodes_n-i)*15)
		box(xx,32,13,4,Color("#2c4752"))
		box(xx+1,33,11,2,MINT if i<stage.target else (GOLD if i==stage.target else METAL))
	box(0,336,640,24,Color("#0f242ef8"))
	box(0,336,640,1,Color("#48646a"))
	var counter="接点 %d / %d"%[stage.target,nodes_n]
	text(Vector2(9,352),counter,MINT)
	box(78,343,1,11,Color("#516970"))
	text(Vector2(87,352),stage.hint,WHITE)
	var jump="B / 摇杆↑  二段跳" if stage.game.pad else "↑ / 空格  二段跳"
	var kw=FONT.get_string_size(jump,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	text(Vector2(630-kw,352),jump,Color("#a9c3b8"))
	if stage.feedback_time>0:
		var msg=stage.feedback
		label(Vector2(320,48),msg,HOT if msg in ["安全绳已回收","绝缘受损"] else MINT)
	elif stage.room_pulse>.65:
		label(Vector2(320,51),stage.room_name,accent)

func _draw():
	if not stage or not stage.hero: return
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	calm=stage.game.prefs.calm
	shift=Vector2.ZERO
	if stage.game.prefs.tremor and not calm and stage.feedback_time>.87 and stage.feedback in ["绝缘受损","安全绳已回收"]:
		shift=Vector2(roundf(sin(stage.clock*112)*2),roundf(cos(stage.clock*85)))
	draw_set_transform(shift)
	background()
	for i in stage.platforms.size():
		var r:Rect2=stage.platforms[i]
		if r.size.y>40: floor_block(r)
		else: steel_deck(r,i)
	door(Vector2(24,294),false)
	door(stage.exit_pos,true)
	for h in stage.hazards: hazard(h)
	for i in stage.nodes.size(): terminal(stage.nodes[i],i)
	player()
	active_cue()
	for fx in stage.particles:
		var p:Vector2=fx.p
		var tail=(p-fx.v*.04).round()
		draw_line(tail,p.round(),Color(fx.c,clampf(fx.t*4,0,1)),2)
	draw_set_transform(Vector2.ZERO)
	hud()
