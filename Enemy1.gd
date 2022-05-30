extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var speed = 200
var velocity = Vector2()
var playerSeeking = null
var facing=0
var dir
var hp = 100
var damage = 10
var can_be_damaged = true
var playerWhoHit = null
onready var damage_timer = $damage_timer

func _ready():
	calcular_player_mas_cercano()

func _physics_process(delta):
#	if get_tree().has_network_peer():
#		if is_network_master():	
	## EN TODOS LOS CLIENTES Y SERVIDOR
	# movimiento
	
	# Si tiene conexión y es un servidor, que actualize la posicion global del enemigo a los clientes, despues llama al metodo calcular_player_mas_cercano
	if get_tree().has_network_peer():
			if get_tree().is_network_server():
				rpc("actualizar_posicion",global_position)
				calcular_player_mas_cercano()
				


	
	# si playerSeeking no es nulo, entonces calcula la direccion del que tiene que mover, mueve hacia la direccion y ultimo hacemos que el enemigo mire hacia player
	if playerSeeking:
		dir = (playerSeeking.global_position - global_position).normalized()
		velocity= move_and_slide(dir * speed).normalized()
		facing = look_at(playerSeeking.position)

	# si enemigo no tiene vida y eres el servidor, llama al metodo destroy
	if hp <=0:
		if get_tree().is_network_server():
			rpc("destroy",self.name)

	# cuando el playerWhohit no es nulo y can_be_damaged es true,
	# entonces llama al metodo hit_by_damager del playerWhohit para quitarle vida
	# despues ponemos el can_be_damaged false, para que no pegue todo el rato
	# ultimo con un timer para tener un margen entre golpe y golpe
	if playerWhoHit != null and can_be_damaged:
		playerWhoHit.rpc("hit_by_damager",damage)
		can_be_damaged = false
		damage_timer.start()
		
	
# actualiza el global position de los clientes.
remote func actualizar_posicion(pos):
	global_position=pos

# actualiza el player del que tiene que perseguir en los clientes.
remote func actualizar_playerSeeking(pl):
	for p in Persistent_nodes.get_children():
		if p.is_in_group("Player"):
			if p.name==pl:
				playerSeeking=p

# Es para calcular en la partida que player esta mas cerca de enemigo y llama a newPlayerSeeking
func calcular_player_mas_cercano():
	
	var posicion_referencia = null
	
	for player in Persistent_nodes.get_children():
		if player.is_in_group("Player"):
			if posicion_referencia == null:
				playerSeeking=player
				posicion_referencia = player.position
#			elif (self.position - player.position).abs() < (self.position - posicion_referencia).abs():
			elif (self.position.distance_to(player.position)) < (self.position.distance_to(posicion_referencia)):
				playerSeeking=player
				posicion_referencia=player.position
	rpc('newPlayerSeeking', playerSeeking.name)

# para dar alta un nuevo player al seguir
sync func newPlayerSeeking(playerToSeek):
	for child in Persistent_nodes.get_children():
		if child.name == playerToSeek:
			playerSeeking= child

#func _on_seekArea_area_entered(area):
#	if get_tree().is_network_server():
#		if (area.get_parent().is_in_group('Player') and playerSeeking == null):
#			for child in Persistent_nodes.get_children():
#				if child.name == area.get_parent().name:
#					rpc('newPlayerSeeking', child.name)

func _on_HurtBox_area_entered(area):
	if get_tree().is_network_server():
		# Si se trata de una bala
		if area.is_in_group("Player_damager"):
			# mandamos mensaje TCP para ejecutar la funcion remota hit_by_damager y le pasamos el damage que es la variable que indica el daño de una bala en el nodo player_bullet que corresponde con la bala
			rpc("hit_by_damager", area.get_parent().damage)
			# mandamos ejecutar la funcion remota destroy de la bala para que se destruya en todos los clientes
			area.get_parent().rpc("destroy")

sync func hit_by_damager(damage):
	# le restamos al hp de este player el damage que corresponde al daño que recibe por parametro y se corresponde con la bala
	hp -= damage

# Busca en Persistent_nodes, el nodo con el nombre del parametro y lo borra.
sync func destroy(name) -> void:
	for e in Persistent_nodes.get_children():
		if e.name == name:
			Persistent_nodes.get_node(e.name).queue_free()
			self.queue_free()

func _on_HitBox_area_entered(area):
	# Si eres servidor
	if get_tree().is_network_server():
		# Si el padre de la area es un player
		if area.get_parent().is_in_group("Player"):
			# le asigna al playerWhoHit el padre de la area
			playerWhoHit = area.get_parent()
			print(playerWhoHit)
			#area.get_parent().rpc("hit_by_damager",damage)

# vuelve al true para poder hacer daño cuando el timer se termine
func _on_DamageTimer_timeout():
	can_be_damaged = true

# cuando no hay ninguna area dentro de HitBox area que ponga nulo
func _on_HitBox_area_exited(area):
	playerWhoHit=null
