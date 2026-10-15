extends Node2D
# Nivel 3 (laboratorio): atrae al enemigo bajo la caja y córtale la cuerda

func _ready():
	add_to_group("nivel")


func jefe_derrotado():
	var capa = CanvasLayer.new()
	var etiqueta = Label.new()
	etiqueta.text = "¡Nivel 3 completado!"
	etiqueta.position = Vector2(400, 280)
	etiqueta.add_theme_font_size_override("font_size", 44)
	capa.add_child(etiqueta)
	add_child(capa)
