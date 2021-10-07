extends CanvasLayer


const LOADING_LENGTH = 9
const REFRESH_FRAME = 4
const LONG_LINE = "—"
const MED_LINE = "–"
const SHORT_LINE = "-"

var kill_obj
var kill_signal : String
var message : String
var frame := 0
var loading_img : PoolStringArray
var bar_pos := 0
var adj := 1

onready var loadingLabel = $ColorRect/Label
onready var messageLabel = $ColorRect/MessageLabel


func _ready():
	if kill_obj:
		kill_obj.connect(kill_signal, self, "die")
	if message:
		messageLabel.set_text(message)


func _physics_process(_delta):
	if frame == REFRESH_FRAME:
		reset_loading_img()
		
		loading_img[bar_pos] = LONG_LINE
		if bar_pos - 1 >= 0:
			loading_img[bar_pos - 1] = MED_LINE
		if bar_pos + 1 <= LOADING_LENGTH - 1:
			loading_img[bar_pos + 1] = MED_LINE
		
		loadingLabel.text = loading_img.join("\n")
		
		frame = 0
		bar_pos += adj
		if bar_pos > LOADING_LENGTH - 1 or bar_pos < 0:
			bar_pos = 0
		if bar_pos in [0, LOADING_LENGTH - 1]:
			adj *= -1
	
	frame += 1


func reset_loading_img():
	loading_img.resize(0)
	for _i in range(LOADING_LENGTH):
		loading_img.append(SHORT_LINE)


func die():
	queue_free()






