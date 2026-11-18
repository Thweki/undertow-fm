extends RefCounted
const PATH="user://broadcast.cfg"
var path=PATH
var cfg=ConfigFile.new()
var chapter=-1
var section=0
var score=0
var checkpoint_health=100
var unlock=0
var completed=false
var broadcast_pending=false
var route_stats={}
var interlude={}
var records={}
var best={}
var music=7
var effects=8
var tremor=true
var calm=false
var difficulty=1
var fullscreen=false
var active_seconds=0.0
var backup_valid=false
func read():
	if cfg.load(path)!=OK:
		if cfg.load(path+".bak")!=OK: return
	else: backup_valid=true
	chapter=clampi(int(cfg.get_value("route","chapter",-1)),-1,15)
	section=clampi(int(cfg.get_value("route","section",0)),0,5)
	score=maxi(0,int(cfg.get_value("route","score",0)))
	checkpoint_health=clampi(int(cfg.get_value("route","hp",100)),1,100)
	unlock=clampi(int(cfg.get_value("route","unlock",0)),0,15)
	completed=cfg.get_value("route","completed",false)
	broadcast_pending=bool(cfg.get_value("route","broadcast_pending",false))
	interlude=cfg.get_value("route","interlude",{})
	route_stats=cfg.get_value("route","stats",{})
	active_seconds=maxf(0.0,float(cfg.get_value("route","seconds",0)))
	records=cfg.get_value("archive","tapes",{})
	best=cfg.get_value("archive","best",{})
	for prop in ["music","effects","tremor","calm","difficulty","fullscreen"]:
		set(prop,cfg.get_value("options",prop,get(prop)))
	difficulty=clampi(difficulty,0,2)
func save():
	for key in ["chapter","section","score","unlock","completed","broadcast_pending"]:
		cfg.set_value("route",key,get(key))
	cfg.set_value("route","stats",route_stats)
	cfg.set_value("route","interlude",interlude)
	cfg.set_value("route","hp",checkpoint_health)
	cfg.set_value("route","seconds",active_seconds)
	cfg.set_value("archive","tapes",records)
	cfg.set_value("archive","best",best)
	for prop in ["music","effects","tremor","calm","difficulty","fullscreen"]:
		cfg.set_value("options",prop,get(prop))
	if cfg.save(path+".tmp")!=OK: return
	var root=DirAccess.open(path.get_base_dir())
	var filename=path.get_file()
	if backup_valid and root.file_exists(filename):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path)+".bak")
	if root.rename(filename+".tmp",filename)==OK: backup_valid=true
