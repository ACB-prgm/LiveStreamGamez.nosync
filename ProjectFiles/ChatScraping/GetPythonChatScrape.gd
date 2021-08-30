extends Node

const UDP_IP = "127.0.0.1"
const UDP_PORT = 4243

var server := UDPServer.new()
var ip_address : String
var is_broadcasting := false
var process_pids := []


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		if is_broadcasting:
			stop_scraping()
		get_tree().quit() # default behavior


func _ready():
	set_process(false)
	start_scraping()


func _process(_delta):
# warning-ignore:return_value_discarded
	server.poll()
	if server.is_connection_available():
		var peer : PacketPeerUDP = server.take_connection()
		var packet = peer.get_packet().get_string_from_utf8()
		packet = JSON.parse(packet).result
		
		if typeof(packet[0]) == TYPE_REAL:
			process_pids.append_array(packet)
		else:
			print(packet)


func start_listening():
# warning-ignore:return_value_discarded
	server.listen(UDP_PORT)
	set_process(true)
	
	is_broadcasting = true
 

func start_scraping():
	var PID = OS.execute("/usr/local/bin/python3.9", [ProjectSettings.globalize_path("res://ChatScraping") + "/YouTubeScrape.py"], false)
	process_pids.append(float(PID))
	start_listening()


func stop_scraping():
	stop_listening()
	
	for pid in process_pids:
# warning-ignore:return_value_discarded
		OS.kill(pid)


func stop_listening():
	server.stop()
	set_process(false)
	
	is_broadcasting = false
