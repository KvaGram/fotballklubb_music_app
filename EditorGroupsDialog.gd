extends AcceptDialog

const reserved_names:PackedStringArray = ["TRASH"]
var groups:PackedStringArray
var buttons:Array[CheckBox]

signal bad_group_name(name:String)

func clearAndUpdate(groups:PackedStringArray):
	for c in %listGroups.get_children():
		c.free()
	buttons.clear()
	self.groups = groups
	for g in groups:
		var btn:CheckBox = CheckBox.new()
		btn.text = g
		%listGroups.add_child(btn)
		buttons.append(btn)
	%txtNewGroup.text = ""
	#generate a new group name. Tries 200 times max.
	for i in range(200):
		var n:String = "ny gruppe %d"%[i]
		if not n in groups:
			%txtNewGroup.text = n
			break

func select(index:int):
	buttons[index].button_pressed = true

func selectByName(group:String):
	if group in groups:
		select(groups.find(group))

func deselect(index:int):
	buttons[index].button_pressed = false

func deselectByName(group:String):
	if group in groups:
		deselect(groups.find(group))
	
func getSelected()->Array[String]:
	var selected:Array[String] = []
	for i in range(groups.size()):
		if buttons[i].button_pressed:
			selected.append(groups[i])
	return selected

func _on_add_group():
	var n:String = %txtNewGroup.text
	#sigh.. if adding existing group, just select it.
	if n in groups:
		deselectByName(n)
		return
	#if name is bad or reserved, reject it and report.
	if n.length() < 2 or n in reserved_names:
		emit_signal("bad_group_name", n)
		return
	#finally, add the group.
	var btn:CheckBox = CheckBox.new()
	btn.text = n
	btn.button_pressed = true
	%listGroups.add_child(btn)
	buttons.append(btn)
