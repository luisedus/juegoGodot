extends CharacterBody2D
# Enemigo del nivel 3: te persigue lento, sube escaleras y salta. Dispara arriba o abajo
# al azar (se evita agachándote o saltando) y pega si te acercas.
# No se puede matar a golpes: solo la trampa de la caja lo derrota.

enum Estado { QUIETO, PERSIGUE, TREPANDO, AVISO_DISPARO, AVISO_GOLPE, GOLPE, ENFRIAMIENTO, ATURDIDO }

@export var velocidad = 70.0
@export var velocidad_trepar = 70.0
@export var salto = -430.0
@export var radio_vision = 650.0
@export var alcance_golpe = 60.0
@export var tiempo_aviso_disparo = 0.4     # barrita blanca que anuncia la altura del disparo
@export var tiempo_entre_disparos = 0.3
@export var disparos_por_rafaga = 2
@export var velocidad_bala = 500.0
@export var bala_esquivable = false        # false = Shift no protege de sus balas
@export var espera_entre_rafagas = 1.6
@export var tiempo_aviso_golpe = 0.25
@export var tiempo_golpe = 0.15
@export var tiempo_enfriamiento = 0.7
@export var duracion_aturdimiento = 1.5
@export var color_base = Color(0.55, 0.05, 0.1)

const GRAVEDAD = 1200.0
const ALTURA_DISPARO_ALTO = -18.0          # respecto al centro del enemigo
const ALTURA_DISPARO_BAJO = 26.0

var estado = Estado.QUIETO
var tiempo_estado = 0.0
var direccion = 1
var en_escalera = 0                        # lo modifica el script de la escalera
var espera_disparo = 1.0
var disparos_restantes = 0
var disparo_alto = true
var jugador = null
var marca = null

@onready var cuerpo = $Cuerpo


func _ready():
	add_to_group("enemigos")
	add_to_group("jefe")
	add_to_group("trepadores")
	cuerpo.color = color_base

	# Sonrisa blanca ancha
	var sonrisa = Line2D.new()
	sonrisa.width = 3.0
	sonrisa.default_color = Color.WHITE
	sonrisa.position = Vector2(18, 24)
	for i in range(9):
		var t = i / 8.0
		sonrisa.add_point(Vector2(lerp(-13.0, 13.0, t), 6.0 * (1.0 - pow(2.0 * t - 1.0, 2.0))))
	cuerpo.add_child(sonrisa)

	# Barrita que anuncia a qué altura va a disparar
	marca = ColorRect.new()
	marca.color = Color.WHITE
	marca.size = Vector2(26, 6)
	marca.visible = false
	add_child(marca)


func _physics_process(delta):
	if not is_on_floor() and estado != Estado.TREPANDO:
		velocity.y += GRAVEDAD * delta

	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		move_and_slide()
		return

	if espera_disparo > 0:
		espera_disparo -= delta

	var dx = jugador.global_position.x - global_position.x
	var dy = jugador.global_position.y - global_position.y

	match estado:
		Estado.QUIETO:
			velocity.x = 0
			if abs(dx) < radio_vision and abs(dy) < 400:
				estado = Estado.PERSIGUE

		Estado.PERSIGUE:
			_perseguir(dx, dy)

		Estado.TREPANDO:
			velocity.x = 0
			velocity.y = sign(dy) * velocidad_trepar
			if abs(dy) < 40 or en_escalera <= 0:
				estado = Estado.PERSIGUE

		Estado.AVISO_DISPARO:
			velocity.x = 0
			tiempo_estado -= delta
			if tiempo_estado <= 0:
				_disparar()
				disparos_restantes -= 1
				if disparos_restantes > 0:
					_iniciar_aviso_disparo(tiempo_entre_disparos)
				else:
					marca.visible = false
					espera_disparo = espera_entre_rafagas
					_iniciar_enfriamiento()

		Estado.AVISO_GOLPE:
			velocity.x = 0
			tiempo_estado -= delta
			if tiempo_estado <= 0:
				estado = Estado.GOLPE
				tiempo_estado = tiempo_golpe
				cuerpo.color = Color(1, 0.3, 0)
				_intentar_golpear(dx, dy)

		Estado.GOLPE:
			velocity.x = 0
			tiempo_estado -= delta
			_intentar_golpear(dx, dy)
			if tiempo_estado <= 0:
				_iniciar_enfriamiento()

		Estado.ENFRIAMIENTO:
			velocity.x = 0
			tiempo_estado -= delta
			if tiempo_estado <= 0:
				cuerpo.color = color_base
				estado = Estado.PERSIGUE

		Estado.ATURDIDO:
			velocity.x = 0
			tiempo_estado -= delta
			if tiempo_estado <= 0:
				cuerpo.color = color_base
				estado = Estado.PERSIGUE

	move_and_slide()


