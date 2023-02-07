extends Control
var config:ConfigFile
var _config_path:String = "user://listdata.cfg"
var dir:String = ""
var playlistdata = {}
@export var max_filedepth = 2 #How many levels of subdirectories the fileexplorer will explore. At 0, only the base directory will show, no subdirectories.
@export var ignore_nonmusic = false #hides filetypes not in SUPPORTED

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
		pass #add to active element
	else:
		#Presume it is a folder, attempt to navigate to it
		var dir:DirAccess = DirAccess.open(path)
		if dir:
			openDir(dir.get_current_dir())
	
	
#Recursively gets the full path of a TreeItem, presuming text index 0 is the file/dir name, and root contains full a valid path.
func getpathTreeitem(item:TreeItem)-> String:
	if not item:
		return ""
	return getpathTreeitem(item.parent).path_join(item.get_text(0))
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
