extends Node
#singleton utility static class
class_name util

func load_audio(path:String)->AudioStream:
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	var stream:AudioStream
	if path.get_extension() == "mp3": # .ends_with(".mp3"):
		stream = AudioStreamMP3.new()
		stream.data = file.get_buffer(file.get_length())
	elif path.get_extension() == "wav": #.ends_with(".wav"):
		stream = AudioStreamWAV.new()
		stream.stereo = true
		stream.format = stream.FORMAT_16_BITS
		stream.data = file.get_buffer(file.get_length())
	#elif path.get_extension() == "ogg": #.ends_with(".ogg"):
	#	stream = AudioStreamOggVorbis.new()
	#	stream.data = file.get_buffer(file.get_length())
	file = null #closes file 
	return stream
	
func tosecminString(sec) -> String:
	var s:int = int(sec) % 60
	var m:int = int(sec) / 60
	return "%02d:%02d" % [m, s]
