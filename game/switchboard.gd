extends Node2D
## A field engineer's patch bay. Every bank is a hand-routed, connected wiring tree.
signal finished
signal checkpoint_changed(state: Dictionary)

const FACE=preload("res://assets/fonts/FusionPixel.ttf")
const INK=Color("#091923")
const PANEL=Color("#112d35")
const TRACE=Color("#376164")
const COPPER=Color("#c78e63")
const MINT=Color("#7be5c7")
const PAPER=Color("#f4e8ce")
const DIM=Color("#a2b9af")
const GOLD=Color("#f8c56b")
const ALERT=Color("#f39677")
const DIRECTIONS=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const PORTS=[1,2,4,8]
const CALLS={2:"return_theatre",5:"return_salt",8:"return_customs",11:"return_ridge",14:"return_breakwater"}
const NAMES={
	2:["白鲸剧院","报幕员","票厅","后台","楼座"],
	5:["盐仓东廊","仓管婆婆","东廊","盐台","装卸棚"],
	8:["旧海关","老岑","查验屋","档案室","值守亭"],
	11:["西堤天线阵","接线员","天线室","山城台","体育馆"],
	14:["北防波堤","船老大","堤头","背风岗","避风棚"]
}
const RESPONSES={
	2:["售票口听清。手印还湿，他们刚从这儿走过。","后台的帘子开了。孩子们排成了一列。","最后一排也散场了。山上见，阿沅。"],
	5:["东廊有回音。水线已经越过墙上的刻度。","盐台抄下数字。我们把纸装进了油布袋。","装卸棚清点完毕。工人和原始记录一起走。"],
	8:["查验屋有三个人。请把铅笔给我。","档案室回答。名单背面还有一行字。","最后一处也报了名。这一次，一个都没漏。"],
	11:["天线室收到。铜线搭上了旧馈线。","山城台收到。体育馆在等下一声呼号。","折叠床都铺好了。让海边的人上来吧。"],
	14:["堤头的引灯亮了。第一队往高地走。","背风岗回了两声。雨里还能看清路。","队尾进棚。守灯的人也可以回家了。"]
}
# [columns, rows, source row, deterministic switch positions, authored traces].
# Each trace begins with its cell coordinate. Its last cell is a receiver.
const BANKS={
	2:[
		[4,3,1,3,["01 RURR"]],
		[5,3,1,7,["01 RURRDR","11 DRRR"]],
		[5,4,2,5,["02 RRUURR","12 DRRR","21 RRD"]]],
	5:[
		[5,3,1,1,["01 URRDRR","20 RR"]],
		[5,4,2,19,["02 RRURDR","12 DRRR","21 URR"]],
		[6,4,1,2,["01 RDRRURR","11 URRRR","32 DRR"]]],
	8:[
		[5,4,0,4,["00 RDDRURR","12 DRRR"]],
		[6,4,2,12,["02 RURRURR","21 DRRR","12 DRRRR"]],
		[6,5,3,1,["03 RUURRDRR","11 URRRR","21 RDDDRR"]]],
	11:[
		[6,4,2,13,["02 RRUURDRR","12 DRRRR"]],
		[6,5,1,6,["01 RDRRURR","22 DRDRR","31 URR"]],
		[7,5,3,14,["03 RUURRDRRR","11 URRRRR","32 DDRRR"]]],
	14:[
		[6,5,2,17,["02 RRDRUURR","23 DRRR","31 URR"]],
		[7,5,1,8,["01 RDDRURRRR","11 URRRRR","23 RDRRR"]],
		[7,5,3,15,["03 RURULURRDRRR","22 RDRURR","33 DRRR"]]]
}

var game
var chapter=2
var zone=0
var cols=0
var rows=0
var source_row=0
var exits=[]
var wire=[]
var ideal=[]
var fixed=[]
var turns=[]
var live={}
var receipts=[]
var open_ends=0
var cursor=0
var moves=0
var elapsed=0.0
var solved=false
var completed=false
var zone_time=0.0
var hint_idx=-1
var hint_age=0.0
var flash=0.0
var rotation_fx=-1
var rot_time=0.0
var note=""
var note_age=0.0
var held_dir=Vector2i.ZERO
var repeat_in=0.0
var grid_origin=Vector2i.ZERO
var cell=42

