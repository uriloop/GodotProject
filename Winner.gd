extends Label

sync func return_to_lobby():
	get_tree().change_scene("res://Network_setup.tscn")

func _on_Win_timer_timeout():
	if get_tree().is_network_server():
		for child in Persistent_nodes.get_children():
			if child.is_in_group("Enemy"):
				rpc("borrar",child.name)
	rpc("return_to_lobby")

sync func borrar(enemigo):
	Persistent_nodes.get_node(enemigo).queue_free()
