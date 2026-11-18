extends RefCounted
const FRAMES={"idle":6,"walk":8,"jab":6,"heavy":8,"skill":10,"dodge":6,"hurt":4,"down":6}
const STATS={
	"hero":[100,136,0,0],"runner":[37,62,8,49],"guard":[61,42,11,55],
	"brute":[86,36,15,63],"tech":[43,46,10,87],"skater":[46,80,9,66],"boss":[265,56,17,71]}
static var sheets={}
var kind="hero"
var skin_override=""
var pos=Vector2.ZERO
var face=1
var hp=100
var max_hp=100
var state="idle"
var time=0.0
var length=1.0
var cooldown=0.0
var invincible=0.0
var push=Vector2.ZERO
var move_bonus=""
var chase_time=0.0
var vector=Vector2.ZERO
var struck=false
var index=0
var chain=0
var chain_grace=0.0
var command=""
var buffer=0.0
var hurt_by=""
var guard_break=0.0
var role=""
var damage=0
var speed=0.0
var reach=0
var attack_type=""
var locked_dir=Vector2.ZERO
var attack_phase=0
var special_phase=false
var perfect=false
var last_foot=0
var recent_hit=0.0
var palette=Color.WHITE
var shade=1.0
func init(id:String,point:Vector2,idx:int,diff:int,champ:=""):
	kind=id
	pos=point
	index=idx
	role=champ
	var stats=STATS[id]
	max_hp=stats[0]
	if id!="hero":
		max_hp=roundi(max_hp*[0.78,1.0,1.22][diff]*(1.72 if champ!="" and kind!="boss" else 1.0))
		face=-1
		damage=roundi(stats[2]*[0.55,0.82,1.1][diff])
		reach=stats[3]
		cooldown=0.45+fmod(idx*0.173,0.7)
		palette=[Color.WHITE,Color("dcf6f4"),Color("f4e0d4"),Color("e4dfef")][idx%4]
	hp=max_hp
	speed=stats[1]
	return self
func pose(s:String,dur:float):
	state=s
	time=0.0
	length=maxf(dur,0.01)
	struck=false
	last_foot=0
func alive(): return hp>0
func can_move(): return state=="idle" or state=="walk"
func frame_id():
	var n=int(FRAMES.get(state,6))
	if state=="idle": return int(time*6.0+index)%n
	if state=="walk": return int(time*(12 if kind=="hero" else 9)+index)%n
	if state=="warn":
		return 0 if time<length*0.55 else 1
	return clampi(int(time/length*n),0,n-1)
func texture_for(anim:String):
	var key=(skin_override if skin_override!="" else kind)+"_"+anim
	if not sheets.has(key):
		var path="res://assets/actors/"+key+".png"
		if ResourceLoader.exists(path): sheets[key]=load(path)
		else: return null
	return sheets[key]
func timers(dt):
	time+=dt
	cooldown=maxf(0,cooldown-dt)
	chase_time=maxf(0,chase_time-dt)
	invincible=maxf(0,invincible-dt)
	guard_break=maxf(0,guard_break-dt)
	recent_hit=maxf(0,recent_hit-dt)
	chain_grace=maxf(0,chain_grace-dt)
	buffer=maxf(0,buffer-dt)
	if buffer<=0: command=""
	if chain_grace<=0 and can_move(): chain=0
	pos+=push*dt
	push=push.move_toward(Vector2.ZERO,660*dt)
func queue_cmd(cmd:String):
	command=cmd
	buffer=0.23
