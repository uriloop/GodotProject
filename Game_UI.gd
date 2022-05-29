extends CanvasLayer

onready var win_timer = $Control/Winner/Win_timer
onready var winner = $Control/Winner

func _ready() -> void:
	# escondemos el mensaje de ganador
	winner.hide()

# Esto se ejecuta cada frame
func _process(_delta: float) -> void:
	# si queda un player y tiene conexion
	if Global.alive_players.size() == 1 and get_tree().has_network_peer():
		# Si la id es la misma, muestra el mensaje winner.
		if Global.alive_players[0].name == str(get_tree().get_network_unique_id()):
			winner.show()
		# Si no esta activo, activamos el timer
		if win_timer.time_left <= 0:
			win_timer.start()
