extends Node2D
# Nivel 2 (hospital subterráneo): reúne las piezas del código para abrir la rejilla de la ventilación

@export var puerta: Node
@export var total_piezas = 3

var recogidas = []
var hud


func _ready():
	add_to_group("nivel")
	var capa = CanvasLayer.new()
	hud = Label.new()
	hud.position = Vector2(20, 16)
	hud.add_theme_font_size_override("font_size", 26)
	capa.add_child(hud)
	add_child(capa)
	_actualizar_hud()


func pieza_recogida(digito):
	recogidas.append(digito)
	_actualizar_hud()
	if recogidas.size() >= total_piezas and puerta != null:
		puerta.abrir()


func _actualizar_hud():
	var texto = "Código: "
	for i in range(total_piezas):
		texto += (str(recogidas[i]) if i < recogidas.size() else "_") + " "
	if recogidas.size() >= total_piezas:
		texto += "  ¡Rejilla abierta!"
	hud.text = texto
