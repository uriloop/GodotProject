extends CanvasLayer
# Asignar a si mismo a la ui del global
func _ready() -> void:
	Global.ui = self
# Ponerlo en nulo
func _exit_tree() -> void:
	Global.ui = null
