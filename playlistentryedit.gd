extends HBoxContainer

var _index:int
var _path:String

signal delete(index:int)
signal move(fromIndex:int, toIndex:int)

func set_index(index:int):
	_index = index
	%Index.text = "[%0d]"%[index+1] #UI counts from 1, internally count from 0
	%SpinBoxIndex.value = index + 1

func set_path(path:String):
	_path = path
	%Path.text = path.get_file().get_basename()
	self.tooltip_text = path

func _on_delete_pressed():
	emit_signal("delete", _index)


func _on_spin_box_index_value_changed(value):
	var v:int = int(value -1)
	emit_signal("move", _index, v)
