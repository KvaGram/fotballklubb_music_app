extends Control
var config:ConfigFile
var _config_path:String = "user://listdata.cfg"
var currentPath:String = ""
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
		currentPath = config.get_value("lastused", "dir", "")
		playlistdata = config.get_value("playlists", "lists", {})
	if currentPath != "":
		openDir(currentPath)
	else:
		openDir(OS.get_system_dir(OS.SYSTEM_DIR_MUSIC)) #open OS music directory by default.
	#clean and ready input lists and editing fields
	clearEditor()
	populateElementList()
	#Do not auto accept quit request
	get_tree().set_auto_accept_quit(false)
#End of _ready
func _notification(what):
	#When quit request is recived, run save_data, then comply.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print("Goodbye world")
		save_data()
		get_tree().quit() #closes application

func _openHelp():
	%Help.popup_centered(Vector2i(800,400))
	
func save_data():
	config.set_value("playlists", "lists", playlistdata)
	config.set_value("lastused", "dir", currentPath)
	config.save(_config_path)

func onPlaystop(path:String, vol:int):
	#%AudioStreamPlayer
	pass #todo testplayer

#Tree functions

func popTreeRecursive(depth:int, localdir:DirAccess, parent:TreeItem):
	localdir.list_dir_begin()
	var end:bool = depth >= max_filedepth
	while true:
		var f:String = localdir.get_next()
		if f.is_empty():
			break
		#print(f)
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
				popTreeRecursive(depth+1,  DirAccess.open(getpathTreeitem(child)), child)
				if child.get_child_count() < 1:
					child.free()#remove empty directories
		elif not isAudio:
			child.set_custom_color(0, Color.LIGHT_CORAL)
	#end of loop

func openDir(path):
	%Tree.clear()
	var localDir:DirAccess = DirAccess.open(path)
	var root:TreeItem = %Tree.create_item()
	%txtRootName.text = path
	root.set_text(0, path)
	currentPath = path
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
		var d:DirAccess = DirAccess.open(path)
		if d:
			openDir(d.get_current_dir())
	
	
#Recursively gets the full path of a TreeItem, presuming text index 0 is the file/folder name, and root contains full a valid path.
#func getpathTreeitem(item:TreeItem)-> String:
func getpathTreeitem(item)-> String:
	if not item:
		return ""
	return getpathTreeitem(item.get_parent()).path_join(item.get_text(0))
#opens file dialog to load a new directory
func _on_btn_load_dir_pressed():
	%FileDialog.popup_centered(Vector2i(200,500))
#redirecting to openDir. Kept seperate in case of future input sanitizing is needed.
func _on_file_dialog_dir_selected(path):
	openDir(path)
func _on_btn_up_one_dir_pressed():
	var d:DirAccess = DirAccess.open(currentPath)
	var err = d.change_dir("..")
	if err == OK:
		openDir(d.get_current_dir())
	else:
		printerr("Error moving up one directory: " + err)

#Editor functions
func populateElementList():
	for n in %boxListElements.get_children():
		%boxListElements.remove_child(n)
		n.queue_free()
	var entries:Array = []
	entries.resize(playlistdata.size())
	for e in playlistdata.values():
		var n:Node = playlistentryedit.instantiate()
		var i = e.get("list_index", -1)
		n.set_mode(PlaylistEntry.ENTRYMODE.LISTENTRY)
		n.set_text(e.get("name", "unnamed list"))
		if(i < 0 or i > entries.size()):
			entries.append(n) #in the event of indecies missing or out of range
		elif entries[i]: #in case of indicies somehow overlapping
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
	updateListElementIndex() #in case of above index error, said error will be corrected here.
	

func clearEditor():
	for c in %boxListContent.get_children():
		c.free()
	%txtListName.clear()
	
func addListEntry(path:String):
	var n:Node = playlistentryedit.instantiate()
	n.set_mode(PlaylistEntry.ENTRYMODE.AUDIOENTRY)
	n.set_text(path)
	n.set_index(%boxListContent.get_child_count())
	%boxListContent.add_child(n)
	n.delete.connect(onEditorDeleteListContent)
	n.move.connect(onEditorMoveListContent)
	n.playstop.connect(onPlaystop)
	
func saveEditor():
	if not isEditorNameValid():
		return
	#TODO: reimplement override flag?
	#	elif playlistdata.has(listname):
#		if not overwrite_flag:
#			%ListNameWarn.visible = true #ERROR! This seem to have passed without holding shift.
#			%ListNameEditBox.tooltip_text = "En spilleliste med det navnet finnes allerede. Trykk igjen for å overskrive"
#			overwrite_flag = true
#			return
	var listname = %txtListName.text
	var num = %boxListContent.get_child_count()
	if num < 1:
		return #Can't save empty list
	var list:Array[String] = []
	var vol:Array[int] = []
	for c in %boxListContent.get_children():
		list.append(c.get_text())
		vol.append(c.get_vol())
	var data = {"list" : list, "name" : listname, "volume" : vol}
	if playlistdata.has(listname):
		playlistdata[listname].merge(data, true) #this preserves metadata if present
	else:
		playlistdata[listname] = data
		var n:Node = playlistentryedit.instantiate()
		n.set_mode(PlaylistEntry.ENTRYMODE.LISTENTRY)
		n.set_text(listname)
		n.set_index(%boxListElements.get_child_count())
		%boxListElements.add_child(n)
		n.move.connect(onMoveListElement)
		n.delete.connect(onDeleteListElement)
		n.edit.connect(onEditListElement)
	clearEditor()
	updateListElementIndex()
	save_data()

	

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
	return %txtListName.text.length() > 2
	
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
	var c = %boxListElements.get_child(index)
	if not c:
		_panicRepopulateElements("onDeleteListElement")
		return
	playlistdata.erase(c.get_text())
	%boxListElements.remove_child(c)
	c.queue_free()
	updateListElementIndex()
	
func onEditListElement(index):
	clearEditor()
	var data:Dictionary = playlistdata.get(%boxListElements.get_child(index).get_text(), {})
	%txtListName.text = data.get("name", "")
	for e in data.get("list", []):
		addListEntry(e)
		
func _panicRepopulateElements(callername):
	printerr("Something went wrong with " + callername + " Re-populating element list.")
	populateElementList()


func switchToPlayScene():
	save_data()
	get_tree().change_scene_to_file("res://lydspiller_panel.tscn")
