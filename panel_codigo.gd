extends CanvasLayer
# Panel de código: escribe los dígitos con el teclado (0-9). RETROCESO borra, ESC sale.

signal resuelto
signal cerrado

var codigo_correcto = "371"

var entrada = ""
var terminado = false

var pantalla
var mensaje


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	layer = 100
	var tam = get_viewport().get_visible_rect().size

	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.8)
	fondo.size = tam
	add_child(fondo)

	var titulo = _crear_texto(Vector2(0, tam.y * 0.2), tam.x, 30)
	titulo.text = "TERMINAL DEL HOSPITAL"
	pantalla = _crear_texto(Vector2(0, tam.y * 0.38), tam.x, 72)
	mensaje = _crear_texto(Vector2(0, tam.y * 0.62), tam.x, 28)
	var ayuda = _crear_texto(Vector2(0, tam.y - 60), tam.x, 20)
	ayuda.text = "Teclas 0-9: escribir     RETROCESO: borrar     ESC: salir"
	_actualizar()


func _crear_texto(pos, ancho, tamano):
	var t = Label.new()
	t.position = pos
	t.custom_minimum_size = Vector2(ancho, 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", tamano)
	add_child(t)
	return t


func _actualizar():
	var texto = ""
	for i in range(codigo_correcto.length()):
		texto += (entrada[i] if i < entrada.length() else "_") + " "
	pantalla.text = texto


func _unhandled_input(event):
	if terminado or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		_cerrar()
	elif event.keycode == KEY_BACKSPACE:
		entrada = entrada.substr(0, entrada.length() - 1)
		mensaje.text = ""
		_actualizar()
	elif event.unicode >= 48 and event.unicode <= 57 and entrada.length() < codigo_correcto.length():
		entrada += char(event.unicode)
		_actualizar()
		if entrada.length() == codigo_correcto.length():
			_comprobar()


func _comprobar():
	if entrada == codigo_correcto:
		terminado = true
		mensaje.text = "Código correcto. Rejilla desbloqueada."
		await get_tree().create_timer(1.0).timeout
		resuelto.emit()
		_cerrar()
	else:
		mensaje.text = "Código incorrecto"
		entrada = ""
		_actualizar()


func _cerrar():
	terminado = true
	cerrado.emit()
	get_tree().paused = false
	queue_free()
