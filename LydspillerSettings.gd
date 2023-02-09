extends Control
var config:ConfigFile
var _config_path:String = "user://listdata.cfg"
var dir:String = ""
var playlistdata = {}
@export var max_filedepth = 2 #How many levels of subdirectories the fileexplorer will explore. At 0, only the base directory will show, no subdirectories.
@export var ignore_nonmusic = false #hides filetypes not in SUPPORTED
@onready var playlistentryedit:PackedScene = preload("res://playlistentryedit.tscn")

const SUPPORTED:PackedStringArray = ["mp3", "wav"]
# Called when the node enters the scene tree for the first time.
func _ready():
	config = ConfigFile.new()
	var status:int = config.load(_config_path)
	if status == OK:
		dir = config.get_value("lastused", "test_dir", "")
		playlistdata = config.get_value("playlists", "lists", {})
	if dir != "":
		openDir(dir)
	else:
		openDir(OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)) #open OS music directory by default.
	if playlistdata.size() > 0:
		pass #todo set up playlists in editpanel
	else:
		pass #todo start editing a new playlist? I don't know.. something, I guess.
	
	#remove example nodes
	clearEditor()
	for c in %boxListElements.get_children():
		c.free()
#End of _ready
func _openHelp():
	%Help.popup_centered(Vector2i(800,400))


#Tree functions

func popTreeRecursive(depth:int, localdir:DirAccess, parent:TreeItem):
	localdir.list_dir_begin()
	var end:bool = depth >= max_filedepth
	while true:
		var f:String = localdir.get_next()
		if f.is_empty():
			break
		print(f)
		var isDir:bool = localdir.current_is_dir()
		var isAudio:bool = f.get_extension() in SUPPORTED
		if ignore_nonmusic and not isAudio and not isDir:
			#Skip if not a directory nor supported audiofile
			continue
		var child:TreeItem = parent.create_child()
		child.set_text(0, f)
		if localdir.current_is_dir():
			if end:
				child.set_custom_color(0, Color.LIGHT_CORAL)
			else:
				popTreeRecursive(depth+1,  localdir.open(getpathTreeitem(child)), child)
				if child.get_child_count() < 1:
					child.free()#remove empty directories
		elif not isAudio:
			child.set_custom_color(0, Color.LIGHT_CORAL)
	#end of loop

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func openDir(path):
	%Tree.clear()
	var localDir:DirAccess = DirAccess.open(path)
	var root:TreeItem = %Tree.create_item()
	%txtRootName.text = path
	root.set_text(0, path)
	popTreeRecursive(0, localDir, root)
	
func _on_tree_item_activated():
	var item:TreeItem = %Tree.get_selected()
	if not item:
		return
	activateItem(item)

func activateItem(item:TreeItem):
	var path = getpathTreeitem(item)
	if path.get_extension() in SUPPORTED:
		addListEntry(path)
	else:
		#Presume it is a folder, attempt to navigate to it
		var dir:DirAccess = DirAccess.open(path)
		if dir:
			openDir(dir.get_current_dir())
	
	
#Recursively gets the full path of a TreeItem, presuming text index 0 is the file/dir name, and root contains full a valid path.
#func getpathTreeitem(item:TreeItem)-> String:
func getpathTreeitem(item)-> String:
	if not item:
		return ""
	return getpathTreeitem(item.get_parent()).path_join(item.get_text(0))
#opens file dialog to load a new directory
func _on_btn_load_dir_pressed():
	%FileDialog.popup_centered(200,200)
#redirecting to openDir. Kept seperate in case of future input sanitizing is needed.
func _on_file_dialog_dir_selected(path):
	openDir(path)
func _on_btn_up_one_dir_pressed():
	var dir:DirAccess = DirAccess.open(dir)
	if dir.change_dir(".."):
		openDir(dir.get_current_dir())
	pass # Replace with function body.
	
#Editor functions
func populateElementList():
	for n in %boxListElements.get_children():
		n.free()
	var entries:Array = []
	entries.resize(playlistdata.size())
	for e in playlistdata.values():
		var n:Node = playlistentryedit.instantiate()
		var i = e.get("list_index", -1)
		n.set_text(e.get("name", "unnamed list"))
		n.setShowEdit(true)
		if(i < 0):
			entries.append(n)
		else:
			entries[i] = n
	for n in entries:
		if not n:
			continue
		%boxListElements.add_child(n)
		n.move.connect(onMoveListElement)
		n.delete.connect(onDeleteListElement)
		n.edit.connect(onEditListElement)
	updateListContentIndex()
	

func clearEditor():
	for c in %boxListContent.get_children():
		c.free()
	%txtListName.clear()
	
func addListEntry(path:String):
	var n:Node = playlistentryedit.instantiate()
	n.set_text(path, true)
	n.setShowEdit(false)
	n.set_index(%boxListContent.get_child_count())
	%boxListContent.add(n)
	n.delete.connect(onEditorDeleteListContent)
	n.move.connect(onEditorMoveListContent)
	
func saveEditor():
	if not isEditorNameValid():
		return
	#TODO: reimplement override flag?
	#	elif playlistdata.has(name):
#		if not overwrite_flag:
#			%ListNameWarn.visible = true #ERROR! This seem to have passed without holding shift.
#			%ListNameEditBox.tooltip_text = "En spilleliste med det navnet finnes allerede. Trykk igjen for å overskrive"
#			overwrite_flag = true
#			return
	var name = %txtListName.text
	var num = %boxListContent.get_child_count()
	if num < 1:
		return #Can't save empty list
	var list:Array[String] = []
	for c in %boxListContent.get_children():
		list.append(c.get_text())
	var data = {"list" : list, "name" : name}
	if playlistdata.has(name):
		playlistdata[name].merge(data, true) #this preserves metadata if present
	else:
		playlistdata[name] = data
		var n:Node = playlistentryedit.instantiate()
		n.set_text(name, false)
		n.setShowEdit(true)
		n.set_index(%boxListElements.get_child_count())
		%boxListElements.add_child(n)
		n.move.connect(onMoveListElement)
		n.delete.connect(onDeleteListElement)
		n.edit.connect(onEditListElement)
	clearEditor()
	#TODO: SAVE
		
	

func updateListContentIndex():
	for i in range(%boxListContent.get_child_count()):
		%boxListContent.get_child(i).set_index(i)
func onEditorMoveListContent(from, to):
	%boxListContent.move_child(%boxListContent.get_child(from), to)
	updateListContentIndex()
func onEditorDeleteListContent(index):
	var c = %boxListContent.get_child(index)
	%boxListContent.remove_child(c)
	c.queue_free()
	updateListContentIndex()
func isEditorNameValid() -> bool:
	return %txtListName.text.length > 2
func onEditorNameChanged(_text):
	%btnSaveEdit.disabled = not isEditorNameValid()
	
func updateListElementIndex():
	for i in range(%boxListElements.get_child_count()):
		var c = %boxListElements.get_child(i)
		c.set_index(i)
		playlistdata[c.get_text()]["list_index"] = i
func onMoveListElement(from, to):
	%boxListElements.move_child(%boxListElements.get_child(from), to)
	updateListElementIndex()
func onDeleteListElement(index):
	#TODO: add warning?
	var c = %boxListContent.get_child(index)
	playlistdata.erase(c.get_text())
	%boxListContent.remove_child(c)
	c.queue_free()
	updateListContentIndex()
func onEditListElement(index):
	clearEditor()
	var data:Dictionary = playlistdata.get(%boxListContent.get_child(index).get_text(), {})
	%txtListName.text = data.get("name", "")
	for e in data.get("list", []):
		addListEntry(e)
		
	
