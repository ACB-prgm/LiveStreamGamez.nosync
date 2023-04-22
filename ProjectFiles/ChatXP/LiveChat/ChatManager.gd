extends PanelContainer


const SAVE_DIR = 'user://ChatPlayers/'
const ALPHA_VALUE = 0.5
const BASE_XP_GAIN = 100

var current_stream = ""
var playerTSCN = preload("res://ChatXP/ChatPlayer/ChatPlayer.tscn")
var default_player_info = {
	"progression" : {
		"level": 1,
		"level_xp" : 0,
		"last_stream" : "",
		"total_num_comments" : 0, # num lifetime comments
		"current_num_comments" : 0 # num comments on current stream
	},
	"appearance" : {
		"icon" : null
	}
}
var ChatPlayerData = {}

onready var chatBox = $VBoxContainer/ScrollContainer/ChatVBoxContainer
onready var tween = $Tween
onready var chat_timer = $Timer


func _ready() -> void:
	modulate.a = ALPHA_VALUE
	var data = yield(FlaskAPI.get_all_users_info(), "completed")
	if data:
		ChatPlayerData = data
	var _err = GetPythonChatScrape.connect("chat_packet_recieved", self, "_on_chat_packet_recieved")
	
	# TESTING
	_on_chat_packet_recieved([ ["Joe", "hello"], ["Rickle", "howdy"], ["Joe", "hey now"], ["ACB_Gamez", "test"]])


# CHAT FUNCTIONS ———————————————————————————————————————————————————————————————
func _on_chat_packet_recieved(chat:Array) -> void:
	modulate.a = 1
#	current_stream = YoutTubeApi.LiveBroadcastResource.get("snippet").get("title")
	current_stream = "test"
	
	for comment in chat:
		var user = comment[0]
		comment = comment[1]
		
		var info : Dictionary
		if user in ChatPlayerData.keys():
			info = ChatPlayerData[user]
		else:
			info = default_player_info.duplicate()
		
		# UPDATE USER PROGRESSION ————————————————
		var progression_info = info["progression"]
		progression_info["level"] = int(progression_info["level"])
		# Update comment stats
		if progression_info["last_stream"] == current_stream:
			progression_info["current_num_comments"] += 1
		else:
			progression_info["last_stream"] = current_stream
			progression_info["current_num_comments"] = 1
		progression_info["total_num_comments"] += 1
		
		# Update XP
		var bonus_xp = clamp(BASE_XP_GAIN * (progression_info.get("current_num_comments")-1) * 0.25, 0, 300) # reward participation
		var xp_gain = BASE_XP_GAIN + bonus_xp
		var level_up = false
		var level_up_threshold = TaskManagerGlobals.LEVEL_INFO.get(progression_info.get("level"))
		var previous_level_xp = progression_info.get("level_xp")
		var theoretical_level_xp = previous_level_xp + xp_gain
		
		if  theoretical_level_xp > level_up_threshold: # level up!
			level_up = true
			xp_gain = theoretical_level_xp - level_up_threshold
			progression_info["level_xp"] = xp_gain
			progression_info["level"] += 1
		else:
			progression_info["level_xp"] = theoretical_level_xp
		
		ChatPlayerData[user] = info # Update working info
		FlaskAPI.update_user_info(user, info) # Update Cloud info
		
		# DISPLAY CHAT AND UPDATES
		spawn_chatPlayer(user, comment, info, previous_level_xp, xp_gain, level_up)
		chat_timer.start()
		yield(chat_timer, "timeout")


func spawn_chatPlayer(user:String, comment:String, info:Dictionary, previous_xp:float, xp_gain:float, level_up:bool):
	var bar_start_val = previous_xp
	var start_level = info["progression"].get("level")
	if level_up:
		start_level -= 1
	bar_start_val = bar_start_val / TaskManagerGlobals.LEVEL_INFO.get(start_level) * 100
	
	var anim_info = {
			"user" : user,
			"comment" : comment,
			"icon" : info["appearance"].get("icon"),
			"level" : start_level,
			"level_xp" : info["progression"].get("level_xp"),
			"bar_start_val" : bar_start_val,
			"xp_gain" : xp_gain,
			"level_up" : level_up
		}
	
	var playerINS = playerTSCN.instance()
	
	playerINS.anim_info = anim_info
	
	playerINS.connect("player_fading", self, "_on_player_fading")
	chatBox.add_child(playerINS)
	chatBox.move_child(playerINS, 0)


func _on_player_fading() -> void:
	if chatBox.get_child_count() <= 1:
		tween.interpolate_property(self, "modulate:a", modulate.a, ALPHA_VALUE, 
		0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.start()

# SAVE/LOAD FUNCTIONS ——————————————————————————————————————————————————————————
func save_data() -> void:
	var save_path = SAVE_DIR + "Players" + ".dat"
	var dir = Directory.new()
	if !dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)

	var file = File.new()
	var error = file.open(save_path, File.WRITE)
	if error == OK:
		file.store_var(ChatPlayerData)
		file.close()
	else:
		print("ERROR SAVING FILE : %s" % error)

func load_player_data() -> Dictionary:
	var save_path = SAVE_DIR + "Players" + ".dat"
	var data = null
	var file = File.new()
	if file.file_exists(save_path):
		var error = file.open(save_path, File.READ)
		if error == OK:
			data = file.get_var()
			file.close()
		else:
			print("ERROR LOADING FILE : %s" % error)
	return data

# CLEANUP ——————————————————————————————————————————————————————————————————————
func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_data()
		get_tree().quit() # default behavior


#func merge_changes() -> void:
#	# Update local appearance data with aws data and aws progression data with 
#	# local progression data.
#
#	var user_data = yield(FlaskAPI.get_all_users_info(), "completed")
#	for user in user_data: # update aws progression data with local data
#		if user in ChatPlayerData:
#			user_data[user]["progression"] = ChatPlayerData[user]["progression"]
#		else:
#			ChatPlayerData[user] = user_data[user]
#	ChatPlayerData = user_data # update local appearance data with aws data
#
#	FlaskAPI.update_all_users_info(user_data)
