extends Control

var config:ConfigFile
var _config_path:String = "user://scores.cfg"
enum Mode { SINGLE=0,PLAYLIST=1,PLAYLISTEDIT=2 }

var mode:Mode
var audio:AudioStreamPlayer
var dir:String = ""
var was_playing_audio:bool = false
#var playlist_mode:bool = false

#var playlist_edit_mode:bool = false
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
	clearPlaylistEdit()
	setmode(Mode.SINGLE)

func setmode(newMode):
	mode = newMode
	%Tabs.current_tab = 1 if mode==Mode.PLAYLIST else 0
	%Playmode.text = "Spill spillelister" if mode == Mode.SINGLE else "Spill enkeltlåter"
	%GetSound.disabled = mode == Mode.PLAYLIST
	%StopSound.disabled = mode == Mode.PLAYLISTEDIT
	%Plistbuilder.visible = mode == Mode.PLAYLISTEDIT

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
	if mode == Mode.PLAYLISTEDIT:
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

#### PLAYLIST MODE ####
func _on_playmode_pressed():
	if mode == Mode.SINGLE:
		setmode(Mode.PLAYLIST)
	else:
		setmode(Mode.SINGLE)
func _on_new_playlist_btn_pressed():
	setmode(Mode.PLAYLISTEDIT)

func update_playlists():
	#updates the list of playlists
	pass #TODO

#### PLAYLIST EDIT ####
func _on_save_playlist_pressed():
	var name = %ListNameEntry.text
	if len(name) < 2:
		%ListNameWarn.visible = true
		%ListNameEditBox.tooltip_text = "Navnet er for kort"
		return
	elif config.has_section_key("playlists", "name") && not Input.is_key_pressed(KEY_SHIFT):
		%ListNameWarn.visible = true #ERROR! This seem to have passed without holding shift.
		%ListNameEditBox.tooltip_text = "En spilleliste med det navnet finner allerede. Hold inne shift for å overskrive"
		return
	config.set_value("playlists", name, playlistedit_entries.duplicate())
	config.save(_config_path)
	clearPlaylistEdit()
	update_playlists()
	setmode(Mode.PLAYLIST)

func _on_list_name_entry_text_changed(_new_text):
	%ListNameWarn.visible = false
	%ListNameEditBox.tooltip_text = "..."

func clearPlaylistEdit():
	%ListNameWarn.visible = false
	%ListNameEditBox.tooltip_text = "ingen feil"
	%ListNameEntry.clear()
	playlistedit_entries.clear()
	for c in %Plistentryeditors.get_children():
		%Plistentryeditors.remove_child(c)
		c.queue_free()

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








