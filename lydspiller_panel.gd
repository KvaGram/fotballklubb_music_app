extends Control

var config:ConfigFile
var _config_path:String = "user://listdata.cfg"

var audio:AudioStreamPlayer
var was_playing_audio:bool = false
var controller_callback:PlaylistController = null
#var playlist_mode:bool = false
var playlistdata:Dictionary = {}

@onready var playlistcontroller:PackedScene = preload("res://playlist_controller.tscn")

func _ready():
	audio = %audio
	%audioname.text = "INGEN LYD SPILLES"
	%audiolength.text = "00:00"
	%audiotime.text = "00:00"
	
	#load user config
	config = ConfigFile.new()
	var status:int = config.load(_config_path)
	if status == OK:
		playlistdata = config.get_value("playlists", "lists", {})
	populateGrid()
	#Do not quit application automatically.
	get_tree().set_auto_accept_quit(false)

func _process(_delta):
	if audio.playing == true:
		%audiotime.text = _tosecminString(audio.get_playback_position())
		was_playing_audio = true
	elif was_playing_audio:
		onAudioFinished()

#Ensure the app does not close untill anything important is saved.
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Goodbye world")
		save_data()
		get_tree().quit() #closes application

#saves any changes to the playlists. Possible changes are play indicies and autoplay status.
func save_data():
	config.set_value("playlists", "lists", playlistdata)
	config.save(_config_path)

func onAudioFinished():
	#if autoplay, call it from callback
	if controller_callback != null && is_instance_valid(controller_callback):
		controller_callback.next()
		controller_callback.visualizer.disabled = true
		if controller_callback.getAuto():
			controller_callback.onPlayPressed()
			return
	#reset playinfo
	controller_callback = null
	%Visualizer.disabled = true
	%audioname.text = "INGEN LYD SPILLES"
	%Audioinfo.tooltip_text = ""
	%audiolength.text = "00:00"
	%audiotime.text = "00:00"

#populates the gridPlayElements with playlistcontroller instances.
func populateGrid():
	for c in %gridPlayElements.get_children():
		%gridPlayElements.remove_child(c)
		c.queue_free()
	var entries:Array = []
	entries.resize(playlistdata.size())
	for e in playlistdata.values():
		var n:PlaylistController = playlistcontroller.instantiate()
		n.setPlaylist(e)
		n.play.connect(play)
		var i = e.get("list_index", -1)
		if(i < 0 or i > entries.size()):
			entries.append(n) #in the event of indecies missing or out of range
		elif entries[i]: #in case of indicies somehow overlapping
			entries.append(n)
		else:
			entries[i] = n
	for n in entries:
		if not n:
			continue
		%gridPlayElements.add_child(n)

func stop():
	audio.stop()

func play(path:String, callback:PlaylistController = null):
	#disable old visualizer if applicable
	if controller_callback != null && is_instance_valid(controller_callback):
		controller_callback.visualizer.disabled = true
		#pass
	#set new callback refrence
	controller_callback = callback
	#enable new visualizer
	callback.visualizer.disabled = false
	audio.stream = load_audio(path)
	audio.play()
	%Visualizer.disabled = false
	
	if audio.playing == true:
		%audioname.text = path.get_basename().get_file()
		%Audioinfo.tooltip_text = path
		%audiolength.text = _tosecminString(audio.stream.get_length())
		%audiotime.text = _tosecminString(audio.get_playback_position())
		
func load_audio(path:String):
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	var sound:AudioStream
	if path.get_extension() == "mp3": # .ends_with(".mp3"):
		sound = AudioStreamMP3.new()
		sound.data = file.get_buffer(file.get_length())
	elif path.get_extension() == "wav": #.ends_with(".wav"):
		sound = AudioStreamWAV.new()
		sound.stereo = true
		sound.format = sound.FORMAT_16_BITS
		sound.data = file.get_buffer(file.get_length())
	#elif path.get_extension() == "ogg": #.ends_with(".ogg"):
	#	sound = AudioStreamOggVorbis.new()
	#	sound.data = file.get_buffer(file.get_length())
	file = null #closes file 
	return sound
	
func _tosecminString(sec) -> String:
	var s:int = int(sec) % 60
	var m:int = int(sec) / 60
	return "%02d:%02d" % [m, s]


func switchToSettingsScene():
	save_data()
	get_tree().change_scene_to_file("res://LydspillerSettings.tscn")
