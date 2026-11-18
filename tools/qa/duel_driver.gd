extends RefCounted

## Return true when this frame's ordinary controller inputs have been selected.
## Observe the same carrier lamps, station markers, attack warnings and recovery
## windows as the player. This driver never edits a fighter or an objective.
static func drive(pilot) -> bool:
	var arena=pilot.game.arena
	var duel=arena.duels
	if duel.lead==null or not duel.lead.alive() or arena.done: return false
	var hero=arena.hero
	var carrier=duel.priority_enemy()
	if carrier!=null:
		pilot.roles[carrier.kind]=true
		pilot.fight(carrier)
		return true
	var target:Vector2=duel.guidance()
	if target!=Vector2.INF:
		if arena.is_near(hero.pos,target,22):
			pilot.mark("use")
		else:
			pilot.go_to(target,8,8)
		return true
	if duel.phase=="wind" and duel.phase_left<0.13 and hero.cooldown<=0.0:
		pilot.mark("u" if hero.pos.y>295 else "d")
		pilot.tap("dodge",3)
		return true
	var v:Vector2=duel.lead.pos-hero.pos
	if duel.phase=="vent" and absf(v.x)<62 and absf(v.y)<20:
		if v.x*hero.face<0:
			pilot.mark("r" if v.x>0 else "l")
		pilot.tap("heavy",5)
	else:
		pilot.fight(duel.lead)
	return true