func setup(host,ch:int,saved:Dictionary={}):
	game=host
	chapter=ch
	if not BANKS.has(ch):
		push_error("Missing switchboard station %d"%ch)
		return
	zone=0
	moves=0
	elapsed=0.0
	completed=false
	if not saved.is_empty() and int(saved.get("chapter",-1))==ch:
		zone=clampi(int(saved.get("zone",0)),0,2)
		moves=maxi(int(saved.get("moves",0)),0)
		elapsed=maxf(float(saved.get("elapsed",0.0)),0.0)
	build_bank()
	if int(saved.get("chapter",-1))==ch and int(saved.get("zone",-1))==zone:
		var restoration=saved.get("rotations",[])
		if restoration is Array and restoration.size()==wire.size():
			for i in wire.size():
				if fixed[i] or ideal[i]==0: continue
				turns[i]=posmod(int(restoration[i]),4)
				wire[i]=spin(ideal[i],turns[i])
			cursor=clampi(int(saved.get("cursor",cursor)),0,wire.size()-1)
			reconnect()
	queue_redraw()

func checkpoint_state()->Dictionary:
	return {"chapter":chapter,"zone":zone,"rotations":turns.duplicate(),"cursor":cursor,"moves":moves,"elapsed":elapsed}

func spin(mask:int,count:int)->int:
	var shifted=mask
	for _i in posmod(count,4): shifted=((shifted<<1)&15)|((shifted>>3)&1)
	return shifted

func flat(p:Vector2i)->int: return p.x+p.y*cols
func inside(p:Vector2i)->bool: return p.x>=0 and p.y>=0 and p.x<cols and p.y<rows
func point(i:int)->Vector2i: return Vector2i(i%cols,floori(float(i)/cols))
func cell_rect(i:int)->Rect2:
	var xy=grid_origin+point(i)*cell
	return Rect2(xy,Vector2i(cell-1,cell-1))

func build_bank():
	var spec=BANKS[chapter][zone]
	cols=spec[0]
	rows=spec[1]
	source_row=spec[2]
	var salt=int(spec[3])
	exits=[]
	ideal=[]
	ideal.resize(cols*rows)
	ideal.fill(0)
	ideal[source_row*cols]=8
	for text in spec[4]:
		var fields=text.split(" ")
		var p=Vector2i(int(fields[0][0]),int(fields[0][1]))
		for cmd in fields[1]:
			var direction="URDL".find(cmd)
			var q=p+DIRECTIONS[direction]
			assert(inside(q))
			ideal[flat(p)]|=PORTS[direction]
			ideal[flat(q)]|=PORTS[(direction+2)%4]
			p=q
		assert(p.x==cols-1)
		ideal[flat(p)]|=2
		exits.append(p.y)
	wire=ideal.duplicate()
	turns=[]
	fixed=[]
	cursor=-1
	for i in wire.size():
		var p=point(i)
		var selector=posmod(19*p.x+11*p.y+7*p.x*p.y+salt*5+(p.x+salt)%3, 23)
		var bolted=wire[i]==0 or wire[i]==15 or selector%7==2
		if chapter==2 and zone==0: bolted=wire[i]==0 or i==flat(Vector2i(2,0))
		fixed.append(bolted)
		var count=0 if bolted else posmod(selector+salt+p.y,4)
		turns.append(count)
		wire[i]=spin(wire[i],count)
		if cursor==-1 and wire[i]!=0 and not bolted: cursor=i
	if cursor<0: cursor=source_row*cols
	var source=source_row*cols
	if not fixed[source]: cursor=source
	cell=mini(46,floori(221.0/rows))
	grid_origin=Vector2i(40+floori((344-cols*cell)/2.0),79+floori((209-rows*cell)/2.0))
	hint_idx=-1
	hint_age=0
	note_age=0
	zone_time=0
	rotation_fx=-1
	held_dir=Vector2i.ZERO
	solved=false
	reconnect()
	if solved:
		for i in wire.size():
			if not fixed[i] and spin(wire[i],1)!=wire[i]:
				turns[i]=(int(turns[i])+1)%4
				wire[i]=spin(wire[i],1)
				reconnect()
				if not solved: break

func reconnect():
	live.clear()
	receipts.clear()
	open_ends=0
	var root_idx=source_row*cols
	var stack=[]
	if wire[root_idx]&8:
		stack.append(root_idx)
		live[root_idx]=true
	else: open_ends=1
	while not stack.is_empty():
		var i=int(stack.pop_back())
		var p=point(i)
		for direction in 4:
			if not (int(wire[i])&PORTS[direction]): continue
			var q=p+DIRECTIONS[direction]
			if not inside(q):
				if direction==3 and p.x==0 and p.y==source_row: continue
				if direction==1 and p.x==cols-1 and exits.has(p.y):
					if not receipts.has(p.y): receipts.append(p.y)
				else: open_ends+=1
				continue
			var other=flat(q)
			if not (int(wire[other])&PORTS[(direction+2)%4]):
				open_ends+=1
			elif not live.has(other):
				live[other]=true
				stack.append(other)
	solved=receipts.size()==exits.size() and open_ends==0
	queue_redraw()

