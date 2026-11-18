extends RefCounted
static var start_surface=-1
static var next_surface=-1
static var identity=""
static var last_hop=-10
static func containing(rects,pos):
	for i in rects.size():
		var r=rects[i]
		if absf(pos.y-r.position.y)<1 and pos.x>=r.position.x-2 and pos.x<=r.end.x+2: return i
	return -1
static func adjacency(rects,i,j):
	var a:Rect2=rects[i]
	var b:Rect2=rects[j]
	var gap=maxf(maxf(b.position.x-a.end.x,a.position.x-b.end.x),0)
	var climb=a.position.y-b.position.y
	if climb>82: return false
	return gap<(72 if climb>22 else (125 if climb>=0 else 155))
static func first_step(rects,src,dst):
	if src==dst: return dst
	var q=[src]
	var prev={src:-1}
	while not q.is_empty():
		var u=q.pop_front()
		for v in rects.size():
			if not prev.has(v) and adjacency(rects,u,v):
				prev[v]=u
				if v==dst:
					var w=v
					while prev[w]!=src: w=prev[w]
					return w
				q.append(v)
	return dst
static func side(p,dx,tol=3):
	if absf(dx)>tol: p.mark("r" if dx>0 else "l")
static func hop(p):
	if p.frame_no-last_hop>=5:
		p.mark("dodge")
		last_hop=p.frame_no
static func drive(p):
	var s=p.game.traverse
	var h=s.hero
	if h==null: return
	var goal=s.exit_pos if s.target>=s.nodes.size() else s.nodes[s.target].p
	var id="%d.%d.%d"%[s.chapter,s.room,s.target]
	if id!=identity:
		next_surface=-1
		identity=id
	var dst=containing(s.platforms,goal)
	if dst<0: return
	var src=containing(s.platforms,h.pos) if s.grounded else -1
	if src>=0:
		start_surface=src
		next_surface=first_step(s.platforms,src,dst)
	if next_surface<0: next_surface=dst
	if src==dst or (not s.grounded and next_surface==dst and absf(h.pos.y-goal.y)<14 and s.vy>=0):
		var dx=goal.x-h.pos.x
		if s.target>=s.nodes.size():
			side(p,dx,9)
			if s.near(goal): p.tap("use",4)
		elif s.nodes[s.target].kind in ["lock","drone"]:
			if absf(dx)>37: side(p,dx,20)
			elif absf(dx)>2 and h.face!=int(signf(dx)): side(p,dx,1)
			if absf(dx)<52: p.tap("heavy",6)
		else:
			side(p,dx,7)
			if s.near(goal): p.tap("use",5)
		return
	var next:Rect2=s.platforms[next_surface]
	var at=h.pos
	var low=next.position.x+8
	var high=next.end.x-8
	var desired=clampf(at.x,low+6,high-6)
	if start_surface>=0:
		var old:Rect2=s.platforms[start_surface]
		if next.position.x>=old.end.x-5: desired=low+12
		elif next.end.x<=old.position.x+5: desired=high-12
	var dx=desired-at.x
	side(p,dx,3)
	if src>=0:
		var old:Rect2=s.platforms[src]
		var above=next.position.y<old.position.y
		if above:
			if at.x>=next.position.x-84 and at.x<=next.end.x+84: hop(p)
		elif next.position.y==old.position.y:
			if (dx>0 and at.x>old.end.x-24) or (dx<0 and at.x<old.position.x+24): hop(p)
		elif src<4 and at.x>=low and at.x<=high:
			p.mark("d")
			hop(p)
		elif dx!=0 and ((dx>0 and at.x>old.end.x-17) or (dx<0 and at.x<old.position.x+17)):
			hop(p)
	elif s.jumps==1 and s.vy>=-25 and (h.pos.y>next.position.y-4 or at.x<low-4 or at.x>high+4):
		hop(p)
