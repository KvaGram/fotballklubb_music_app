extends MarginContainer
class_name PlaylistEntry

#Used for listing screen elements for editing, and playlist entries.

enum ENTRYMODE {AUDIOENTRY=1, LISTENTRY=2}

var _index:int
var _text:String
var _mode:ENTRYMODE
var _vol:int

signal delete(index:int)
signal edit(index:int)
signal move(fromIndex:int, toIndex:int)
signal playstop(path:String, volume_percent:int)
#signal volume_changed(index:int, percent:int)

func set_mode(newmode:ENTRYMODE):
	_mode = newmode
	%btnEdit.visible = _mode == ENTRYMODE.LISTENTRY
	%PanelVolTest.visible = _mode == ENTRYMODE.AUDIOENTRY

func set_index(index:int):
	_index = index
	%Index.text = "[%0d]"%[index+1] #UI counts from 1, internally count from 0
	%SpinBoxIndex.value = index + 1

func set_text(text:String):
	_text = text
	self.tooltip_text = text
	if _mode == ENTRYMODE.AUDIOENTRY:
		%Text.text = text.get_file().get_basename()
	else:
		%Text.text = text
func set_vol(val:int):
	_on_slid_vol_value_changed(val)
	%slidVol.value = val
func get_vol()->int:
	return %slidVol.value

func get_text()->String:
	return _text

func _on_delete_pressed():
	emit_signal("delete", _index)

func _on_spin_box_index_value_changed(value):
	var v:int = int(value -1)
	emit_signal("move", _index, v)

func _on_btn_edit_pressed():
	emit_signal("edit", _index)

func _on_btn_playstop_pressed():
	emit_signal("playstop", _text, %slidVol.value)

func _on_slid_vol_value_changed(value):
	%txtVol.text = "%3d %%" % [value]

func set_trashed(value:bool):
	if value:
		self.theme = load("res://theme/deletedTheme.tres")
	else:
		self.theme = load("res://theme/playlistTheme.tres")
	
