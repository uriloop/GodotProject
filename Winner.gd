extends Label
# Hecha todos los enemigos de la partida y cambia la pestanya a Network_setup
sync func return_to_lobby():
	for child in Persistent_nodes.get_children():
		if child.is_in_group("Enemy"):
			Persistent_nodes.get_node(child.name).queue_free()
	get_tree().change_scene("res://Network_setup.tscn")
			
# cuando el timer de win acabe, llama a la funcion de return_to_lobby
func _on_Win_timer_timeout():
	
	rpc("return_to_lobby")