func enabled()->bool:
	return game!=null and not completed and is_visible_in_tree() and game.mode=="switchboard"

func _physics_process(dt):
	if not enabled(): return
	elapsed+=dt
	zone_time+=dt
	hint_age=maxf(0,hint_age-dt)
	note_age=maxf(0,note_age-dt)
	flash=maxf(0,flash-dt)
	rot_time=maxf(0,rot_time-dt)
	var raw=Input.get_vector("leftward","rightward","upward","downward")
	var dir=Vector2i.ZERO
	if maxf(absf(raw.x),absf(raw.y))>.48:
		dir=Vector2i(int(signf(raw.x)),0) if absf(raw.x)>=absf(raw.y) else Vector2i(0,int(signf(raw.y)))
	if dir==Vector2i.ZERO:
		held_dir=dir
		repeat_in=0
	elif not solved:
		repeat_in-=dt
		if dir!=held_dir or repeat_in<=0:
			var next=point(cursor)+dir
			if inside(next):
				cursor=flat(next)
				game.sound.fx("select",.24)
			repeat_in=.28 if dir!=held_dir else .105
			held_dir=dir
	queue_redraw()

func _input(event):
	if not enabled(): return
	if event is InputEventKey and event.echo: return
	if event is InputEventJoypadButton or event is InputEventJoypadMotion: game.pad=true
	elif event is InputEventKey or event is InputEventMouseButton: game.pad=false
	if event is InputEventMouseMotion:
		var idx=cell_at(event.position)
		if idx>=0 and not solved: cursor=idx
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index not in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]: return
		if solved and confirm_rect().has_point(event.position):
			advance()
		elif not solved and helper_rect().has_point(event.position) and game.prefs.difficulty==0:
			request_hint()
		else:
			var idx=cell_at(event.position)
			if idx<0 or solved: return
			cursor=idx
			rotate_piece(-1 if event.button_index==MOUSE_BUTTON_RIGHT else 1)
	elif event.is_action_pressed("use"):
		if solved: advance()
		else: rotate_piece(1)
	elif event.is_action_pressed("heavy") and not solved:
		rotate_piece(-1)
	elif event.is_action_pressed("jab") and not solved and game.prefs.difficulty==0:
		request_hint()
	else: return
	get_viewport().set_input_as_handled()

func cell_at(pos:Vector2)->int:
	var local=pos-Vector2(grid_origin)
	if local.x<0 or local.y<0: return -1
	var p=Vector2i(floori(local.x/cell),floori(local.y/cell))
	return flat(p) if inside(p) else -1

func rotate_piece(direction:int):
	if fixed[cursor]:
		note="这一块已铆接。" if wire[cursor]!=0 else "此处没有模块。"
		note_age=1.15
		game.sound.fx("guard",.23,1.48)
		return
	var previous=receipts.size()
	turns[cursor]=posmod(int(turns[cursor])+direction,4)
	wire[cursor]=spin(wire[cursor],direction)
	moves+=1
	rotation_fx=cursor
	rot_time=.13
	note_age=0
	if hint_idx==cursor: hint_age=0
	reconnect()
	if solved:
		flash=.75
		game.sound.fx(CALLS[chapter],.86,1.0+zone*.028)
	elif receipts.size()>previous:
		game.sound.fx("radio",.55,1.0+.045*receipts.size())
	else:
		game.sound.fx("select",.54,.74+zone*.065)
	checkpoint_changed.emit(checkpoint_state())

func advance():
	if zone==2:
		completed=true
		finished.emit()
	else:
		zone+=1
		game.sound.fx("confirm",.52)
		build_bank()
		checkpoint_changed.emit(checkpoint_state())

func request_hint():
	# Prefer a break reached by current from the transmitter.
	var best=-1
	var score=-INF
	for i in wire.size():
		if fixed[i] or wire[i]==ideal[i]: continue
		var p=point(i)
		var priority=30 if live.has(i) else 0
		for d in DIRECTIONS:
			if inside(p+d) and live.has(flat(p+d)): priority+=9
		if i==source_row*cols: priority+=45
		priority-=p.x
		if priority>score:
			best=i
			score=priority
	if best<0: return
	hint_idx=best
	cursor=best
	hint_age=4.0
	var clockwise=1
	while clockwise<4 and spin(wire[best],clockwise)!=ideal[best]: clockwise+=1
	note="标记模块逆转一次。" if clockwise==3 else "标记模块顺转%d次。"%clockwise
	note_age=4.0
	game.sound.fx("radio",.38,1.24)

