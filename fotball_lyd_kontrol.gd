extends Control

var config:ConfigFile
var _config_path:String = "user://listdata.cfg"
enum Mode { SINGLE=0,PLAYLIST=1,PLAYLISTEDIT=2 }

var mode:Mode
var audio:AudioStreamPlayer
var dir:String = ""
var was_playing_audio:bool = false
var controller_callback:PlaylistController = null
#var playlist_mode:bool = false
var playlistdata:Dictionary = {}

#var playlist_edit_mode:bool = false
var playlistedit_entries:Array[String] = []
var playlistedit_name:String

# Saving new playlist. Whatever to overwrite existing playlist of same name.
# resets when saving a playlist, or when playlist name changes.
var overwrite_flag:bool

@onready var playlistentryedit:PackedScene = preload("res://playlistentryedit.tscn")
@onready var playlistcontroller:PackedScene = preload("res://playlist_controller.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	audio = %audio
	%audioname.text = "INGEN LYD SPILLES"
	%audiolength.text = "00:00"
	%audiotime.text = "00:00"
	
	#load user config
	config = ConfigFile.new()
	var status:int = config.load(_config_path)
	if status == OK:
		dir = config.get_value("lastused", "dir", "")
		playlistdata = config.get_value("playlists", "lists", {})
		if dir != "":
			_on_file_dialog_dir_selected(dir)
	clearPlaylistEdit()
	update_playlists()
	setmode(Mode.SINGLE)
	#Do not quit application automatically.
	get_tree().set_auto_accept_quit(false)

#Ensure the app does not close untill anything important is saved.
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Goodbye world")
		save_data()
		get_tree().quit() #closes application

func setmode(newMode):
	mode = newMode
	%Tabs.current_tab = 1 if mode==Mode.PLAYLIST else 0
	%Playmode.text = "Spill spillelister" if mode == Mode.SINGLE else "Spill enkeltlåter"
	%GetSound.disabled = mode == Mode.PLAYLIST
	%StopSound.disabled = mode == Mode.PLAYLISTEDIT
	%Plistbuilder.visible = mode == Mode.PLAYLISTEDIT

func _process(_delta):
	if audio.playing == true:
		%audiotime.text = _tosecminString(audio.get_playback_position())
		was_playing_audio = true
	elif was_playing_audio:
		onAudioFinished()
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
		%audioname.text = path.get_basename().get_file()
		%Audioinfo.tooltip_text = path
		%audiolength.text = _tosecminString(audio.stream.get_length())
		%audiotime.text = _tosecminString(audio.get_playback_position())
func play_list(path:String, callback:PlaylistController):
	controller_callback = callback
	play(path)
func onAudioFinished():
	#if autoplay, call it from callback
	if controller_callback != null && is_instance_valid(controller_callback):
		controller_callback.next()
		if false: #autoplay
			controller_callback.onPlayPressed()
			return
	#reset playinfo
	controller_callback = null
	%audioname.text = "INGEN LYD SPILLES"
	%Audioinfo.tooltip_text = ""
	%audiolength.text = "00:00"
	%audiotime.text = "00:00"

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
	var clist:Array = %PlaylistContainer.get_children()
	var ci:int = 0
	for p in playlistdata.values():
		var c:PlaylistController
		if(ci < clist.size()):
			c = clist[ci]
		else:
			c = playlistcontroller.instantiate()
			%PlaylistContainer.add_child(c)
			c.play.connect(play_list)
			c.indexUpdated.connect(update_list_index)
			c.deleteList.connect(on_delete_list)
		c.setPlaylist(p.get("list", PackedStringArray([])), p.get("name", "unnamed playlist"))
		c.setIndex(p.get("index", 0))
		ci += 1
	#remove excess playlist controllers
	while ci < clist.size():
		clist[ci].queue_free()
		ci += 1
func update_list_index(name, newindex):
	if not playlistdata.has(name):
		printerr("Error. playlist % not found"%[name])
		return
	playlistdata[name]["index"] = newindex
func save_data():
	config.set_value("playlists", "lists", playlistdata)
	config.set_value("lastused", "dir", dir)
	config.save(_config_path)
	

#### PLAYLIST EDIT ####
func _on_save_playlist_pressed():
	var name = %ListNameEntry.text
	if len(name) < 2:
		%ListNameWarn.visible = true
		%ListNameEditBox.tooltip_text = "Navnet er for kort"
		return
	elif playlistdata.has(name):
		if not overwrite_flag:
			%ListNameWarn.visible = true #ERROR! This seem to have passed without holding shift.
			%ListNameEditBox.tooltip_text = "En spilleliste med det navnet finnes allerede. Trykk igjen for å overskrive"
			overwrite_flag = true
			return
	
	var data = {"list" : playlistedit_entries.duplicate(), "name" : name}
	if playlistdata.has(name):
		playlistdata[name].merge(data, true) #this preserves play index if present
	else:
		playlistdata[name] = data
	clearPlaylistEdit()
	update_playlists()
	setmode(Mode.PLAYLIST)

func on_delete_list(name):
	playlistdata.erase(name)
	update_playlists()

func _on_list_name_entry_text_changed(_new_text):
	%ListNameWarn.visible = false
	%ListNameEditBox.tooltip_text = "..."
	overwrite_flag = false

func clearPlaylistEdit():
	overwrite_flag = false
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








