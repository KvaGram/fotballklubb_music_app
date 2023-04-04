extends Control

class_name PlaylistController

var listdata:Dictionary
var listlables:Dictionary

var volume:PackedInt32Array
var list:PackedStringArray
var refcache:Dictionary #refrence to parent cache
var listName:String
var _playing:bool = false

@onready var visualizer = %visualizer

#The track to play, self-refrence (for callback)
signal play(track, volume, listcon)
#local stop-button
signal stop()

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
		_getTrackName( list[_clampIndex(getIndex()-1)]) )
	%CurrentAudioName1.text = (
		_getTrackName( list[_clampIndex(getIndex())]) )
	%CurrentAudioName2.text = (
		_getTrackName( list[_clampIndex(getIndex())]) )
	%NextAudioName.text = (
		_getTrackName( list[_clampIndex(getIndex()+1)]) )
	%IndexAndLen.text = "%02d / %02d" % [getIndex()+1, list.size()]
	
func _getTrackName(path:String) -> String:
	if path in listlables:
		return listlables[path]
	var stream:AudioStream
	if refcache.has(path):
		stream = refcache[path]
	else:
		stream = util.load_audio(path)
		refcache[path] = stream
	
	var m = floori(stream.get_length() / 60)
	var s = floori(stream.get_length()) % 60
	var label:String = "%s - (%02d:%02d)"%[path.get_file().get_basename(), m, s] 
	listlables[path] = label
	return label
	
	
func _clampIndex(ind:int) -> int:
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

func next():
	setIndex(getIndex()+1)
func prev():
	setIndex(getIndex()-1)
func reset():
	setIndex(0)
	
func getIndex() -> int:
	return listdata.get("play_index", -1)
func setIndex(value:int):
	listdata["play_index"] = _clampIndex(value)
	refresh()
	
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
func onStreamLoaded(path):
	if path in list:
		refresh()


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
