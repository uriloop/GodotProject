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
	pass

func _physics_process(delta):
#	if get_tree().has_network_peer():
#		if is_network_master():	
	## EN TODOS LOS CLIENTES Y SERVIDOR
	# movimiento

	if get_tree().has_network_peer():
			if get_tree().is_network_server():
				rpc("actualizar_posicion",global_position)

	if playerSeeking:
		dir = (playerSeeking.global_position - global_position).normalized()
		velocity= move_and_slide(dir * speed).normalized()
		facing = look_at(playerSeeking.position)

	if hp <=0:
		if get_tree().is_network_server():
			rpc("destroy")

	if playerWhoHit != null and can_be_damaged:
		playerWhoHit.rpc("hit_by_damager",damage)
		can_be_damaged = false
		damage_timer.start()

remote func actualizar_posicion(pos):
	global_position=pos


sync func newPlayerSeeking(playerToSeek):
	for child in Persistent_nodes.get_children():
		if child.name == playerToSeek:
			playerSeeking= child

func _on_seekArea_area_entered(area):
	if get_tree().is_network_server():
		if (area.get_parent().is_in_group('Player') and playerSeeking == null):
			for child in Persistent_nodes.get_children():
				if child.name == area.get_parent().name:
					rpc('newPlayerSeeking', child.name)


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

sync func destroy() -> void:
	Persistent_nodes.get_node(self.name).queue_free()

func _on_HitBox_area_entered(area):
	if get_tree().is_network_server():
		if area.get_parent().is_in_group("Player"):
			playerWhoHit = area.get_parent()
			print(playerWhoHit)
			#area.get_parent().rpc("hit_by_damager",damage)


func _on_DamageTimer_timeout():
	can_be_damaged = true


func _on_HitBox_area_exited(area):
	playerWhoHit=null
