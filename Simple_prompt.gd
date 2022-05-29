extends Control
# cuando pressionas el boton ok
func _on_Ok_pressed():
	get_tree().change_scene("res://Network_setup.tscn")
# Asignar el texto de label
func set_text(text) -> void:
	$Label.text = text
