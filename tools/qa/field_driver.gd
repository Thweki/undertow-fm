extends RefCounted

static func drive(p):
	var a=p.game.arena
	if a.kind not in ["relay","escort"] or a.done: return false
	var f=a.field
	var h=a.hero
	var foe=null
	var distance=INF
	for e in a.enemies:
		if not e.alive(): continue
		var val=h.pos.distance_to(e.pos)
		if val<distance:
			foe=e
			distance=val
	if foe and (distance<139 or a.jammed or f.duty=="crossing"):
		p.roles[foe.kind]=true
		p.fight(foe)
		return true
	var pos=f.current
	if f.loading:
		p.go_to(pos,9,8)
		return true
	var dx=pos.x-h.pos.x
	if f.duty in ["breaker","lock"]:
		if absf(dx)>43 or absf(pos.y-h.pos.y)>10:
			p.go_to(pos-Vector2(27 if dx>=0 else -27,0),5,6)
		else:
			if h.face!=int(signf(dx)) and absf(dx)>1: p.mark("r" if dx>0 else "l")
			p.tap("heavy",5)
		return true
	if not a.is_near(h.pos,pos,27):
		p.go_to(pos,7,7)
	elif f.duty=="listen":
		var value=f.dial if f.dial<=1 else 2-f.dial
		if absf(value-f.dial_center)<f.window()*0.8: p.tap("use",4)
	elif f.duty=="passenger":
		if f.sub==0: p.tap("use",5)
	else: p.mark("use")
	return true
