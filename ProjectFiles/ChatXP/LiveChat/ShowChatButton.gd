extends Button


const A_VALUE := 0.25
const TWEEN_TIME := 0.25

onready var tween := $Tween


func _ready():
	modulate.a = A_VALUE


func _on_Button_mouse_entered():
	tween.interpolate_property(self, "modulate:a", modulate.a, 1.0, 
	TWEEN_TIME, Tween.TRANS_SINE, Tween.EASE_OUT)
	tween.start()
	

func _on_Button_mouse_exited():
	tween.interpolate_property(self, "modulate:a", modulate.a, A_VALUE, 
	TWEEN_TIME, Tween.TRANS_SINE, Tween.EASE_IN)
	tween.start()
