extends TabContainer


const TIME := 0.75

onready var tween = $Tween


func _on_change_tab(from_obj:Object, to_tab:int):
	tween.interpolate_property(from_obj, "modulate:a", 1, 0, TIME, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()
	
	yield(tween, "tween_all_completed")
	
	var to_obj = get_tab_control(to_tab)
	var must_yield = to_obj.show_tab()
	if must_yield:
		yield(must_yield, "completed")
	
	set_current_tab(to_tab)
	tween.interpolate_property(to_obj, "modulate:a", 0, 1, TIME, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	tween.start()
