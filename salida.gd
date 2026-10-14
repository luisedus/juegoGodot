extends Area2D
# Salida del nivel: cambia a la siguiente escena (o avisa si aún no existe)

@export_file("*.tscn") var siguiente_escena = ""

var usada = false


func _ready():
	body_entered.connect(_al_entrar)


func _al_entrar(cuerpo):
	if usada or not cuerpo.is_in_group("jugador"):
		return
	usada = true
	if siguiente_escena == "":
		_mostrar_aviso("¡Nivel completado!")
	else:
		get_tree().call_deferred("change_scene_to_file", siguiente_escena)


func _mostrar_aviso(texto):
	var capa = CanvasLayer.new()
	var etiqueta = Label.new()
	etiqueta.text = texto
	etiqueta.position = Vector2(440, 300)
	etiqueta.add_theme_font_size_override("font_size", 40)
	capa.add_child(etiqueta)
	add_child(capa)
