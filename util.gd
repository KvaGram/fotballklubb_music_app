extends Node
#singleton utility static class
class_name util

func load_audio(path:String)->AudioStream:
	var file:FileAccess = FileAccess.open(path, FileAccess.READ)
	var stream:AudioStream
	if not file:
		printerr("file not found")
		return
	if path.get_extension() == "mp3": # .ends_with(".mp3"):
		stream = AudioStreamMP3.new()
		stream.data = file.get_buffer(file.get_length())
	elif path.get_extension() == "wav": #.ends_with(".wav"):
		stream = AudioStreamWAV.new()
		#stream.set_data(file.get_buffer(file.get_length()))
		#return stream
		
		#Hardcoded. Need to know where to set.
		stream.format = stream.FORMAT_16_BITS
		
		#header data
		var hd:int
		var hds:String
		
		#print("Parsing wav header...")
		#parsing header
		hds = ""
		#hd=file.get_32() #expect ASCII literal RIFF. ignored
		hds = get8bitCharStringFromfile(file, 4)
		#print(hds)
		hd=file.get_32() #expect filesize. ignored
		#print("wav filesize: %d"%[hd])
		#hd=file.get_32() #WAV description header in ASCII. ignored
		hds = get8bitCharStringFromfile(file, 4)
		#print(hds)
		hds = get8bitCharStringFromfile(file, 4)
		#print(hds)
		hd=file.get_32() #chunk size. normaly 16
		#print("wav chunk size: %d"%[hd])
		hd=file.get_16() #Wav type format. ???
		#print("wav format: %d"%[hd])
		hd=file.get_16() #number of audio channels print("wav byte rate: %d"%[hd])
		#print("wav channels: %d"%[hd])
		stream.stereo = hd > 1
		hd=file.get_32() #sample rate
		#print("wav sample rate: %d"%[hd])
		hd=file.get_32() #byte rate
		#print("wav byte rate: %d"%[hd])
		hd=file.get_16() #block allign
		#print("wav block align: %d"%[hd])
		hd=file.get_16() #bytes per sample
		#print("wav bytes per sample: %d"%[hd])
		#hd=file.get_32() #expect ASCII literal DATA. ignored
		hds = get8bitCharStringFromfile(file, 4)
		#print(hds)
		hd=file.get_32() #bytesize of data
		#print("wav data size: %d"%[hd])
		#print("Finished reading wav header")
		stream.data = file.get_buffer(hd)
		
	#elif path.get_extension() == "ogg": #.ends_with(".ogg"):
	#	stream = AudioStreamOggVorbis.new()
	#	stream.data = file.get_buffer(file.get_length())
	file = null #closes file 
	return stream
	
func tosecminString(sec) -> String:
	var s:int = int(sec) % 60
	var m:int = int(sec) / 60
	return "%02d:%02d" % [m, s]

func get8bitCharStringFromfile(file:FileAccess, len:int) -> String:
	var s:String = ""
	for i in len:
		s += char(file.get_8())
	return s
