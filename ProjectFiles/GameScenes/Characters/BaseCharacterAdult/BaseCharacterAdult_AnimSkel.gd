tool
extends Node2D

var dropdown
var dialogue_preview
var interactable_INS
var interactable_TSCN = preload("res://Scenes/Characters/BaseCharacterAdult/BaseCharacterInteractable.tscn")
var interacting:bool = false

onready var parent = get_parent()
onready var animPlayer = parent.get_node("AnimationPlayer")
onready var animTreePlayback = parent.get_node("AnimationTree").get("parameters/playback")

export var dialogue = ["null"]
export var _texture:StreamTexture = null setget _on_texture_set
export var interactable: bool = false setget set_interactable
export var dialogue_key = "Father_001"
export var dialogue_key_idx= -1
export(String,
	"IDLE",
	"HORIZONTAL",
	"VERTICAL",
	"CIRCLE") var default_movement
export var default_movement_distance: float = 10.0
export var facing_left: bool = false


func _ready():
	get_parent().get_node("AnimationTree").active = true
	dialogue = Dialogue.dict.get(dialogue_key)


# SETTING ANIMATION TEXTURE ————————————————————————————————————————————————————
func _on_texture_set(new_texture):
	_texture = new_texture
	
	reset_child_textures(self, new_texture)


func reset_child_textures(_parent, new_texture):
	if _parent.get_children():
		for child in parent.get_children():
			if child is Sprite:
				child.texture = new_texture
				if child.get_children():
					reset_child_textures(child, new_texture)


# SELECETING DIALOGUE ——————————————————————————————————————————————————————————
func load_dialogue_data():  # Called when this node is selected in the editor
	# if the dialogue has been set previously, loads that past dialogue
	if dialogue_key_idx != -1:
		dropdown.select(dialogue_key_idx)
		_on_dialogue_option_selected(dialogue_key_idx)


func _on_dialogue_option_selected(item):
	# Setget for the plugin dialogue selection
	dialogue_key_idx = item
	dialogue_key = dropdown.get_item_text(item)
	dialogue = Dialogue.dict.get(dialogue_key)
	dialogue_preview.set_text(str(dialogue))


# SETTING INTERACTABLE —————————————————————————————————————————————————————————
func set_interactable(new_value):
	interactable = new_value
	if new_value:
		interactable_INS = interactable_TSCN.instance()
		interactable_INS.connect("interacted", self, "_on_interacted")
		interactable_INS.connect("area_entered", interactable_INS, "_on_BaseCharacterInteractable_area_entered")
		interactable_INS.connect("area_exited", interactable_INS, "_on_BaseCharacterInteractable_area_exited")
		interactable_INS.position = Vector2(0,-325)
		add_child(interactable_INS)
#		interactable_INS.set_owner(get_tree())
	elif interactable_INS:
		interactable_INS.free()


func _on_interacted():
	interacting = true
	var dir_to_char = global_position.direction_to(Globals.player.global_position)
	if facing_left and dir_to_char.x >= 0:
		animPlayer.play("turn_right")
	elif !facing_left and dir_to_char.x < 0:
		animPlayer.play("turn_left")
	else:
		PopupLayer.display_dialogue(dialogue, self)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name in ["turn_left", "turn_right"] and interacting:
		PopupLayer.display_dialogue(dialogue, self)


func _on_dialogue_box_started():
	animTreePlayback.travel("talk")

func _on_dialogue_box_finished():
	interacting = false
	animTreePlayback.travel("movement")
