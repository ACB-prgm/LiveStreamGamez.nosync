extends PanelContainer


const ALPHA_VALUE = 0.5
const BASE_XP_GAIN = 100

var current_stream = ""
var playerTSCN = preload("res://ChatXP/ChatPlayer/ChatPlayer.tscn")
var ChatPlayerData = {
	"user" : {}
}
var default_player_info = {
	"user" : "Default",
	"icon" : null,
	"level": 1,
	"level_xp" : 0,
	"last_stream" : "",
	"num_comments" : 0
}

onready var chatBox = $VBoxContainer/ScrollContainer/ChatVBoxContainer
onready var tween = $Tween
onready var chat_timer = $Timer


func _ready():
	modulate.a = ALPHA_VALUE
	var data = load_player_data()
	if data:
		ChatPlayerData = data
# warning-ignore:return_value_discarded
	GetPythonChatScrape.connect("chat_packet_recieved", self, "_on_chat_packet_recieved")
	
	# TESTING
#	_on_chat_packet_recieved([["Joe", "hello"], ["Rickle", "howdy"], ["Joe", "hey now"], ["Joe", "level up!"]])


func _on_chat_packet_recieved(chat:Array):
	modulate.a = 1
	
	for comment in chat:
		var current_stream = YoutTubeApi.LiveBroadcastResource.get("snippet").get("title")
		var user = comment[0]
		comment = comment[1]
		
		var info : Dictionary
		if user in ChatPlayerData.keys():
			info = ChatPlayerData[user]
		else:
			info = default_player_info.duplicate()
			info["user"] = user
		
		if info["last_stream"] == current_stream:
			info["num_comments"] += 1
		else:
			info["last_stream"] = current_stream
		
		var anim_info = {
			"user" : user,
			"comment" : comment,
			"icon" : info.get("icon"),
			"level" : info.get("level"),
			"level_xp" : info.get("level_xp"),
			"xp_gain" : 0,
			"level_up" : false
		}
		var bonus_xp = clamp(BASE_XP_GAIN * (info.get("num_comments")-1) * 0.25, 0, 300)
		var xp_gain = BASE_XP_GAIN + bonus_xp
		# CHECK IF LEVEL UP
		prints(user, xp_gain + info.get("level_xp"))
		if xp_gain + info.get("level_xp") > TaskManagerGlobals.LEVEL_INFO.get(info.get("level")):
			info["level_xp"] = xp_gain
			xp_gain = TaskManagerGlobals.LEVEL_INFO.get(info.get("level")) - (info.get("level_xp") + xp_gain)
			info["level"] += 1
			anim_info["level_up"] = true
		else:
			info["level_xp"] += xp_gain
		
		anim_info["xp_gain"] = info.get("level_xp")
		ChatPlayerData[user] = info
		spawn_chatPlayer(anim_info)
		chat_timer.start()
		yield(chat_timer, "timeout")


func spawn_chatPlayer(anim_info):
	var playerINS = playerTSCN.instance()
	
	playerINS.anim_info = anim_info
	
	playerINS.connect("player_fading", self, "_on_player_fading")
	chatBox.add_child(playerINS)
	chatBox.move_child(playerINS, 0)


func _on_player_fading():
	if chatBox.get_child_count() <= 1:
		tween.interpolate_property(self, "modulate:a", modulate.a, ALPHA_VALUE, 
		0.5, Tween.TRANS_SINE, Tween.EASE_OUT)
		tween.start()

# SAVING
const SAVE_DIR = 'user://ChatPlayers/'

func save_data():
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

func load_player_data():
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


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_data()
		get_tree().quit() # default behavior
