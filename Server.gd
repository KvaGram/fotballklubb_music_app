extends Node

var server:TCPServer
var conns:Array[StreamPeerTCP]
var connsT:Array

signal list_data_requested(connection, index)
signal list_data_all_requested(connection)
signal play_list_requested(connection, index)
signal stop_audio_requested(connection)

@export var port:int = 9080
@export var timeout:int = 600 #defaults 10 minutes

func start():
	if server:
		if server.is_listening():
			stop()
	else:
		server = TCPServer.new()
	server.listen(port)
	conns = []
func stop():
	if not server:
		return
	server.stop()

func _ready():
	start()

func _process(delta):
	if server.is_connection_available():
		conns.append(server.take_connection()) #add connection refrence
		connsT.append(0) #add timeout timer for connection
	var toRemove = [] #Stack. Last in is first out. index of connections to remove after processing
	var i = -1 #index of current connection
	#processing connections
	for c in conns:
		i+=1
		var status = c.get_status() 
		if status != 2: #connected
			printerr("Connection %s unexpexted status: %s" % [i, status])
		if(connsT[i] > timeout): #any reason to disconnect, timeout
			toRemove.push_front(i)
			continue
		connsT[i] += delta #add to time since last message
		var bytes = c.get_available_bytes()
		if bytes > 0:
			connsT[i] = 0
			_parseMessage(c.get_string(bytes), c)
	for r in toRemove:
		conns[r].disconnect_from_host()
		conns.remove_at(r)
		connsT.remove_at(r)
		
func _parseMessage(m:String, c:StreamPeerTCP):
	print(m, c)
	var args = m.split(" ", false)
	if args.size() < 1:
		return
	match args[0]:
		"list_data":
			if args.size() > 1 and args[1].is_valid_int():
				emit_signal("list_data_requested", c, args[1].to_int())
			else:
				print("bad request for list_data: ( %s ) from %s"%[m, c])
				send_string(c, "Error. Bad or missing index. Echo: " + m)
		"play_list":
			if args.size() > 1 and args[1].is_valid_int():
				emit_signal("play_list_requested", c, args[1].to_int())
			else:
				print("bad request for play_list: ( %s ) from %s"%[m, c])
				send_string(c, "Error. Bad or missing index. Echo: " + m)
		"list_data_all":
			emit_signal("list_data_all_requested", c)
		"stop_audio":
			emit_signal("stop_audio_requested", c)
		"_":
			printerr("bad request: ( %s ) from %s"%[m, c])
			send_string(c, "Error. No matching command. Echo: " + m)
			
func send_string(c:StreamPeerTCP, m:String):
	c.put_string(m)
#sends one playlist/button data
func send_listdata(c:StreamPeerTCP, data:Dictionary):
	c.put_var(data, true) 
#sends all the playlists/buttons data
func send_all_listdata(c:StreamPeerTCP, data:Dictionary):
	c.put_var(data, true) #test result: not satisfactory. must format manually.
