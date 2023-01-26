extends HBoxContainer

var _index:int
var _path:String

signal delete(index:int)

func set_index(index:int):
	_index = index
	%Index.text = "[%0d]"%[index+1] #UI counts from 1, internally count from 0

func set_path(path:String):
	_path = path
	%Path.text = path.get_file().get_basename()
	self.tooltip_text = path

func _on_delete_pressed():
	emit_signal("delete", _index)
