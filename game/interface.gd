extends Node2D
const Book=preload("res://game/campaign.gd")
const Signals=preload("res://game/broadcasts.gd")
const FONT=preload("res://assets/fonts/FusionPixel.ttf")
const INK=Color("#091923")
const PANEL=Color("#102733")
const LINE=Color("#31505a")
const PALE=Color("#f3ebd5")
const DIM=Color("#a1b5b1")
const MINT=Color("#74daca")
const OCHRE=Color("#f8c46b")
const CORAL=Color("#ff997e")
const W=640
const H=360
var game
var buttons=[]
var portraits
var title_art
var backdrop_cache={}
var art_time=0.0
func _ready():
	if ResourceLoader.exists("res://assets/world/portraits.png"): portraits=load("res://assets/world/portraits.png")
	if ResourceLoader.exists("res://assets/world/title.png"): title_art=load("res://assets/world/title.png")
func box(x,y,w,h,c):
	draw_rect(Rect2(roundf(x),roundf(y),roundf(w),roundf(h)),c)
func rule(x,y,w,c=LINE): box(x,y,w,1,c)
func txt(s,x,y,size:=12,col:=PALE):
	draw_string(FONT,Vector2(roundf(x),roundf(y)),str(s),HORIZONTAL_ALIGNMENT_LEFT,-1,size,col)
func right(s,x,y,size:=12,col:=PALE):
	txt(s,x-FONT.get_string_size(str(s),HORIZONTAL_ALIGNMENT_LEFT,-1,size).x,y,size,col)
func center(s,x,y,size:=12,col:=PALE):
	txt(s,x-FONT.get_string_size(str(s),HORIZONTAL_ALIGNMENT_LEFT,-1,size).x/2.0,y,size,col)
