extends Control

@export var disabled:bool
@export var color:Color
@onready var spectrum:AudioEffectSpectrumAnalyzerInstance = AudioServer.get_bus_effect_instance(1,0,0)

#based on https://www.youtube.com/watch?v=5z9uuU0xVX4
const VU_COUNT:float = 1024
const FREQ_STEP:float = 11050 / VU_COUNT
const MIN_DB:float = 60
const SCALE:float = 10

func _process(_delta):
	queue_redraw()

#draws a representation of the audio playing.
func _draw():
	if disabled:
		return
	var box = get_rect().size
	var w:float = box.x / VU_COUNT
	var prev_hz:int = 0
	for i in range(1,VU_COUNT+1):
		#hertz
		var hz:float = i * FREQ_STEP#FREQ_MAX / VU_COUNT
		#Frequency at range
		var f:Vector2 = spectrum.get_magnitude_for_frequency_range(prev_hz,hz)
		#bar heights
		var h:float = clamp(box.y * absf(f.length() * SCALE), 0, box.y)
		draw_rect(Rect2(w*i, box.y - h, w, h), color)
		prev_hz = hz
	
	
	
