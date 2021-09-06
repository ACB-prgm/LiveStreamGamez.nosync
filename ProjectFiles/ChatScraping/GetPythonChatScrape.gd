extends Node

const UDP_IP = "127.0.0.1"
const UDP_PORT = 4243

var server := UDPServer.new()
var ip_address : String
var is_broadcasting := false
var process_pids := []

onready var global_path_to_dir = ProjectSettings.globalize_path("res://ChatScraping")


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if is_broadcasting:
			kill_processes()
		get_tree().quit() # default behavior


func _ready():
	set_process(false)
	start_listening()
	start_keyboard_input()


func _process(_delta):
# warning-ignore:return_value_discarded
	server.poll()
	if server.is_connection_available():
		var peer : PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet().get_string_from_utf8()
		packet = JSON.parse(packet).result
		
		if packet is Array:
			var py_type = packet.pop_front()
			
			match py_type:
				"PIDs":
					process_pids.append_array(packet)
				"CHAT":
					print(packet)
				"KEY_INPUT":
					print(packet)
		else:
			push_error("ERROR : PYTHON TYPE RECIEVED IS NOT TYPE ARRAY")


func start_listening():
# warning-ignore:return_value_discarded
	server.listen(UDP_PORT)
	set_process(true)
	
	is_broadcasting = true


func stop_listening():
	server.stop()
	set_process(false)
	
	is_broadcasting = false


func start_scraping():
	var PID = OS.execute("/usr/local/bin/python3.9", [global_path_to_dir + "/YouTubeScrape.py"], false)
	process_pids.append(float(PID))


func start_keyboard_input():
	var PID = OS.execute("sudo", ["/usr/local/bin/python3.9", global_path_to_dir + "/KeyboardInput.py"], false)
	OS.execute(str(PID), ["REB@6312"])
	process_pids.append(PID)


func kill_processes():
	for pid in process_pids:
# warning-ignore:return_value_discarded
		OS.kill(pid)
