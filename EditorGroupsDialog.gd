extends AcceptDialog

const reserved_names:PackedStringArray = ["TRASH", "ALLE", "INGEN"]
var groups:PackedStringArray
var n_groups:Array
var buttons:Array[CheckBox]

signal bad_group_name(name:String)

func clearAndUpdate(new_groups:PackedStringArray):
	for c in %listGroups.get_children():
		c.free()
	buttons.clear()
	n_groups.clear()
	groups = new_groups
	for g in groups:
		var btn:CheckBox = CheckBox.new()
		btn.text = g
		%listGroups.add_child(btn)
		buttons.append(btn)
	generateGroupName()
	
#generate a new group name. Tries 200 times max
func generateGroupName():
	%txtNewGroup.text = ""
	for i in range(200):
		var n:String = "ny gruppe %d"%[i]
		if not n in groups and n not in n_groups:
			%txtNewGroup.text = n
			break

func select(index:int):
	buttons[index].button_pressed = true

func selectByName(group:String)->bool:
	if group in groups:
		select(groups.find(group))
		return true
	if group in n_groups:
		select(n_groups.find(group)+groups.size())
		return true
	return false

func deselect(index:int):
	buttons[index].button_pressed = false

func deselectByName(group:String):
	if group in groups:
		deselect(groups.find(group))
		return true
	if group in n_groups:
		deselect(n_groups.find(group)+groups.size())
		return true
	return false
func getSelected()->Array[String]:
	var selected:Array[String] = []
	for i in range(buttons.size()):
		if buttons[i].button_pressed:
			selected.append(buttons[i].text)
	return selected

func _on_add_group():
	var n:String = %txtNewGroup.text
	#if name is bad or reserved, reject it and report.
	if n.length() < 2 or n in reserved_names:
		emit_signal("bad_group_name", n)
		return
	#sigh.. if adding existing group, just select it.
	if n in groups:
		deselectByName(n)
		return
	#if n exist as a group name, select it.
	if selectByName(n):
		return
	#finally, add the group.
	n_groups.append(n)
	var btn:CheckBox = CheckBox.new()
	btn.text = n
	btn.button_pressed = true
	%listGroups.add_child(btn)
	buttons.append(btn)
	generateGroupName()