func paragraph(s:String,x:int,y:int,width:int,col:=PALE,size:=12,leading:=18):
	var pen=y
	for block in s.split("\n"):
		var remaining=block
		while FONT.get_string_size(remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x>width:
			var maximum=1
			while maximum<remaining.length() and FONT.get_string_size(remaining.substr(0,maximum+1),HORIZONTAL_ALIGNMENT_LEFT,-1,size).x<=width:
				maximum+=1
			var cut=maximum
			var ideal=maximum if remaining.length()>maximum*2 else int(ceil(remaining.length()/2.0))
			var best_dist=999
			for i in range(maxi(2,ideal/2),maximum+1):
				if remaining[i-1] in ["。","，","！","？","、","…"," ","·"]:
					var dist=absi(i-ideal)
					if dist<best_dist:
						best_dist=dist
						cut=i
			if cut<remaining.length() and remaining[cut] in ["。","，","！","？","」","》","、"]: cut=maxi(1,cut-1)
			txt(remaining.substr(0,cut),x,pen,size,col)
			remaining=remaining.substr(cut).strip_edges()
			pen+=leading
		txt(remaining,x,pen,size,col)
		pen+=leading
	return pen-leading
func tag(s,x,y,col:=MINT):
	var width=FONT.get_string_size(s,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+12
	box(x,y-12,width,15,col)
	txt(s,x+6,y,12,INK)
	return width
func wave(x,y,w,h,col,seed_val:=0.0):
	var t=game.real_time if not game.prefs.calm else 1.0
	for i in range(0,int(w),4):
		var v=absf(sin(i*1.73+seed_val+t*1.9)*cos(i*0.14-t*0.65))
		var bar=2+floorf(v*h)
		box(x+i,y-floorf(bar/2),2,bar,col)
func cassette(x,y,w,h,number,lit):
	var c=MINT if lit else LINE
	box(x,y,w,h,INK)
	draw_rect(Rect2(x,y,w,h),c,false,2)
	box(x+5,y+5,w-10,h*0.47,c)
	for i in 4: box(x+8+i*4,y+8,2,h*0.28,INK)
	right("B / %02d"%number,x+w-8,y+17,12,INK)
	box(x+9,y+h*0.55,w-18,h*0.27,LINE)
	for gx in [x+19,x+w-20]:
		draw_circle(Vector2(gx,y+h*0.68),5,c)
		box(gx-2,y+h*0.68-2,4,4,INK)
func hit(p:Vector2)->int:
	for i in buttons.size():
		if buttons[i].has_point(p): return i
	return -1
func element(i:int,r:Rect2,s:String,small:=false,locked:=false):
	while buttons.size()<=i: buttons.append(Rect2())
	buttons[i]=r
	var sel=game.cursor==i
	var color=OCHRE if sel else (Color("#12242eea") if not small else Color("#12242eb0"))
	draw_rect(r,color)
	if sel:
		box(r.position.x,r.position.y,3,r.size.y,PALE)
	else:
		rule(r.position.x,r.end.y-1,r.size.x,LINE)
	var c=INK if sel else (Color("#778c91") if locked else PALE)
	txt(s,r.position.x+11,r.position.y+floorf((r.size.y+10)/2.0)-1,12,c)
	if sel: right(">",r.end.x-7,r.position.y+floorf((r.size.y+10)/2.0)-1,12,INK)
func _draw():
	if not game: return
	buttons.clear()
	art_time=game.real_time
	match game.mode:
		"title": draw_title()
		"story": draw_story()
		"play","memory": draw_hud()
		"memory_intro","memory_outro": draw_tape_scene()
		"pause","fail","options","manual","confirm","newgame":
			draw_panel()
		"chapters","archive","record": draw_library()
		"results","broadcast","ending","credits": draw_closing()
	if game.transition>0:
		box(0,0,W,H,Color(0.02,0.05,0.07,game.transition*0.75))
func cover():
	if title_art: draw_texture(title_art,Vector2.ZERO)
	else: box(0,0,W,H,INK)
func studio_bar():
	box(0,0,W,22,Color("#0a1922ea"))
	box(14,8,5,5,MINT)
	txt("PUBLIC SERVICE BAND",26,15,12,DIM)
	right("港湾公用频段    /    FM 87.6",626,15,12,MINT)
func footer(text:String):
	box(0,337,W,23,Color("#08151ff2"))
	rule(0,337,W,LINE)
	txt(text,16,353,12,DIM)
	right("87.6  ◇",625,353,12,MINT)
func menukeys():
	return "方向键 / WASD  选择      回车  确认      ESC  返回" if not game.pad else "方向键 / 左摇杆  选择      A  确认      B  返回"
func draw_title():
	cover()
	if not game.prefs.calm:
		for i in range(28):
			var speed=66+i%7*11
			var x=fposmod(281+i*71-art_time*speed*0.18,682)-20
			var y=fposmod(i*47+art_time*speed,382)-8
			draw_line(Vector2(x,y).round(),Vector2(x-1,y+4+i%3).round(),Color(0.69,0.85,0.85,0.18),1,false)
		var glow=clampf(sin(art_time*1.6)*2.6,0,1)
		box(556,7,2,2,Color(1.0,0.5,0.36,glow))
	for i in 32:
		box(i*10,22,10,315,Color(0.02,0.065,0.09,0.69*(1.0-i/33.0)))
	studio_bar()
	txt("港湾夜间播送",24,48,12,MINT)
	rule(109,43,98,Color("#678785"))
	txt("逆潮电台",23,101,48,Color("#11222d"))
	txt("逆潮电台",21,97,48,PALE)
	txt("UNDERTOW",24,125,24,OCHRE)
	var x=24+FONT.get_string_size("UNDERTOW",HORIZONTAL_ALIGNMENT_LEFT,-1,24).x+7
	box(x,107,34,20,OCHRE)
	center("FM",x+17,123,18,INK)
	wave(x+43,117,41,13,MINT)
	var a=game.items()
	var first=145 if a.size()==7 else 153
	for i in a.size():
		var label=a[i][1]
		if a[i][0]=="continue": label+="    /    "+Book.PLACES[game.prefs.chapter][0]
		element(i,Rect2(24,first+i*23,182,21),label,true)
	right("AM  00:07",620,310,12,PALE)
	right("海岬港  /  风暴夜",620,326,12,DIM)
	footer(menukeys())
func art_scene():
	if game.arena.visible: return
	cover()
	box(0,0,W,H,Color("#081720c9"))
func draw_panel():
	art_scene()
	box(0,0,W,H,Color("#07131ec7"))
	var m=game.mode
	var title={"newgame":"选择难度","pause":"暂停播送","fail":"信号中断","options":"设备设置","manual":"操作手册","confirm":"确认操作"}[m]
	var subtitle={"newgame":"NEW ROUTE","pause":"STANDBY","fail":"SIGNAL LOST","options":"CONFIGURATION","manual":"FIELD GUIDE","confirm":"CONFIRM"}[m]
	var wide=m in ["options","manual"]
	var px=96 if wide else 142
	var pw=448 if wide else 356
	box(px,40,pw,273,INK)
	rule(px,40,pw,MINT if m!="fail" else CORAL)
	tag(subtitle,px+18,65,MINT if m!="fail" else CORAL)
	txt(title,px+18,99,24,PALE)
	rule(px+18,108,pw-36)
	var a=game.items()
	if m=="manual":
		var pages=[
			[["移动","WASD / 方向键","左摇杆 / 十字键"],["轻拳 / 重踢","J / K","X / Y"],["闪避 / 频能脉冲","空格 / L","B / RB"],["接入 / 暂停","E / Esc","A / Start"]],
			[["街战","盾卫只能在正面格挡。重踢能击穿盾牌。",""],["追拳","第三站起，滑步后立即出拳可突进。",""],["连踢","第七站起，两拳接一踢能打出更重的踵击。",""],["回声","第十一站起，精准闪避可小幅回血。",""]],
			[["跳跃 / 二段跳","W、↑ 或空格，再按一次","↑ 或 B，再按一次"],["穿过脚手板","按住 S 或 ↓，再按空格","↓ + B"],["修复 / 重击","E / K","A / Y"],["安全绳","失足会返回最近的安全接点。",""]],
			[["移动光标","WASD / 方向键","左摇杆 / 十字键"],["转动铜线","E 顺时针，K 逆时针","A 顺时针，Y 逆时针"],["检查","沿亮起的线路确认通到每座接收站。",""],["故事难度提示","J 标出下一块可调整的铜线。","X"]]]
		var pg=game.manual_page
		for i in 4:
			var row=pages[pg][i]
			var yy=130+i*23
			txt(row[0],px+18,yy,12,DIM)
			txt(row[1],px+117,yy)
			txt(row[2],px+300,yy,12,MINT)
		var note=["三记轻拳形成连段。命中与精准闪避均可蓄能，消耗 40 频能可震退近处的多名敌人。","地面预警标出攻击范围。绕向敌人后侧，或等其出手时闪避，可以制造反击机会。","找到亮起的设备。黄黑条纹指示泄放带，电弧亮起时跳过它。所有设备接通后，从右侧出口离开。","带电线缆绘为双线。旋转模块，沿连续通路将左侧发射机连接到右侧所有端子。"][pg]
		paragraph(note,px+18,231,pw-36,DIM)
		for i in 3: element(i,Rect2(px+18+i*106,272,96,22),a[i][1])
		right("%d / 4"%(pg+1),px+pw-18,287,12,MINT)
	elif m=="options":
		for i in a.size():
			element(i,Rect2(px+18,118+i*25,pw-36,22),a[i][1])
			if i==a.size()-1: break
			var v=game.prefs.get(a[i][0])
			var val=str(int(v)*10)+" %" if i<2 else (["故事","街机","暴潮"][int(v)] if i==2 else ("开" if v else "关"))
			right("<   "+val+"   >",px+pw-40,133+i*25,12,INK if game.cursor==i else MINT)
	elif m=="confirm":
		paragraph(game.confirm_text,px+20,144,pw-41)
		for i in a.size(): element(i,Rect2(px+18+i*150,238,137,28),a[i][1])
	else:
		var yy=122
		if m=="fail":
			txt("本段已有接力记录。",px+18,137,12,DIM)
			yy=155
		if m=="newgame":
			txt("可在暂停菜单中随时调整。",px+18,136,12,DIM)
			yy=150
		for i in a.size(): element(i,Rect2(px+18,yy+i*29,pw-36,26),a[i][1])
	footer(menukeys())
func draw_story():
	var a=game.arena
	var place=Book.PLACES[a.chapter]
	box(0,0,W,28,INK)
	box(0,185,W,175,Color("#071822ed"))
	rule(0,185,W,OCHRE)
	txt("沿岸接力   /   第 %02d 站"%a.chapter,18,18,12,MINT)
	right("港内时间   "+place[3],622,18,12,PALE)
	tag("CH. %02d"%a.chapter,20,212,OCHRE)
	txt(place[0],86,213,24,PALE)
	right(place[2],620,211,12,DIM)
	rule(20,225,600)
	var line=game.story_line
	var speaker="现场记录" if line==0 else (place[5] if line==1 else place[7])
	var inset=22
	if line>0 and portraits:
		var portrait_row=0 if line==2 else a.chapter+1
		box(21,232,74,76,Color("#15323b"))
		draw_texture_rect_region(portraits,Rect2(26,236,64,68),Rect2(64*(int(game.story_age*5)%2 if game.story_age<2.3 and not game.prefs.calm else 0),portrait_row*68,64,68))
		rule(21,308,74,MINT)
		inset=108
	txt(speaker,inset,248,12,MINT)
	var body=place[4] if line==0 else (place[6] if line==1 else place[8])
	paragraph(body,inset,272,616-inset,PALE,24,25)
	for i in 3: box(22+i*15,326,11,2,OCHRE if i<=line else LINE)
	right("A  继续     START  跳过" if game.pad else "回车  继续     ESC  跳过",619,342,12,DIM)
func meter(x,y,w,h,value,maxv,fill):
	box(x,y,w,h,Color("#233c47"))
	box(x,y,w*clampf(float(value)/float(maxv),0,1),h,fill)
func draw_hud():
	var a=game.arena
	var p=a.hero
	if not p: return
	box(10,8,172,43,Color("#0a1a25ea"))
	box(10,8,3,43,OCHRE)
	txt("阿烈" if a.memory_mode else "阿沅",19,23,12,OCHRE)
	txt("LIE" if a.memory_mode else "YUAN",53,22,12,DIM)
	right("%03d"%p.hp,174,22,12,PALE)
	meter(19,27,155,8,p.hp,100,CORAL if p.hp<27 else OCHRE)
	meter(19,39,155,4,a.flux,100,MINT)
	for i in [40,80]: box(19+155*i/100.0,39,1,4,INK)
	if a.combo>=2 and a.combo_timer>0:
		txt("%02d"%a.combo,17,77,24,OCHRE)
		txt("连击",50,75,12,PALE)
	var stage=Book.PLACES[a.chapter]
	var top="CH.%02d   %s"%[a.chapter,stage[0]]
	if a.memory_mode: top="A 面    "+a.memoryrun.SITES[a.memory_index][a.memoryrun.room]
	var tw=FONT.get_string_size(top,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+18
	box(630-tw,8,tw,20,Color("#0a1a25ea"))
	right(top,621,23,12,PALE)
	var target=a.last_target
	if a.kind=="boss" and not a.done:
		for e in a.enemies:
			if e.kind=="boss": target=e
	if target and ((a.last_target_time>0 and target.alive()) or (a.kind=="boss" and not a.done)):
		var name_tag=target.role if target.role!="" else Book.TYPE_NAMES[target.kind]
		box(480,34,150,25,Color("#0a1a25e6"))
		right(name_tag,622,47,12,CORAL)
		meter(488,51,134,4,target.hp,target.max_hp,CORAL)
	if not a.memory_mode and a.phase_help>3 and a.chapter>0 and a.wave_timer<=0 and a.radio_left<=0:
		var loc=Signals.BLOCKS[a.chapter][a.section]
		center(loc,320,29,12,PALE)
	if a.radio_left>0 and a.tip_timer<=0 and not a.done:
		var width=clampf(FONT.get_string_size(a.radio_text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+58,198,555)
		box(320-width/2,78,width,28,Color("#0c222ceb"))
		box(320-width/2,78,2,28,MINT)
		if portraits:
			draw_texture_rect_region(portraits,Rect2(324-width/2,78,27,28),Rect2(64*(0 if game.prefs.calm else int(a.clock*4)%2),68*(a.chapter+1),64,68))
		txt(a.radio_text,355-width/2,96,12,PALE)
	if a.wave_timer>0 and not a.done:
		var bw=FONT.get_string_size(a.wave_banner,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+22
		var banner_y=54 if a.radio_left>0 or a.tip_timer>0 else 66
		box(320-bw/2,banner_y,bw,20,Color("#0b202bf2"))
		center(a.wave_banner,320,banner_y+15,12,OCHRE)
	if a.save_message>0 and a.chapter>0:
		right("◆  接力点",622,78,12,MINT)
	# Reserve the bottom strip for task information, below the fighter silhouettes.
	box(0,337,640,23,Color("#081823f5"))
	rule(0,337,640,LINE)
	var prefix="校频 %d/6"%(a.lesson+1) if a.chapter==0 else "%02d / 06"%(a.section+1)
	if a.memory_mode: prefix="往事 %d/4"%(a.memoryrun.room+1)
	box(0,338,66,22,OCHRE if not a.done else MINT)
	center(prefix,33,353,12,INK)
	var msg=a.briefing() if not a.done else ("接点已接通" if a.section==5 or a.chapter==0 else "接点已接通 · 沿箭头前往下一段")
	txt(msg,74,353,12,PALE)
	var end=""
	if a.chapter>0 and not a.done:
		match a.kind:
			"relay","escort":
				var v=roundi(100*a.progress/a.goal)
				meter(510,346,67,5,v,100,MINT)
				end="%d%%"%v
			"haul": end="%d/3"%a.cargo_count
			"tune","rescue": end="%d/3"%a.spot_idx
			"fight","elite": end="队 %d/%d"%[a.wave,a.waves]
	if a.memory_mode: end="%d / 3"%(a.memoryrun.station+1)
	right(end,628,353,12,MINT)
	if a.tip_timer>0:
		var mw=FONT.get_string_size(a.tip,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x+21
		box(320-mw/2,80,mw,21,Color("#09202bee"))
		center(a.tip,320,95,12,MINT)
func draw_library():
	cover()
	box(0,0,W,H,Color("#071722ec"))
	studio_bar()
	var m=game.mode
	var is_archive=m=="archive"
	if m=="record":
		var loc=Book.PLACES[game.current_record]
		cassette(35,82,170,111,game.current_record,true)
		txt("现场磁带  /  SIDE B",36,224,12,MINT)
		txt("磁带 %02d"%game.current_record,244,77,12,MINT)
		txt(loc[9],244,120,24,OCHRE)
		rule(244,135,350)
		paragraph(loc[10],244,172,345,PALE,18,26)
		txt(loc[0]+"   /   "+loc[3],244,251,12,DIM)
		element(0,Rect2(245,280,105,26),"返回")
	else:
		var pg=game.archive_page if is_archive else game.chapter_page
		txt("声音档案" if is_archive else "章节重播",22,63,24,PALE)
		right("%02d / 16 卷"%game.prefs.records.size() if is_archive else "%02d / 16 站"%(game.prefs.unlock+1),620,61,12,MINT)
		rule(22,76,595)
		var a=game.items()
		for i in range(a.size()-3):
			var id=int(a[i][0])
			var unlocked=game.prefs.records.has(str(id)) if is_archive else id<=game.prefs.unlock
			var label="%02d     "%id+(a[i][1] if unlocked else ("未收录的频段" if is_archive else "未接通的站点"))
			element(i,Rect2(22,88+35*i,357,30),label,false,not unlocked)
			var data=Book.PLACES[id]
			right(data[0] if is_archive else data[3],361,108+35*i,12,INK if game.cursor==i else DIM)
		if game.cursor<a.size()-3:
			var id=int(a[game.cursor][0])
			var dat=Book.PLACES[id]
			cassette(424,100,143,88,id,game.prefs.records.has(str(id)) if is_archive else id<=game.prefs.unlock)
			center("FM 87.6   /   %02d"%id,496,211,12,MINT)
			var note="接近路边的琥珀色磁带，收录现场留下的声音。" if is_archive else "从本站开头重播，新的接力点会记录在本机。"
			paragraph(note,407,239,198,DIM)
		var start=a.size()-3
		element(start,Rect2(22,281,98,26),"<  上一页")
		element(start+1,Rect2(126,281,98,26),"下一页  >")
		txt("%d / 4"%(pg+1),244,298,12,DIM)
		element(start+2,Rect2(513,281,105,26),"返回")
	footer(menukeys())
func minutes(sec:float):
	return "%02d:%02d"%[int(sec)/60,int(sec)%60]
func draw_closing():
	var m=game.mode
	if m=="credits":
		cover()
		box(0,0,W,H,Color("#071722d9"))
		studio_bar()
		txt("制作名单",26,72,24,PALE)
		rule(26,86,585)
		txt("UNDERTOW FM",26,122,24,OCHRE)
		txt("原创像素角色、场景与逐帧动作",27,157)
		txt("原创电子配乐、合成音色与音效",27,180)
		txt("引擎  /  Godot Engine",27,211,12,MINT)
		txt("字体  /  缝合像素字体 · Fusion Pixel Font",27,233,12,MINT)
		txt("引擎与字体授权随发行包提供。",27,256,12,DIM)
		element(0,Rect2(27,287,131,26),"返回标题")
		footer("海岬港公用广播    /    结束播送")
		return
	if m=="ending":
		cover()
		box(0,0,W,H,Color("#0a1f28c7"))
		studio_bar()
		var idx=game.story_line
		var heads=["开放频段","全港回声","潮水退去"]
		var passages=[
			"阿沅先读了名字。每一个名字后面，都有一个声音回答「到了」。" if game.ending_order==0 else "阿沅先念潮位。一组，两组，三组。十二年前的删改记录也完整送进了每一台收音机。",
			"老岑接过话筒，从第一行开始读第二份记录。山顶体育馆的人把喇叭朝向港湾。清晨的第一班渡船循声靠岸。",
			"天亮后，修理铺开门了。阿沅把备用话筒放在窗边，在玻璃上写下：谁都可以来，说完再走。"]
		txt("清晨  05:46   /   播后记",24,82,12,MINT)
		txt(heads[idx],22,143,36,OCHRE)
		paragraph(passages[idx],25,185,533,PALE,18,27)
		element(0,Rect2(25,283,195,28),"继续收听" if idx<2 else "结束播送")
		footer("主线已完成    /    全部章节可重播")
		return
	box(0,0,W,H,Color("#06131cd9"))
	studio_bar()
	var a=game.arena
	if m=="broadcast":
		txt("总控室  /  麦克风已打开",28,70,12,MINT)
		txt("你先播哪一份记录？",26,120,24,PALE)
		paragraph("一份是漏报名单，一份是潮位原件。两份都会送出。这一次，由握着话筒的人决定开头。",28,163,543,DIM,18,24)
		for i in 2: element(i,Rect2(28,225+i*35,370,30),game.items()[i][1])
		footer("FM 87.6    /    正在直播")
		return
	txt("接力报告    /    CH.%02d"%a.chapter,26,70,12,MINT)
	txt(Book.PLACES[a.chapter][0]+"已接通",25,113,24,PALE)
	rule(26,130,586)
	var r=game.last_result
	txt(r.grade,37,217,72,OCHRE)
	txt("评级",44,240,12,DIM)
	for j in 4:
		var label=["段内得分","最高连击","击退人数","现场用时"][j]
		var value=[str(r.score),str(r.combo),str(r.ko),minutes(r.time)][j]
		var x=136+j*119
		txt(label,x,169,12,DIM)
		txt(value,x,201,24,MINT)
	if Signals.TECHNIQUES.has(a.chapter+1):
		var move=Signals.TECHNIQUES[a.chapter+1]
		txt("新技术   "+move[0]+"   /   "+move[1],27,256,12,OCHRE)
	var aitems=game.items()
	for i in aitems.size(): element(i,Rect2(26+180*i,275,166,29),aitems[i][1])
	footer("接力进度已保存在本机")

func draw_tape_scene():
	var memory=game.arena.memoryrun
	var intro=game.mode=="memory_intro"
	box(0,0,640,360,Color("#0b181adc"))
	tag("A 面   /   现场录音",25,62,OCHRE)
	right("十二年前   ◇   %02d / 05"%(memory.episode+1),615,61,12,DIM)
	rule(25,79,590,LINE)
	txt(memory.TITLES[memory.episode],24,131,36,PALE)
	txt("机务员 · 阿烈" if intro else "录音带尾",25,162,12,MINT)
	paragraph(memory.INTRO[memory.episode] if intro else memory.ENDINGS[memory.episode],25,197,585,PALE,24,25)
	element(0,Rect2(25,281,216,27),game.items()[0][1])
	footer("现场见证    /    记录未经剪辑")
