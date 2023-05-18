extends TabContainer


onready var icon_container := $IconScrollContainer/VBoxContainer

var icons := [[load("res://icon.png"), "Default", 0]]
var icon_button = preload("res://Scenes/Buttons/IconButton.tscn")
var player_info : Dictionary setget set_player_info
var timer = Timer.new()

signal icon_selected(button)
signal player_info_updated(info)


func _ready():
	add_child(timer)
	timer.set_wait_time(0.1)
	timer.set_one_shot(true)


func _on_ChatAppearanceCustomizer_info_received(info):
	set_player_info(info)
	load_icons()


func set_player_info(info) -> void:
	if !info.get("appearance", {}).get("bg"):
		info["appearance"]["bg"] = {}
	player_info = info


func _on_OptionsContainer_option_selected(option):
	set_current_tab(option)


# ICONS ————————————————————————————————————————————————————————————————————————
func _on_icon_selected(button:Button) -> void:
	emit_signal("icon_selected", button)
	player_info["appearance"]["icon"] = button._icon.get_data().data
	emit_signal("player_info_updated", player_info)

func load_icons() -> void:
	if icon_container.get_child_count() > 0:
		return
	var icon_path := "res://Images/Icons/"
	var dir := Directory.new()
	
	if dir.open(icon_path) == OK:
		var _err = dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !(is_in(file_name, [".", "..", ".DS_Store"]) or ".import" in file_name or dir.current_is_dir()):
				var texture = load(icon_path.plus_file(file_name))
				var info = file_name.replace(".png", "").split("+")
				var lvl = int(info[-1])
				var icon_name = title_case(info[0].replace("-", " "))
				
				icons.append([texture, icon_name, lvl])
			file_name = dir.get_next()
		
		icons.sort_custom(self, "sort_icon")
		
	else:
		print("An error occurred when trying to access the path.")
	
	# populate icons
	var player_level = player_info["progression"]["level"]
	for icon in icons:
		var button = icon_button.instance()
		button.connect("pressed", self, "_on_icon_selected", [button])
		var _err = connect("icon_selected", button, "_on_other_pressed")
		icon_container.add_child(button)
		button.populate_info(icon[0], icon[1], icon[2])
		
		if player_level < icon[2]:
			button.set_disabled(true)

func sort_icon(a, b) -> bool:
	return a[2] < b[2]

func is_in(string:String, equals:PoolStringArray) -> bool:
	for x in equals:
		if x == string:
			return true
	return false

func title_case(string:String) -> String:
	var final = PoolStringArray()
	var stray = string.split(" ")
	
	for word in stray:
		word[0] = word[0].to_upper()
		final.append(word)
	
	return final.join(" ")


# INFO COLOR ———————————————————————————————————————————————————————————————————
func _on_InfoColorPicker_color_changed(color:Color):
	player_info["appearance"]["info_color"] = color.to_html()
	emit_signal("player_info_updated", player_info)


# XP BAR COLOR —————————————————————————————————————————————————————————————————
func _on_XPBarColorPicker_color_changed(color):
	player_info["appearance"]["xp_bar_color"] = color.to_html()
	emit_signal("player_info_updated", player_info)


# BACKGROUND ———————————————————————————————————————————————————————————————————
func _on_OUTLINE_color_changed(color):
	player_info["appearance"]["bg"]["outline"] = color.to_html()
	emit_signal("player_info_updated", player_info)




