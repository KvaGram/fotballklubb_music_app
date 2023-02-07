extends HBoxContainer

var _index:int
var _text:String
var _showEdit:bool = false

signal delete(index:int)
signal edit(index:int)
signal move(fromIndex:int, toIndex:int)

func set_index(index:int):
	_index = index
	%Index.text = "[%0d]"%[index+1] #UI counts from 1, internally count from 0
	%SpinBoxIndex.value = index + 1

func set_path(path:String):
	_text = path
	%Path.text = path.get_file().get_basename()
	self.tooltip_text = path
	setShowEdit(false)
func set_name(name:String):
	_text = name
	%Path.text = name
	self.tooltip_text = name
	setShowEdit(true)

func setShowEdit(val:bool):
	_showEdit = val
	%btnEdit.visible = val


func _on_delete_pressed():
	emit_signal("delete", _index)


func _on_spin_box_index_value_changed(value):
	var v:int = int(value -1)
	emit_signal("move", _index, v)
