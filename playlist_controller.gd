extends Control

class_name PlaylistController

var listdata:Dictionary
var listlables:Dictionary

var volume:PackedInt32Array
var list:PackedStringArray
var listName:String
var _playing:bool = false
var need_refresh:bool = false

@onready var visualizer = %visualizer

#The track to play, self-refrence (for callback)
signal play(track, volume, listcon)
#local stop-button
signal stop()
#request for a stream to be loaded.
#This is mainly used for showing tracklength.
signal requestStream(requestPacket)

func _process(_delta):
	if need_refresh:
		refresh()

func setPlaylist(newListdata:Dictionary):
	listdata = newListdata
	list = PackedStringArray(listdata.get("list", []))
	volume = PackedInt32Array(listdata.get("vol", []))
	if volume.size() < list.size():
		var i = volume.size()
		volume.resize(list.size())
		while i < list.size():
			volume[i] = 50
			i += 1
	if list.size() < 2:
		%tabContent.set_current_tab(1) #single mode
	else:
		%tabContent.set_current_tab(0) #list mode
	listName = listdata.get("name", "unamed list")
	setAuto(getAuto()) #this updates the buttons.
	%PlaylistName1.text = listName
	%PlaylistName2.text = listName
	%winFullList.title = listName
	setIndex(getIndex())

func refresh():
	%PrevAudioName.text = (
		_getTrackName( list[_wrapIndex(getIndex()-1)]) )
	%CurrentAudioName1.text = (
		_getTrackName( list[_wrapIndex(getIndex())]) )
	%CurrentAudioName2.text = (
		_getTrackName( list[_wrapIndex(getIndex())]) )
	%NextAudioName.text = (
		_getTrackName( list[_wrapIndex(getIndex()+1)]) )
	%IndexAndLen.text = "%02d / %02d" % [getIndex()+1, list.size()]
	need_refresh = false
	
#Gets a track path's readable name and length in minutes:secunds.
#If such a label is not already known, requests the stream object so it may be contructed.
func _getTrackName(path:String) -> String:
	if path in listlables:
		return listlables[path]
	var callback = func(data):
		var stream:AudioStream = data[-1] #stream object is appended when request completes, so it is the last object
		var selfref:PlaylistController = data[2]
#		if(stream.get_length() < 0.1):
#			printerr("no length?")
		var m = floori(stream.get_length() / 60)
		var s = floori(stream.get_length()) % 60
		var label:String = "%s - (%02d:%02d)"%[path.get_file().get_basename(), m, s]
		selfref.listlables[path] = label #Add to list of generated lables
		selfref.need_refresh = true
	var requestPacket:Array = [path, callback, self]
	emit_signal("requestStream", requestPacket)
	#print("requesting " + path)
	return "%s - (??:??)"%[path.get_file().get_basename()] #return placeholder label with unknown time
	
#used when setting the index. Wraps the index within range [0, list.size()-1]
func _wrapIndex(ind:int) -> int:
	var s = list.size()
	if s <= 0:
		return -1 #a what the f.. failsafe. case of empty list.
	while ind >= s:
		ind -= s
	while ind < 0:
		ind += s
	return ind

func getAuto()->bool:
	return listdata.get("play_auto", false)
func setAuto(value:bool):
	listdata["play_auto"] = value
	%btnAutoplay2.set_pressed(value)
	%btnAutoplay1.set_pressed(value)

#index buttons
func next():
	setIndex(getIndex()+1)
func prev():
	setIndex(getIndex()-1)
func reset():
	setIndex(0)

#index getter and setter. Index is stored in the listdata dictionary.
func getIndex() -> int:
	return listdata.get("play_index", -1)
func setIndex(value:int):
	listdata["play_index"] = _wrapIndex(value)
	need_refresh = true

#When the playbutton is pressed. 
func onPlayPressed():
	if _playing:
		emit_signal("stop")
	else:
		emit_signal("play", list[getIndex()], volume[getIndex()], self)

func isPlaying()->bool:
	return _playing
func setPlaying(value:bool):
	_playing = value
	visualizer.disabled = !_playing
	for btn in [%btnPlay1, %btnPlay2]:
		btn.text = "■" if _playing else "▶"

func _on_index_and_len_pressed():
	%listFullList.deselect_all()
	%listFullList.clear()
	for p in list:
		%listFullList.add_item(_getTrackName(p))
	%listFullList.select(getIndex(), true)
	%winFullList.popup_centered()


func setIndexAndPlay(index):
	setIndex(index)
	onPlayPressed()
	%winFullList.hide()
