extends Node2D
# Nivel 2 (hospital subterráneo): reúne las piezas del código y escríbelo en la terminal

@export var total_piezas = 3

var recogidas = {}        # posición -> dígito
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


func pieza_recogida(posicion, digito):
	recogidas[posicion] = digito
	_actualizar_hud()


func _actualizar_hud():
	var texto = "Código: "
	for i in range(1, total_piezas + 1):
		texto += (str(recogidas[i]) if recogidas.has(i) else "_") + " "
	hud.text = texto
