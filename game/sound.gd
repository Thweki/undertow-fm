extends Node
var prefs
var music_players=[]
var sounds=[]
var samples={}
var songs={}
var current=""
var active=0
var fade=1.0
var duck=1.0
func setup(p):
	prefs=p
	var master=AudioServer.get_bus_index("Master")
	var limited=false
	for i in AudioServer.get_bus_effect_count(master):
		if AudioServer.get_bus_effect(master,i) is AudioEffectHardLimiter: limited=true
	if not limited:
		var limiter=AudioEffectHardLimiter.new()
		limiter.ceiling_db=-1.2
		AudioServer.add_bus_effect(master,limiter)
	for i in 2:
		var player=AudioStreamPlayer.new()
		add_child(player)
		music_players.append(player)
	for i in 16:
		var player=AudioStreamPlayer.new()
		add_child(player)
		sounds.append(player)
func track(id:String):
	if id==current or DisplayServer.get_name()=="headless": return
	var path="res://assets/audio/"+id+".ogg"
	if not ResourceLoader.exists(path): return
	if not songs.has(id):
		songs[id]=load(path)
		songs[id].loop=true
	current=id
	active=1-active
	var player=music_players[active]
	player.stream=songs[id]
	player.volume_db=-80
	player.play()
	fade=0.0
func _process(dt):
	if music_players.is_empty(): return
	fade=minf(1.0,fade+dt*1.15)
	for i in 2:
		var vol=(fade if i==active else 1.0-fade)*prefs.music/10.0*duck
		music_players[i].volume_db=linear_to_db(maxf(0.0001,vol))
		if i!=active and fade>=1.0: music_players[i].stop()
func fx(id:String,vol:=0.85,pitch:=1.0):
	if prefs.effects<=0 or DisplayServer.get_name()=="headless": return
	if not samples.has(id):
		var path="res://assets/audio/"+id+".wav"
		if not ResourceLoader.exists(path): return
		samples[id]=load(path)
	var chosen=sounds[0]
	for p in sounds:
		if not p.playing:
			chosen=p
			break
	chosen.stream=samples[id]
	chosen.pitch_scale=pitch
	chosen.volume_db=linear_to_db(maxf(0.0001,prefs.effects/10.0*vol))
	chosen.play()


func silence():
	for player in music_players+sounds:
		player.stop()
		player.stream=null
	samples.clear()
	songs.clear()
