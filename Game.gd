extends Node2D

var enemy_scene = preload("res://Enemy1.tscn")
onready var oleada_label= $Game_UI/OleadaLabel
onready var oleada_label_timer = $Game_UI/OleadaLabel/TimerLabelOleada

var pausa_oleada = true
var numero_oleada = 0
var lista_enemigos_oleada = []
var numPlayersInicials = 0
var num_enemigos_vivos = 0

## Spawn points overlaping

var EnemySpawnPoint1Overlaping = 0
var EnemySpawnPoint2Overlaping = 0
var EnemySpawnPoint3Overlaping = 0
var EnemySpawnPoint4Overlaping = 0


var current_spawn_location_instance_number = 1
var current_player_for_spawn_location_number = null

func _ready() -> void:
	# conectamos el trigger para que ejecute la funcion player disconected cuando se desconecte un cliente
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")

	# Si el arbol de nodos actual tiene la conexión como servidor

	if get_tree().is_network_server():
		# ejecutamos este metodo para apawnear al player en una posicion vacia
		setup_players_positions()
		for player in Persistent_nodes.get_children():
			if player.is_in_group("Player"):
				numPlayersInicials  +=1
		$Timer_descanso_oleadas.start()

	

	

func _process(delta):
	if get_tree().is_network_server():
		# Si el descanso se ha acabado
		if not pausa_oleada:

			# Miramos los enemigos vivos en pantalla
			num_enemigos_vivos = 0
			for e in Persistent_nodes.get_children():
				if e.is_in_group("Enemy"):
					num_enemigos_vivos+=1
				# Si hay más de x enemigos en pantalla no se spawnea
			print("enemigos vivos = ",num_enemigos_vivos)
			print("enemigos lista oleada = ",lista_enemigos_oleada.size())
			if num_enemigos_vivos < 8+numPlayersInicials:
				if lista_enemigos_oleada.size()>0:
					for i in lista_enemigos_oleada:
						var enemigo = i
							# comprovar que no esten obstaculizadas las posiciones de spawn
						var spawn_points = $Spawn_enemy.get_children()
						var free_spawn_points = spawn_points.size()
						if EnemySpawnPoint1Overlaping>0:
							free_spawn_points-=1
						if EnemySpawnPoint2Overlaping>0:
							free_spawn_points-=1
						if EnemySpawnPoint3Overlaping>0:
							free_spawn_points-=1
						if EnemySpawnPoint4Overlaping>0:
							free_spawn_points-=1
						if free_spawn_points>0:
							rpc("instance_enemy1",get_tree().get_network_unique_id())
							lista_enemigos_oleada.erase(i)
							print("spawneamos un nuevo enemigo")
							return # solo spawnea un enemigo por loop
			if num_enemigos_vivos == 0 and lista_enemigos_oleada.size() == 0 and pausa_oleada==false:
				print("La oleada se ha terminado. Iniciamos pausa oleada")
				pausa_oleada=true
				$Timer_descanso_oleadas.start()
				rpc("descanso")

sync func descanso():
	oleada_label.text="Descanso!"
	oleada_label.visible=true

# Cuando el usuario esta hosteando la partida se llama a esta función para que establezca las posiciones de spawn
func setup_players_positions() -> void:
	for player in Persistent_nodes.get_children():
		if player.is_in_group("Player"):
			# por cada lugar donde se puede spawnear un player...
			for spawn_location in $Spawn_locations.get_children():
				
				if int(spawn_location.name) == current_spawn_location_instance_number and current_player_for_spawn_location_number != player:
					# Con este comando avisamos a los demás usuarios que esta posicion ya esta ocupada por este usuario
					player.rpc("update_position", spawn_location.global_position)
					# Cada posición va numerada así que sumamos uno a las posiciones
					current_spawn_location_instance_number += 1
					# Le decimos que el player de este dispositivo será el que ocupará esta posicion
					current_player_for_spawn_location_number = player

# si el player se desconecta lo borramos este metodo se ejecuta a través de un trigger/signal
func _player_disconnected(id) -> void:
	if Persistent_nodes.has_node(str(id)):
		Persistent_nodes.get_node(str(id)).username_text_instance.queue_free()
		Persistent_nodes.get_node(str(id)).queue_free()



#  ---- ENEMIGOS ----
#Ejecutamos la creación del enemigo en todos los clientes
sync func instance_enemy1(id):
	var enemy1_instance = Global.instance_node_at_location(enemy_scene,Persistent_nodes, random_spawn_enemy_position())
	enemy1_instance.name = name + str(Network.networked_object_name_index)
	enemy1_instance.set_network_master(id)
	Network.networked_object_name_index += 1
	

# El random habria que hacerlo como el de el player en Network. De moento se queda así
var rng = RandomNumberGenerator.new()

func random_spawn_enemy_position():
	while(true):
		var randomPlace= rng.randi_range(1,4)
		if (randomPlace==1 and EnemySpawnPoint1Overlaping==0):
			return $Spawn_enemy/spawn.position
		elif (randomPlace==2 and EnemySpawnPoint2Overlaping==0):
			return $Spawn_enemy/spawn2.position
		elif (randomPlace==3 and EnemySpawnPoint3Overlaping==0):
			return $Spawn_enemy/spawn3.position
		elif (randomPlace==4 and EnemySpawnPoint4Overlaping==0):
			return $Spawn_enemy/spawn4.position

func _on_Timer_descanso_oleadas_timeout():
	if (get_tree().is_network_server()):
		numero_oleada+=1
		pausa_oleada = false
		generarOleada(numero_oleada)
		rpc("show_oleada_label",numero_oleada)

sync func show_oleada_label(num_oleada):
	oleada_label.text= "Oleada " + str(num_oleada)
	oleada_label.visible = true
	oleada_label_timer.start()

func generarOleada(num_oleada):
	for p in numPlayersInicials:
		for i in (3*(num_oleada)):
			var randomEnemy=rng.randi_range(1,4)
			if randomEnemy == 4:
				# Aquí generar el enemigo 2 cuando lo tengamos
				lista_enemigos_oleada.append("enemy1")
			else:
				lista_enemigos_oleada.append("enemy1")


func _on_TimerLabelOleada_timeout():
	oleada_label.visible = false


func _on_EnemySpawnPoint1_area_entered(area):
	if get_tree().is_network_server():
		EnemySpawnPoint1Overlaping +=1



func _on_EnemySpawnPoint1_area_exited(area):
	if get_tree().is_network_server():

		EnemySpawnPoint1Overlaping -=1

func _on_EnemySpawnPoint2_area_entered(area):
	if get_tree().is_network_server():

		EnemySpawnPoint2Overlaping +=1


func _on_EnemySpawnPoint2_area_exited(area):
	if get_tree().is_network_server():

		EnemySpawnPoint2Overlaping -=1


func _on_EnemySpawnPoint3_area_entered(area):
	if get_tree().is_network_server():

		EnemySpawnPoint3Overlaping +=1


func _on_EnemySpawnPoint3_area_exited(area):
	if get_tree().is_network_server():

		EnemySpawnPoint3Overlaping -=1


func _on_EnemySpawnPoint4_area_entered(area):
	if get_tree().is_network_server():

		EnemySpawnPoint4Overlaping +=1


func _on_EnemySpawnPoint4_area_exited(area):
	if get_tree().is_network_server():

		EnemySpawnPoint4Overlaping -=1
