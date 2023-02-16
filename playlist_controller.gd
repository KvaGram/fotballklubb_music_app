extends Control

class_name PlaylistController

var listdata:Dictionary

var list:PackedStringArray
var listName:String
var _playing:bool = false

@onready var visualizer = %visualizer

#The track to play, self-refrence (for callback)
signal play(track, listcon)
#local stop-button
signal stop()

func setPlaylist(newListdata:Dictionary):
	listdata = newListdata
	list = PackedStringArray(listdata.get("list", []))
	if list.size() < 2:
		%tabContent.set_current_tab(1) #single mode
	else:
		%tabContent.set_current_tab(0) #list mode
	listName = listdata.get("name", "unamed list")
	setAuto(getAuto()) #this updates the buttons.
	%PlaylistName1.text = listName
	%PlaylistName2.text = listName
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
	return path.get_file().get_basename()
	
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
		emit_signal("play", list[getIndex()], self)

func isPlaying()->bool:
	return _playing
func setPlaying(value:bool):
	_playing = value
	visualizer.disabled = !_playing
	for btn in [%btnPlay1, %btnPlay2]:
		btn.text = "■" if _playing else "▶"
