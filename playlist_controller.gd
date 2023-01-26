extends HBoxContainer

class_name PlaylistController

var list:PackedStringArray
var index:int
var listName:String

#The track to play, self-refrence (for callback)
signal play(track, listcon)

signal indexUpdated(listname, index)

func setPlaylist(newlist:PackedStringArray, newname:String):
	list = newlist
	listName = newname
	%PlaylistName.text = listName
	setIndex(index)	

func refresh():
	%PrevAudioName.text = (
		_getTrackName( list[_clampIndex(index-1)]) )
	%CurrentAudioName.text = (
		_getTrackName( list[_clampIndex(index)]) )
	%NextAudioName.text = (
		_getTrackName( list[_clampIndex(index+1)]) )
	%IndexAndLen.text = "%02d / %02d" % [index+1, list.size()]
	
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
	
func next():
	setIndex(index+1)
func prev():
	setIndex(index-1)
func reset():
	setIndex(0)
func setIndex(newIndex:int):
	index = _clampIndex(newIndex)
	refresh()
	emit_signal("indexUpdated", listName, index)
func onPlayPressed():
	emit_signal("play", list[index], self)

