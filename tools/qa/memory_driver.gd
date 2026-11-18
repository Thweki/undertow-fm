extends RefCounted
static var lever_id=""
static func drive(p):
	var a=p.game.arena
	var f=a.memoryrun
	var h=a.hero
	var target=f.node
	if f.pending:
		p.go_to(target,8,8)
		return
	var enemy=null
	var cost=INF
	for e in a.enemies:
		if e.alive():
			var distance=h.pos.distance_to(e.pos)
			if distance<cost:
				cost=distance
				enemy=e
	if enemy and (f.phase==0 or cost<144 or a.jammed):
		p.fight(enemy)
		return
	if f.phase==0:
		p.go_to(target,12,10)
		return
	if f.action=="lock" and f.strikes<2:
		var dx=target.x-h.pos.x
		if absf(dx)>42 or absf(target.y-h.pos.y)>10:
			p.go_to(target-Vector2(28 if dx>=0 else -28,0),5,6)
		else:
			if absf(dx)>1 and h.face!=int(signf(dx)): p.mark("r" if dx>0 else "l")
			p.tap("heavy",5)
	elif not a.is_near(h.pos,target,25): p.go_to(target,8,7)
	elif f.action=="send": p.mark("use")
	elif f.action=="lever":
		var dir=int(f.signal_pattern[f.sequence])
		var station="%d/%d/%d"%[f.episode,f.room,f.station]
		if lever_id!=station:
			if absf(h.pos.x-target.x)>5:
				p.go_to(target,3,8)
				return
			lever_id=station
		if h.face!=dir:
			p.mark("r" if dir>0 else "l")
		else:
			p.tap("use",5)

	else: p.tap("use",5)
