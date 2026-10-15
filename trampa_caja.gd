extends Node2D
# Trampa: una caja colgada de una cuerda. Si cortas la cuerda con el enemigo debajo, lo aplasta.

@export var caida = 220.0            # cuánto baja la caja al caer
@export var radio_aplastar = 75.0    # qué tan cerca (en horizontal) debe estar el enemigo

@onready var cuerda = $Cuerda
@onready var caja = $Caja

var usada = false


# La llama la terminal al resolver el puzle. Devuelve true si la trampa funcionó.
func cortar_cuerda():
	if usada:
		return true
	var jefe = get_tree().get_first_node_in_group("jefe")
	if jefe == null:
		return false

	var destino_y = global_position.y + caja.position.y + caida + caja.size.y / 2.0
	var cerca_x = abs(jefe.global_position.x - global_position.x) < radio_aplastar
	var cerca_y = abs(jefe.global_position.y - destino_y) < 80.0
	if not (cerca_x and cerca_y):
		_mostrar_mensaje("El enemigo no está debajo de la caja")
		return false

	usada = true
	jefe.inmovilizar(2.0)
	cuerda.visible = false
	var tween = create_tween()
	tween.tween_property(caja, "position:y", caja.position.y + caida, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_al_caer.bind(jefe))
	return true


func _al_caer(jefe):
	if is_instance_valid(jefe):
		jefe.morir_aplastado()


func _mostrar_mensaje(texto):
	var capa = CanvasLayer.new()
	var etiqueta = Label.new()
	etiqueta.text = texto
	etiqueta.position = Vector2(300, 120)
	etiqueta.add_theme_font_size_override("font_size", 28)
	capa.add_child(etiqueta)
	add_child(capa)
	await get_tree().create_timer(2.5).timeout
	capa.queue_free()
