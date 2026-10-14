extends Area2D
# Pieza del código: casi invisible, se hace visible al acercarte. Se recoge con el agarre (F).

@export var digito = 0
@export var posicion = 1                 # lugar que ocupa en el código (1, 2 o 3)
@export var radio_aparicion = 160.0

var jugador = null


func _ready():
	add_to_group("agarrables")
	modulate.a = 0.08


func _process(_delta):
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		return
	var d = global_position.distance_to(jugador.global_position)
	modulate.a = clamp(1.0 - (d - 60.0) / (radio_aparicion - 60.0), 0.08, 1.0)


# La llama el jugador cuando la agarra
func recoger():
	get_tree().call_group("nivel", "pieza_recogida", posicion, digito)
	queue_free()
