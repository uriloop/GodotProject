extends Label

sync func return_to_lobby():
	for child in Persistent_nodes.get_children():
		if child.is_in_group("Enemy"):
			Persistent_nodes.get_node(child.name).queue_free()
	get_tree().change_scene("res://Network_setup.tscn")
			

func _on_Win_timer_timeout():
	
	rpc("return_to_lobby")