func label(value,x,y,size=12,color=PAPER):
	draw_string(FACE,Vector2(roundf(x),roundf(y)),str(value),HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func rect(x,y,w,h,color):
	draw_rect(Rect2(roundf(x),roundf(y),roundf(w),roundf(h)),color)

func right_label(value,x,y,size=12,color=PAPER):
	label(value,x-FACE.get_string_size(str(value),HORIZONTAL_ALIGNMENT_LEFT,-1,size).x,y,size,color)

func wrapped(value,x,y,width,color=PAPER):
	var s=""
	for ch in value:
		if FACE.get_string_size(s+ch,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x>width and s!="":
			label(s,x,y,12,color)
			y+=16
			s=""
		s+=ch
	if s!="": label(s,x,y,12,color)

func screw(p):
	rect(p.x-3,p.y-2,6,4,INK)
	rect(p.x-2,p.y-3,4,6,INK)
	rect(p.x-2,p.y-1,4,2,TRACE)
	rect(p.x-1,p.y,2,1,COPPER)

func stroke(a,b,c,width=1):
	draw_line(Vector2(a).round(),Vector2(b).round(),c,width,false)

func border(r:Rect2,c,width=1):
	draw_rect(r,c,false,width)

func confirm_rect()->Rect2: return Rect2(444,272,174,27)
func helper_rect()->Rect2: return Rect2(444,272,174,27)

func draw_board():
	# Soldermask, silvered bus bars and an etched edge connector.
	rect(16,64,412,240,INK)
	rect(18,66,408,236,Color("#234242"))
	rect(22,70,400,228,Color("#153938"))
	border(Rect2(22,70,400,228),TRACE)
	for k in 8:
		var x=28+k*46
		stroke(Vector2(x,74),Vector2(x+13,74),TRACE)
		rect(x+14,73,2,2,TRACE)
	for p in [Vector2(25,73),Vector2(420,73),Vector2(25,296),Vector2(420,296)]: screw(p)
	var center_y=grid_origin.y+source_row*cell+floori(cell*.5)
	stroke(Vector2(34,center_y),Vector2(grid_origin.x,center_y),MINT,4)
	rect(27,center_y-5,8,10,INK)
	rect(28,center_y-3,6,6,MINT)
	label("TX",27,center_y-8,12,MINT)
	for i in wire.size():
		var r=cell_rect(i)
		var ctr=(r.position+Vector2(floori(cell*.5),floori(cell*.5))).round()
		if wire[i]==0:
			rect(r.position.x+4,r.position.y+4,2,2,TRACE)
			rect(r.end.x-5,r.end.y-5,2,2,TRACE)
		else:
			draw_rect(r,Color("#0d292d"))
			border(r,Color("#35534f"))
			var line_color=MINT if live.has(i) else COPPER
			for d in 4:
				if not int(wire[i])&PORTS[d]: continue
				var end=ctr+Vector2(DIRECTIONS[d])*(cell*.5)
				stroke(ctr,end,Color("#071e23"),7)
				stroke(ctr,end,line_color,4)
				var normal=Vector2(DIRECTIONS[d].y,DIRECTIONS[d].x).abs()
				stroke(ctr-normal,end-normal,line_color.lightened(.2),1)
				if live.has(i):
					var phase=.56 if game.prefs.calm else fmod(elapsed*1.4+i*.11,1)
					var dot=ctr.lerp(end,phase).round()
					rect(dot.x-1,dot.y-1,3,3,PAPER)
					var neighbor=point(i)+DIRECTIONS[d]
					if inside(neighbor) and not (int(wire[flat(neighbor)])&PORTS[(d+2)%4]):
						var tip=(end-Vector2(DIRECTIONS[d])*3).round()
						rect(tip.x-2,tip.y-2,4,4,ALERT)
			rect(ctr.x-4,ctr.y-4,9,9,INK)
			rect(ctr.x-3,ctr.y-3,7,7,line_color)
			rect(ctr.x-1,ctr.y-1,3,3,PANEL if not fixed[i] else PAPER)
			if fixed[i]: screw(r.position+Vector2(7,7))
			if rotation_fx==i and rot_time>0:
				border(r.grow(-2),PAPER)
		if i==cursor and not solved:
			var color=MINT if hint_idx==i and hint_age>0 else GOLD
			for corners in [[r.position,1,1],[Vector2(r.end.x-1,r.position.y),-1,1],[r.end-Vector2.ONE,-1,-1],[Vector2(r.position.x,r.end.y-1),1,-1]]:
				var p:Vector2=corners[0]
				stroke(p,p+Vector2(corners[1]*8,0),color,2)
				stroke(p,p+Vector2(0,corners[2]*8),color,2)
	for j in exits.size():
		var y=grid_origin.y+int(exits[j])*cell+floori(cell*.5)
		var c=MINT if receipts.has(exits[j]) else COPPER
		stroke(Vector2(grid_origin.x+cols*cell,y),Vector2(395,y),c,3)
		rect(396,y-7,18,15,c)
		label(char(65+j),401,y+4,12,INK)

func _draw():
	if game==null or cols==0: return
	var station=NAMES[chapter]
	rect(0,0,640,360,INK)
	for j in 24:
		rect(0,25+j*13,640,1,Color("#10242b"))
	rect(0,0,640,22,Color("#1a3940"))
	rect(15,8,5,5,MINT)
	label("PORT AUTHORITY  /  FIELD SIGNAL DEPT.",27,15,12,DIM)
	right_label("87.6 MHz    TX",623,15,12,MINT)
	label("短波配线盘",17,52,24,PAPER)
	label("PATCH BAY",153,50,12,GOLD)
	right_label("%02d  /  %s"%[chapter,station[0]],622,50,12,DIM)
	draw_board()
	rect(435,64,188,240,PANEL)
	rect(435,64,188,2,MINT if solved else COPPER)
	label("BANK   %02d / 03"%(zone+1),445,86,12,MINT)
	for j in 3: rect(567+14*j,77,10,5,MINT if j<zone or (j==zone and solved) else (GOLD if j==zone else TRACE))
	rect(445,95,168,1,TRACE)
	label("接收站",445,113,12,DIM)
	right_label("%d / %d"%[receipts.size(),exits.size()],612,113,12,GOLD)
	for j in exits.size():
		var y=128+j*20
		var lit=receipts.has(exits[j])
		rect(446,y-10,14,13,MINT if lit else COPPER)
		label(char(65+j),450,y,12,INK)
		label(station[j+2],469,y,12,PAPER)
		right_label("已接通" if lit else "断开",612,y,12,MINT if lit else DIM)
	rect(445,179,168,1,TRACE)
	if solved:
		label(station[1]+"  /  回传",445,199,12,MINT)
		wrapped(RESPONSES[chapter][zone],445,218,166)
		var r=confirm_rect()
		draw_rect(r,MINT)
		label("完成配线" if zone==2 else "接入下一区",454,r.position.y+18,12,INK)
		right_label("A" if game.pad else "E",609,r.position.y+18,12,INK)
	else:
		label("线路断口   %02d"%open_ends,445,199,12,GOLD if open_ends else MINT)
		wrapped(note if note_age>0 else "旋转铜线，将 TX 接到所有字母端口。亮线断口归零即接通。",445,218,166,ALERT if note_age>0 else PAPER)
		if game.prefs.difficulty==0:
			var r=helper_rect()
			draw_rect(r,Color("#294447"))
			label("标出下一步",454,r.position.y+18,12,PAPER)
			right_label("X" if game.pad else "J",609,r.position.y+18,12,GOLD)
		else:
			label("TURN COUNT",445,288,12,DIM)
			right_label("%03d"%moves,611,288,12,GOLD)
	if not solved:
		var power=float(live.size())/maxf(1,wire.size()*.56)
		rect(445,245,168,18,INK)
		for j in 37:
			var phase=0 if game.prefs.calm else elapsed*3.5
			var v=clampi(roundi((1+absf(sin(j*.72+phase)*cos(j*.18-phase*.33))*12*power)),1,13)
			rect(448+4*j,254-v/2.0,2,v,MINT if power>.3 else COPPER)
		rect(602,249,7,3,MINT if receipts.size() else TRACE)
		rect(602,255,7,3,GOLD if open_ends else TRACE)
	elif flash>.1:
		rect(435,65,188,2,GOLD)
	rect(16,313,8,4,MINT)
	label("亮点流动  已带电",29,320,12,DIM)
	rect(163,313,8,4,COPPER)
	label("实线  待接入",177,320,12,DIM)
	screw(Vector2(288,315))
	label("铆钉  固定件",298,320,12,DIM)
	rect(0,337,640,23,INK)
	rect(0,337,640,1,TRACE)
	label("方向键  选择      A  顺转      Y  逆转      START  暂停" if game.pad else "WASD / 方向键  选择      E  顺转      K  逆转      鼠标左右键  旋转",16,353,12,DIM)
	right_label("BAY  /  %02d"%(zone+1),624,353,12,MINT)
