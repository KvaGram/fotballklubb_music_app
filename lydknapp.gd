extends Button

signal play(lyd)

var lyd:String = ""
func on_pressed():
	emit_signal("play", lyd)
