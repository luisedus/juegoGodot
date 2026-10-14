extends CanvasLayer
# Puzle circular: detén la aguja en la zona verde con ESPACIO.
# Se construye solo con código; la terminal lo crea cuando el jugador lo activa.

signal resuelto
signal cerrado

const RADIO = 160.0

var zonas = 8
var rondas_necesarias = 3
var velocidad_inicial = 2.0       # radianes por segundo
var aumento_velocidad = 1.2       # se multiplica en cada ronda acertada

var velocidad = 2.0
var angulo = 0.0                  # 0 = arriba, crece en el sentido de las manecillas
var zona_correcta = 0
var ronda = 0
var bloqueo = 0.0                 # evita pulsaciones seguidas tras un resultado
var terminado = false

var lienzo
var mensaje
var contador


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS   # sigue funcionando con el juego pausado
	get_tree().paused = true
	layer = 100
	var tam = get_viewport().get_visible_rect().size

	var fondo = ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.75)
	fondo.size = tam
	add_child(fondo)

	lienzo = Node2D.new()
	add_child(lienzo)
	lienzo.draw.connect(_dibujar)

	mensaje = _crear_texto(Vector2(0, 30), tam.x, 34)
	contador = _crear_texto(Vector2(0, 80), tam.x, 22)
	var ayuda = _crear_texto(Vector2(0, tam.y - 60), tam.x, 20)
	ayuda.text = "ESPACIO: detener la aguja     ESC: salir"

	velocidad = velocidad_inicial
	_nueva_zona()
	_actualizar_textos("Detén la aguja en la zona verde")


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
	contador.text = "Ronda %d de %d" % [min(ronda + 1, rondas_necesarias), rondas_necesarias]


func _nueva_zona():
	var anterior = zona_correcta
	while zona_correcta == anterior:
		zona_correcta = randi() % zonas


func _process(delta):
	if terminado:
		return
	angulo = fposmod(angulo + velocidad * delta, TAU)
	if bloqueo > 0.0:
		bloqueo -= delta
	lienzo.queue_redraw()


func _unhandled_input(event):
	if terminado:
		return
	if event.is_action_pressed("ui_cancel"):
		_cerrar()
	elif event.is_action_pressed("saltar") and not event.is_echo() and bloqueo <= 0.0:
		_intentar()


func _intentar():
	var zona = int(angulo / (TAU / zonas)) % zonas
	if zona == zona_correcta:
		ronda += 1
		if ronda >= rondas_necesarias:
			_terminar_con_exito()
		else:
			velocidad *= aumento_velocidad
			_nueva_zona()
			bloqueo = 0.25
			_actualizar_textos("¡Bien!")
	else:
		ronda = 0
		velocidad = velocidad_inicial
		_nueva_zona()
		bloqueo = 0.5
		_actualizar_textos("Fallaste, empieza de nuevo")


func _terminar_con_exito():
	terminado = true
	_actualizar_textos("¡Acceso concedido!")
	await get_tree().create_timer(0.9).timeout
	resuelto.emit()
	_cerrar()


func _cerrar():
	terminado = true
	cerrado.emit()
	get_tree().paused = false
	queue_free()


func _dibujar():
	var centro = get_viewport().get_visible_rect().size / 2.0
	var paso = TAU / zonas

	# Zonas del círculo (la correcta en verde)
	for i in range(zonas):
		var inicio = -PI / 2 + i * paso
		var puntos = PackedVector2Array([centro])
		for k in range(13):
			var a = inicio + paso * k / 12.0
			puntos.append(centro + Vector2(cos(a), sin(a)) * RADIO)
		var color = Color(0.25, 0.25, 0.35) if i % 2 == 0 else Color(0.35, 0.35, 0.5)
		if i == zona_correcta:
			color = Color(0.2, 0.8, 0.3)
		lienzo.draw_colored_polygon(puntos, color)

	# Líneas que separan las zonas y el borde
	for i in range(zonas):
		var a = -PI / 2 + i * paso
		lienzo.draw_line(centro, centro + Vector2(cos(a), sin(a)) * RADIO, Color.BLACK, 2.0)
	lienzo.draw_arc(centro, RADIO, 0, TAU, 64, Color.WHITE, 3.0)

	# La aguja
	var a_aguja = angulo - PI / 2
	var punta = centro + Vector2(cos(a_aguja), sin(a_aguja)) * (RADIO + 10)
	lienzo.draw_line(centro, punta, Color(1, 0.2, 0.2), 5.0)
	lienzo.draw_circle(centro, 10, Color(1, 0.2, 0.2))
