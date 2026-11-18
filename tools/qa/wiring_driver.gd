extends RefCounted
## Solves the visible connectors using edge constraints, with no access to the
## authored answer, hint method, checkpoint mutators or game progression methods.
const DIR=[Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]
const BIT=[1,2,4,8]
var signature=""
var answer=[]
var selected=-1
var turns_sent=0
var confirmations=0
var unsolved=false

func rotate(mask:int)->int: return ((mask<<1)&15)|((mask>>3)&1)
func xy(i:int,w:int)->Vector2i: return Vector2i(i%w,floori(float(i)/w))

func candidates(b):
	var domains=[]
	for i in b.wire.size():
		var domain=[]
		var mask=int(b.wire[i])
		for _n in (1 if b.fixed[i] else 4):
			var valid=true
			var p=xy(i,b.cols)
			for d in 4:
				var q=p+DIR[d]
				if q.x>=0 and q.y>=0 and q.x<b.cols and q.y<b.rows: continue
				var exterior=(p.x==0 and p.y==b.source_row and d==3) or (p.x==b.cols-1 and b.exits.has(p.y) and d==1)
				if bool(mask&BIT[d])!=exterior: valid=false
			if valid and not domain.has(mask): domain.append(mask)
			mask=rotate(mask)
		domains.append(domain)
	return domains

func search(b,domains):
	var changed=true
	while changed:
		changed=false
		for i in domains.size():
			var p=xy(i,b.cols)
			for d in 4:
				var q=p+DIR[d]
				if q.x<0 or q.y<0 or q.x>=b.cols or q.y>=b.rows: continue
				var neighbor=domains[q.x+q.y*b.cols]
				var on=false
				var off=false
				for n in neighbor:
					if int(n)&BIT[(d+2)%4]: on=true
					else: off=true
				for j in range(domains[i].size()-1,-1,-1):
					if (not on if int(domains[i][j])&BIT[d] else not off):
						domains[i].remove_at(j)
						changed=true
				if domains[i].is_empty(): return []
	var branch=-1
	for i in domains.size():
		if domains[i].size()>1 and (branch<0 or domains[i].size()<domains[branch].size()):
			branch=i
	if branch<0:
		var result=[]
		for domain in domains: result.append(domain[0])
		return result if connected(b,result) else []
	for choice in domains[branch]:
		var trial=domains.duplicate(true)
		trial[branch]=[choice]
		var found=search(b,trial)
		if not found.is_empty(): return found
	return []

func connected(b,net)->bool:
	var stack=[b.source_row*b.cols]
	var reached={stack[0]:true}
	while not stack.is_empty():
		var i=int(stack.pop_back())
		var p=xy(i,b.cols)
		for d in 4:
			if not int(net[i])&BIT[d]: continue
			var q=p+DIR[d]
			if q.x<0 or q.y<0 or q.x>=b.cols or q.y>=b.rows: continue
			var k=q.x+q.y*b.cols
			if not reached.has(k):
				reached[k]=true
				stack.append(k)
	for y in b.exits:
		if not reached.has(b.cols-1+int(y)*b.cols): return false
	return true

func drive(p,b):
	var id="%d:%d"%[b.chapter,b.zone]
	if signature!=id:
		signature=id
		answer=search(b,candidates(b))
		selected=-1
		unsolved=answer.is_empty()
		if unsolved:
			printerr("No legal orientation for visible bank ",id)
			return
	if b.solved:
		if p.frame_no%7==0:
			p.mark("use")
			confirmations+=1
		return
	if unsolved: return
	if selected<0 or b.wire[selected]==answer[selected]:
		var lowest=999
		selected=-1
		for i in answer.size():
			if b.wire[i]==answer[i]: continue
			var distance=(xy(i,b.cols)-xy(b.cursor,b.cols)).abs()
			var cost=distance.x+distance.y
			if cost<lowest:
				selected=i
				lowest=cost
	if selected<0: return
	var delta=xy(selected,b.cols)-xy(b.cursor,b.cols)
	if delta.x!=0:
		p.tap("r" if delta.x>0 else "l",5)
	elif delta.y!=0:
		p.tap("d" if delta.y>0 else "u",5)
	elif p.frame_no%7==0:
		var result=rotate(int(b.wire[selected]))
		var reverse=rotate(rotate(result))==answer[selected]
		p.mark("heavy" if reverse else "use")
		turns_sent+=1
