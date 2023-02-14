extends MarginContainer

#Used for listing screen elements for editing, and playlist entries.

var _index:int
var _text:String
var _showEdit:bool

signal delete(index:int)
signal edit(index:int)
signal move(fromIndex:int, toIndex:int)

func set_index(index:int):
	_index = index
	%Index.text = "[%0d]"%[index+1] #UI counts from 1, internally count from 0
	%SpinBoxIndex.value = index + 1

func set_text(text:String, ispath:bool):
	_text = text
	self.tooltip_text = text
	if ispath:
		%Text.text = text.get_file().get_basename()
	else:
		%Text.text = text

func get_text()->String:
	return _text

func setShowEdit(val:bool):
	_showEdit = val
	%btnEdit.visible = val


func _on_delete_pressed():
	emit_signal("delete", _index)


func _on_spin_box_index_value_changed(value):
	var v:int = int(value -1)
	emit_signal("move", _index, v)


func _on_btn_edit_pressed():
	emit_signal("edit", _index)