func hero_update(dt,a):
	timers(dt)
	var move_dir=Input.get_vector("leftward","rightward","upward","downward")
	for cmd in ["jab","heavy","dodge","skill"]:
		if Input.is_action_just_pressed(cmd): queue_cmd(cmd)
	if state=="down": return
	if state=="hurt" and time>=length: pose("idle",1)
	if state=="dodge":
		pos+=vector*dt*254*(1.0-0.35*time/length)
		if time>=length:
			chase_time=0.27
			pose("idle",1)
	if state in ["jab","heavy","skill"]:
		var trigger=0.35 if state=="jab" else (0.48 if state=="heavy" else 0.43)
		if time>=length*trigger and not struck:
			struck=true
			a.player_attack(self)
		if time<length*0.48 and state!="skill": pos.x+=face*dt*(171 if move_bonus=="chase" else (65 if state=="heavy" else 48))
		if time>=length or (struck and time>length*0.72 and command!=""):
			pose("idle",1)
	if command=="dodge" and cooldown<=0 and (can_move() or state in ["jab","heavy"]):
		vector=move_dir if move_dir.length()>0.18 else Vector2(face,0)
		if absf(vector.x)>0.1: face=int(signf(vector.x))
		pose("dodge",0.32)
		invincible=0.34
		cooldown=0.61
		perfect=false
		a.dodge_start()
		command=""
	if not can_move(): return
	if absf(move_dir.x)>0.12: face=int(signf(move_dir.x))
	if command!="":
		var cmd=command
		command=""
		move_bonus=""
		if cmd=="jab":
			if a.chapter>=3 and chase_time>0:
				move_bonus="chase"
				chase_time=0
			chain=chain%3+1
			chain_grace=0.79
			pose("jab",0.30 if chain<3 else 0.39)
			a.sound.fx("jab",0.57,1.01+chain*0.045)
		elif cmd=="heavy":
			if a.chapter>=7 and chain==2 and chain_grace>0: move_bonus="breaker"
			chain=0
			pose("heavy",0.56)
			a.sound.fx("heavy",0.60)
		elif cmd=="skill":
			if a.flux>=40:
				a.flux-=40
				pose("skill",0.69)
				invincible=0.58
				a.sound.fx("skill",0.85)
			else: a.tip_once("频能不足 · 命中或精准闪避可充能")
		if not can_move(): return
	if move_dir.length()>0.12:
		if state!="walk": pose("walk",1)
		pos+=Vector2(move_dir.x,move_dir.y*0.70)*speed*dt*(0.82 if a.carry else 1.0)
	else:
		if state!="idle": pose("idle",1)
func enemy_update(dt,a):
	timers(dt)
	if state=="down": return
	if kind=="boss" and hp<=max_hp*0.5 and not special_phase:
		special_phase=true
		guard_break=0.0
		cooldown=0.25
		a.boss_turn()
	var delta=a.hero.pos-pos
	if state=="hurt":
		if time>=length: pose("idle",1)
		return
	if state=="warn":
		if time>=length:
			pose(attack_type,0.67 if attack_type=="skill" else (0.42 if attack_type=="jab" else 0.62))
			a.sound.fx("heavy" if attack_type!="jab" else "jab",0.45,0.80)
		return
	if state in ["jab","heavy","skill"]:
		if kind=="skater" and time<0.28: pos+=locked_dir*dt*133
		if kind=="boss" and state=="heavy" and time<0.33: pos+=locked_dir*dt*104
		if time>=length*0.43 and not struck:
			struck=true
			a.enemy_attack(self)
		if time>=length:
			pose("idle",1)
			cooldown=0.52+fmod(index*0.313+a.rng.randf()*0.54,0.82)
		return
	if absf(delta.x)>2: face=int(signf(delta.x))
	var slot=Vector2(a.hero.pos.x-face*(reach-13),a.hero.pos.y)
	var allow=a.can_attack(self)
	if not allow:
		slot=Vector2(a.hero.pos.x-face*(reach+18+(index%3)*9),clampf(a.hero.pos.y+([-1,1][index%2])*(18+index%12),250,330))
	if absf(delta.x)<reach+3 and absf(delta.y)<(19 if kind!="tech" else 28) and cooldown<=0 and allow and a.hero.alive():
		attack_phase+=1
		attack_type="jab"
		if kind in ["guard","brute","skater"]: attack_type="heavy"
		if kind=="tech" or (kind=="boss" and attack_phase%(2 if special_phase else 3)==0): attack_type="skill"
		elif kind=="boss": attack_type="heavy" if attack_phase%2==0 else "jab"
		var wind=0.48
		if attack_type=="heavy": wind=0.71
		if attack_type=="skill": wind=0.92
		if special_phase: wind*=0.82
		locked_dir=Vector2(face,clampf(delta.y/90,-0.35,0.35)).normalized()
		pose("warn",wind)
		a.windup(self)
		return
	var toward=slot-pos
	if toward.length()>5:
		if state!="walk": pose("walk",1)
		pos+=Vector2(toward.normalized().x,toward.normalized().y*1.07)*speed*dt*(1.15 if special_phase else 1.0)
	elif state!="idle": pose("idle",1)
