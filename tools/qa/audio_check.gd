extends SceneTree
## Run with a native display and --audio-driver Dummy. This reads the actual
## stereo Master output after the shipping limiter without using a microphone.
const Sound=preload("res://game/sound.gd")
const Profile=preload("res://game/profile.gd")
const TRACKS=["title","workshop","market","docks","tower","boss","ending","past","catwalk"]
const EFFECTS=["jab","heavy","hit","guard","dodge","skill","hurt","ko","select","confirm","radio","alarm","clear","step","return_theatre","return_salt","return_customs","return_ridge","return_breakwater"]
var mixer
var capture=AudioEffectCapture.new()
var profile=Profile.new()
var failed=false
func _initialize(): call_deferred("run")
func meter():
	var frames=capture.get_frames_available()
	if frames==0: return Vector3.ZERO
	var buffer=capture.get_buffer(frames)
	var sum=0.0
	var peak=0.0
	for pair in buffer:
		sum+=pair.length_squared()
		peak=maxf(peak,maxf(absf(pair.x),absf(pair.y)))
	return Vector3(frames,sqrt(sum/(2.0*frames)),peak)
func check(flag,msg):
	if not flag:
		printerr("AUDIO CHECK FAILED ",msg)
		failed=true
func run():
	if DisplayServer.get_name()=="headless":
		printerr("Native display required for the shipping audio presentation")
		quit(2)
		return
	mixer=Sound.new()
	root.add_child(mixer)
	profile.music=10
	profile.effects=10
	mixer.setup(profile)
	capture.buffer_length=1.8
	var master=AudioServer.get_bus_index("Master")
	AudioServer.add_bus_effect(master,capture)
	for id in TRACKS:
		mixer.track(id)
		await create_timer(.92).timeout
		capture.clear_buffer()
		await create_timer(.29).timeout
		var info=meter()
		var player=mixer.music_players[mixer.active]
		check(player.playing and player.stream is AudioStreamOggVorbis and player.stream.loop,id+" looping Vorbis")
		check(info.x>6000 and info.y>.002,id+" audible")
		print("MIX track ",id," RMS dBFS ",snapped(linear_to_db(info.y),.1)," captured frames ",info.x)
	mixer.silence()
	await create_timer(.18).timeout
	for id in EFFECTS:
		capture.clear_buffer()
		mixer.fx(id,1.0)
		check(mixer.samples.has(id),id+" missing")
		if not mixer.samples.has(id): continue
		await create_timer(mixer.samples[id].get_length()+.09).timeout
		var info=meter()
		check(info.x>1600 and info.y>.001,id+" audible")
		print("MIX effect ",id," RMS dBFS ",snapped(linear_to_db(info.y),.1)," pk dBFS ",snapped(linear_to_db(info.z),.1))
	mixer.track("boss")
	await create_timer(.95).timeout
	capture.clear_buffer()
	for pitch in [.96,.98,1.0,1.02]: mixer.fx("hit",1.0,pitch)
	mixer.fx("skill",1.0)
	mixer.fx("ko",1.0)
	await create_timer(.65).timeout
	var stress=meter()
	print("MIX overlapping peak dBFS ",snapped(linear_to_db(stress.z),.01))
	check(stress.z>0 and stress.z<.90,"limiter ceiling")
	mixer.silence()
	# Give the audio thread several full mix buffers to release pending voices.
	await create_timer(.65).timeout
	AudioServer.remove_bus_effect(master,AudioServer.get_bus_effect_count(master)-1)
	mixer.queue_free()
	await create_timer(.22).timeout
	print("MIX ","FAIL" if failed else "PASS")
	quit(1 if failed else 0)
