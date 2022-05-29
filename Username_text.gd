extends Node2D

var player_following = null
var text = "" setget text_set

onready var label = $Label

func _process(_delta: float) -> void:
	# cuando el player following no es nulo
	if player_following != null:
		global_position = player_following.global_position
# Asignar el text del nombre de player
func text_set(new_text) -> void:
	text = new_text
	label.text = text
