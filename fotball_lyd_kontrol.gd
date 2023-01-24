extends Control

var config:ConfigFile
var _config_path:String = "user://scores.cfg"

var audio:AudioStreamPlayer
var dir:String = ""
var was_playing_audio:bool = false

var playlist_edit_mode:bool = false
var playlistedit_entries:Array[String] = []
var playlistedit_name

@onready var playlistentryedit:PackedScene = preload("res://playlistentryedit.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	audio = %audio
	%audioname.text = "INGEN LYD SPILLES"
	%audiolength.text = "00:00"
	%audiotime.text = "00:00"
	
	#load user config
	config = ConfigFile.new()
	var err:int = config.load(_config_path)
	if err == 0:
		dir = config.get_value("lastused", "dir", "")
		if dir != "":
			_on_file_dialog_dir_selected(dir)
	
	#_on_disable_playlist_edit()
	_on_enable_playlist_edit()


func _process(delta):
	if audio.playing == true:
		%audiotime.text = _tosecminString(audio.get_playback_position())
		was_playing_audio = true
	elif was_playing_audio:
		%audioname.text = "INGEN LYD SPILLES"
		%audiolength.text = "00:00"
		%audiotime.text = "00:00"
func _tosecminString(sec) -> String:
	var s:int = int(sec) % 60
	var m:int = int(sec) / 60
	return "%02d:%02d" % [m, s]
	
func _on_file_dialog_dir_selected(newdir):
	for c in %snutter.get_children():
		c.free()
	dir = newdir
	var filepaths:PackedStringArray = DirAccess.get_files_at(dir)
	for f in filepaths:
		var btn:Button = Button.new()
		btn.set_script(load("res://lydknapp.gd"))
		btn.lyd = dir + "/" + f
		btn.text = f.get_basename()
		btn.pressed.connect(btn.on_pressed)
		btn.play.connect(on_audio_pressed)
		%snutter.add_child(btn)
	config.set_value("lastused", "dir", dir)
	config.save(_config_path)
		
func _on_get_sound_pressed():
	%FileDialog.popup_centered(Vector2i(600, 600))

func on_audio_pressed(path:String):
	if playlist_edit_mode:
		add_to_playlist(path)
	else:
		play(path)
func play(path:String):
	audio.stream = load_audio(path)
	audio.play()
	
	if audio.playing == true:
		%audioname.text = path.get_basename()
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
	file = null
	return sound

func _on_stop_sound_pressed():
	audio.stop()

#### PLAYLIST EDIT ####

func _on_enable_playlist_edit():
	playlist_edit_mode = true
	%Plistbuilder.visible = true
	_on_stop_sound_pressed()
	%StopSound.disabled = true

func _on_disable_playlist_edit():
	playlist_edit_mode = false
	%Plistbuilder.visible = false
	%StopSound.disabled = false

func add_to_playlist(path:String):
	var entrybox:Node = playlistentryedit.instantiate()
	entrybox.set_path(path)
	entrybox.set_index(len(playlistedit_entries))
	entrybox.delete.connect(on_playlist_entry_delete)
	playlistedit_entries.append(path)
	%Plistentryeditors.add_child(entrybox)
func on_playlist_entry_delete(index:int):
	var d = %Plistentryeditors.get_child(index)
	%Plistentryeditors.remove_child(d)
	d.queue_free()
	playlistedit_entries.remove_at(index)
	var i:int = 0
	for c in %Plistentryeditors.get_children():
		c.set_index(i)
		i += 1