func _perseguir(dx, dy):
	if abs(dy) > 90:
		# El jugador está en otro nivel: ir a la escalera más cercana y trepar
		if en_escalera > 0:
			estado = Estado.TREPANDO
			return
		var escalera = _escalera_cercana()
		if escalera != null:
			var dxe = escalera.global_position.x - global_position.x
			direccion = 1 if dxe > 0 else -1
			velocity.x = direccion * velocidad
		else:
			velocity.x = 0
		_saltar_si_choca(dx)
		return

	# Mismo nivel: golpear de cerca, disparar de lejos o acercarse
	if dx != 0:
		direccion = 1 if dx > 0 else -1

	if abs(dx) < alcance_golpe and abs(dy) < 70:
		velocity.x = 0
		estado = Estado.AVISO_GOLPE
		tiempo_estado = tiempo_aviso_golpe
		cuerpo.color = Color(1, 0.6, 0)
		return

	if espera_disparo <= 0 and abs(dx) < radio_vision and abs(dx) > alcance_golpe + 40:
		velocity.x = 0
		disparos_restantes = disparos_por_rafaga
		_iniciar_aviso_disparo(tiempo_aviso_disparo)
		return

	velocity.x = direccion * velocidad if abs(dx) > 20 else 0.0
	_saltar_si_choca(dx)


func _saltar_si_choca(dx):
	# Si un obstáculo le cierra el paso, salta
	if is_on_floor() and is_on_wall() and abs(dx) > 60:
		velocity.y = salto


func _escalera_cercana():
	var mejor = null
	var mejor_dist = INF
	for e in get_tree().get_nodes_in_group("escaleras"):
		var d = abs(e.global_position.x - global_position.x)
		if d < mejor_dist:
			mejor_dist = d
			mejor = e
	return mejor


func _iniciar_aviso_disparo(tiempo):
	estado = Estado.AVISO_DISPARO
	tiempo_estado = tiempo
	disparo_alto = randf() < 0.5
	var y = ALTURA_DISPARO_ALTO if disparo_alto else ALTURA_DISPARO_BAJO
	marca.position = Vector2(direccion * 26 - 13, y - 3)
	marca.visible = true
	cuerpo.color = Color(1, 1, 0)


func _iniciar_enfriamiento():
	estado = Estado.ENFRIAMIENTO
	tiempo_estado = tiempo_enfriamiento
	cuerpo.color = color_base.darkened(0.4)


func _disparar():
	var bala = Area2D.new()
	bala.set_script(preload("res://bala.gd"))
	bala.direccion = direccion
	bala.velocidad = velocidad_bala
	bala.esquivable = bala_esquivable

	var forma = CollisionShape2D.new()
	var circulo = CircleShape2D.new()
	circulo.radius = 8.0
	forma.shape = circulo
	bala.add_child(forma)

	var dibujo = ColorRect.new()
	dibujo.color = Color(1, 0.5, 0) if disparo_alto else Color(1, 0.2, 0.2)
	dibujo.size = Vector2(16, 16)
	dibujo.position = Vector2(-8, -8)
	bala.add_child(dibujo)

	get_tree().current_scene.add_child(bala)
	var y = ALTURA_DISPARO_ALTO if disparo_alto else ALTURA_DISPARO_BAJO
	bala.global_position = global_position + Vector2(direccion * 34, y)


func _intentar_golpear(dx, dy):
	if abs(dx) < alcance_golpe + 15 and abs(dy) < 70:
		jugador.recibir_golpe(1)


# La llama el jugador cuando lo agarra
func aturdir():
	if estado == Estado.ATURDIDO:
		return
	inmovilizar(duracion_aturdimiento)


# La usa la trampa para dejarlo quieto mientras cae la caja
func inmovilizar(segundos):
	marca.visible = false
	estado = Estado.ATURDIDO
	tiempo_estado = segundos
	cuerpo.color = Color(0.3, 0.5, 1)


# Los golpes solo lo hacen parpadear: es invulnerable
func recibir_golpe(_dano):
	cuerpo.modulate = Color(1, 0.6, 0.6)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		cuerpo.modulate = Color.WHITE


func morir_aplastado():
	get_tree().call_group("nivel", "jefe_derrotado")
	queue_free()
