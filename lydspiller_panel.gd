extends Control

var config:ConfigFile
var _config_path:String = "user://listdata.cfg"

var audio:AudioStreamPlayer
var was_playing_audio:bool = false
var wasStopped:bool = false #flags that the stop function was used to stop audio. list should not advance, and autoplay should be bypassed.
var controller_callback:PlaylistController = null
var master_volume:int
#var playlist_mode:bool = false
var playlistdata:Dictionary = {}
var groups:PackedStringArray
var sel_group:int

var cache:Dictionary #where key is path as a string, value is audiostream.
var loadrequest:Array #where value is an array, index 0 is a path in string, index 1 is a callable and is optional.

@onready var playlistcontroller:PackedScene = preload("res://playlist_controller.tscn")

func _ready():
	audio = %audio
	%audioname.text = "INGEN LYD SPILLES"
	%audiolength.text = "00:00"
	%audiotime.text = "00:00"
	
	cache = {}
	loadrequest = []
	
	#load user config
	config = ConfigFile.new()
	var status:int = config.load(_config_path)
	if status == OK:
		playlistdata = config.get_value("playlists", "lists", {})
	groups = Util.getAllGroups(playlistdata)
	sel_group = -1
	if status == OK:
		sel_group = groups.find(config.get_value("playlists", "last_group", ""))
	for c in %boxGroups.get_children():
		c.free()
	var n = Control.new()
	n.name = "ALLE"
	%boxGroups.add_child(n)
	for g in groups:
		n = Control.new()
		n.name = g
		%boxGroups.add_child(n)
	
	if groups.size() > 0:
		%boxGroups.visible = true
		changeGroupByIndex(sel_group) #This updates the tab
	else:
		sel_group = -1
		%boxGroups.visible = false
	
	populateGrid()
	#Do not quit application automatically.
	get_tree().set_auto_accept_quit(false)
	_on_slid_vol_value_changed(50) #todo: load from config?
	


func _process(_delta):
	if audio.playing == true:
		%audiotime.text = Util.tosecminString(audio.get_playback_position())
		was_playing_audio = true
	elif was_playing_audio:
		onAudioFinished()
	if loadrequest.size() > 0:
		nextLoad()
#process next request for a stream object
func nextLoad():
	var requestPacket:Array = loadrequest.pop_front()
	var path = requestPacket[0]
	if not cache.has(path):
		cache[path] = Util.load_audio(path)
	_completeRequest(requestPacket)
#add a request for a stream object, fullfills it if already loaded.
func requestStream(requestPacket:Array, urgent:bool = false):
	#print("Recived request %s"%[requestPacket])
	var path = requestPacket[0]
	if cache.has(path) and requestPacket.size() > 1:
		_completeRequest(requestPacket)
	elif urgent:
		loadrequest.push_front(requestPacket)
	else:
		loadrequest.push_back(requestPacket)
#fullfills the request for stream object
func _completeRequest(requestPacket:Array):
	var path = requestPacket[0]
	var callback:Callable = (func (_data): return) if requestPacket.size() < 2 else requestPacket[1]
	requestPacket.append(cache[path])
	callback.call_deferred(requestPacket)
	#callback.call(requestPacket)
	
#Ensure the app does not close untill anything important is saved.
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Goodbye world")
		save_data()
		get_tree().quit() #closes application

#saves any changes to the playlists. Possible changes are play indicies and autoplay status.
func save_data():
	config.set_value("playlists", "lists", playlistdata)
	config.set_value("playlists", "last_group", "" if sel_group < 0 else groups[sel_group])
	config.save(_config_path)

func onAudioFinished():
	#if autoplay, call it from callback
	if controller_callback != null && is_instance_valid(controller_callback):
		if not wasStopped:
			controller_callback.next()
		controller_callback.setPlaying(false)
		if not wasStopped and controller_callback.getAuto():
			controller_callback.onPlayPressed()
			return
	#reset playinfo
	controller_callback = null
	%Visualizer.disabled = true
	%audioname.text = "INGEN LYD SPILLES"
	%Audioinfo.tooltip_text = ""
	%audiolength.text = "00:00"
	%audiotime.text = "00:00"
	wasStopped = false

#populates the gridPlayElements with playlistcontroller instances.
func populateGrid():
	var g:String = "" if sel_group < 0 else groups[sel_group]
	for c in %gridPlayElements.get_children():
		%gridPlayElements.remove_child(c)
		c.queue_free()
	var entries:Array = []
	entries.resize(playlistdata.size())
	for e in playlistdata.values():
		var listgroups = e.get("groups",[])
		#If a list is trashed, ignore. If a group is selected, ignore if not in group.
		if "TRASH" in listgroups:
			continue
		if sel_group >= 0 and not g in listgroups:
			continue
		var n:PlaylistController = playlistcontroller.instantiate()
		n.setPlaylist(e)
		n.play.connect(play)
		n.stop.connect(stop)
		n.requestStream.connect(requestStream)
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
	wasStopped = true

func play(path:String, volume:int, callback:PlaylistController = null):
	#disable old visualizer if applicable
	if controller_callback != null && is_instance_valid(controller_callback):
		controller_callback.setPlaying(false)
		#pass
	var volume_db = linear_to_db(float(volume)/100 * float(master_volume)/100)
		
	#set new callback refrence
	controller_callback = callback
	#enable new visualizer
	if(callback):
		callback.setPlaying(true)
	#NOTE: consider using RequestStream with priority here.
	if not cache.has(path):
		cache[path] = Util.load_audio(path)
	audio.stream = cache[path]
	audio.volume_db = volume_db
	audio.play()
	%Visualizer.disabled = false
	
	if audio.playing == true:
		%audioname.text = path.get_basename().get_file()
		%Audioinfo.tooltip_text = path
		%audiolength.text = Util.tosecminString(audio.stream.get_length())
		%audiotime.text = Util.tosecminString(audio.get_playback_position())

func switchToSettingsScene():
	save_data()
	get_tree().change_scene_to_file("res://LydspillerSettings.tscn")

## Server interaction
func _on_server_stop_audio_requested(connection):
	stop()
	%Server.send_string(connection, "Confirmed. stopping audio")

func _on_server_play_list_requested(connection, index):
	if index < 0 or index >= %gridPlayElements.get_child_count():
		%Server.send_string(connection, "Error: out of range")
		return
	%gridPlayElements.get_child(index).onPlayPressed()
	%Server.send_string(connection, "Confirmed. playing audio")

func _on_server_list_data_requested(connection, index):
	if index < 0 or index >= %gridPlayElements.get_child_count():
		%Server.send_string(connection, "Error: out of range")
		return
	var data = %gridPlayElements.get_child(index).listdata
	%Server.send_listdata(connection, data)

func _on_server_list_data_all_requested(connection):
	%Server.send_all_listdata(connection, playlistdata)

#master volume slide
func _on_slid_vol_value_changed(value):
	master_volume = value
	%txtVol.text = "%3d %%" % [value]

func _on_group_tab_changed(value):
	#changes group, removing the tab's index offset.
	changeGroupByIndex(value - 1)
func changeGroupByIndex(groupindex):
	#sets sel_group to value ranged -1 to last index in groups.
	#where a value of -1 means to show all lists.
	sel_group = clampi(groupindex, -1, groups.size()-1)
	#update the current tab if not correct to sel_group
	#offset by 1 to allow for the -1'th index for the "ALLE" (all) tab
	#meaning tab 0 is index -1, tab 1 is index 0, tab 2 is index 1, etc.
	if %boxGroups.current_tab != (sel_group+1):
		%boxGroups.current_tab = sel_group+1
	
	populateGrid()
