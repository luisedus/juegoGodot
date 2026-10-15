extends CanvasLayer
# Puzle de cuchillos: dos objetivos giran en una cruz. Lanza el cuchillo con ESPACIO justo
# cuando un objetivo cruza su camino. Si fallas un lanzamiento, se reinicia todo.

signal resuelto
signal cerrado

const RADIO_CRUZ = 130.0
const RADIO_OBJETIVO = 22.0
const RADIO_CUCHILLO = 6.0
const DIST_INICIO = 230.0              # distancia inicial del cuchillo bajo el centro
const VELOCIDAD_CUCHILLO = 850.0

var velocidad_inicial = 1.8            # radianes por segundo
var aumento_giro = 1.6                 # el giro se acelera tras el primer acierto

var velocidad = 1.8
var angulo = 0.0
var objetivos_listos = [false, false]
var cuchillo_volando = false
var cuchillo_dy = DIST_INICIO          # altura del cuchillo respecto al centro (positivo = abajo)
var bloqueo = 0.0
var terminado = false

var lienzo
var mensaje
var contador


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	layer = 100
	var tam = get_viewport().get_visible_rect().size

	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.8)
	fondo.size = tam
	add_child(fondo)

	lienzo = Node2D.new()
	add_child(lienzo)
	lienzo.draw.connect(_dibujar)

	mensaje = _crear_texto(Vector2(0, 24), tam.x, 32)
	contador = _crear_texto(Vector2(0, 70), tam.x, 22)
	var ayuda = _crear_texto(Vector2(0, tam.y - 56), tam.x, 20)
	ayuda.text = "ESPACIO: lanzar el cuchillo     ESC: salir"

	velocidad = velocidad_inicial
	_actualizar_textos("Corta la cuerda: acierta los dos objetivos")


func _crear_texto(pos, ancho, tamano):
	var t = Label.new()
	t.position = pos
	t.custom_minimum_size = Vector2(ancho, 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", tamano)
	add_child(t)
	return t


func _actualizar_textos(texto):
	mensaje.text = texto
	contador.text = "Objetivos: %d de 2" % [objetivos_listos.count(true)]


func _posicion_objetivo(i):
	var a = angulo - PI / 2 + (PI if i == 1 else 0.0)
	return Vector2(cos(a), sin(a)) * RADIO_CRUZ


func _process(delta):
	if terminado:
		return
	angulo = fposmod(angulo + velocidad * delta, TAU)
	if bloqueo > 0.0:
		bloqueo -= delta
	if cuchillo_volando:
		cuchillo_dy -= VELOCIDAD_CUCHILLO * delta
		_revisar_cuchillo()
	lienzo.queue_redraw()


func _unhandled_input(event):
	if terminado:
		return
	if event.is_action_pressed("ui_cancel"):
		_cerrar()
	elif event.is_action_pressed("saltar") and not event.is_echo() and not cuchillo_volando and bloqueo <= 0.0:
		cuchillo_volando = true
		cuchillo_dy = DIST_INICIO


func _revisar_cuchillo():
	var punta = Vector2(0, cuchillo_dy)
	for i in range(2):
		if objetivos_listos[i]:
			continue
		if (_posicion_objetivo(i) - punta).length() < RADIO_OBJETIVO + RADIO_CUCHILLO:
			objetivos_listos[i] = true
			cuchillo_volando = false
			cuchillo_dy = DIST_INICIO
			if objetivos_listos[0] and objetivos_listos[1]:
				_terminar_con_exito()
			else:
				velocidad *= aumento_giro
				bloqueo = 0.3
				_actualizar_textos("¡Le diste! Ahora el otro")
			return
	if cuchillo_dy < -DIST_INICIO:
		_fallar()


func _fallar():
	objetivos_listos = [false, false]
	velocidad = velocidad_inicial
	cuchillo_volando = false
	cuchillo_dy = DIST_INICIO
	bloqueo = 0.6
	_actualizar_textos("Fallaste. Se reinicia")


func _terminar_con_exito():
	terminado = true
	_actualizar_textos("¡Cuerda cortada!")
	await get_tree().create_timer(0.8).timeout
	resuelto.emit()
	_cerrar()


func _cerrar():
	terminado = true
	cerrado.emit()
	get_tree().paused = false
	queue_free()


func _dibujar():
	var centro = get_viewport().get_visible_rect().size / 2.0
	var eje = Vector2(cos(angulo - PI / 2), sin(angulo - PI / 2))
	var perp = eje.rotated(PI / 2)
	var gris = Color(0.55, 0.6, 0.62)

	# Cruz giratoria
	lienzo.draw_line(centro - eje * RADIO_CRUZ, centro + eje * RADIO_CRUZ, gris, 14.0)
	lienzo.draw_line(centro - perp * RADIO_CRUZ * 0.6, centro + perp * RADIO_CRUZ * 0.6, gris, 12.0)
	lienzo.draw_circle(centro, 16, Color(0.4, 0.45, 0.47))

	# Objetivos
	for i in range(2):
		var p = centro + _posicion_objetivo(i)
		if objetivos_listos[i]:
			lienzo.draw_circle(p, RADIO_OBJETIVO, Color(0.2, 0.7, 0.3))
		else:
			lienzo.draw_circle(p, RADIO_OBJETIVO, Color(0.9, 0.65, 0.1))
			lienzo.draw_circle(p, RADIO_OBJETIVO * 0.65, Color(1, 0.9, 0.3))
			lienzo.draw_circle(p, RADIO_OBJETIVO * 0.3, Color(0.85, 0.15, 0.1))

	# Cuchillo
	var c = centro + Vector2(0, cuchillo_dy)
	var hoja = PackedVector2Array([c + Vector2(0, -20), c + Vector2(7, 0), c + Vector2(0, 10), c + Vector2(-7, 0)])
	lienzo.draw_colored_polygon(hoja, Color(0.9, 0.92, 0.95))
	lienzo.draw_line(c + Vector2(0, 10), c + Vector2(0, 24), Color(0.5, 0.3, 0.15), 5.0)
