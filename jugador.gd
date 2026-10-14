extends CharacterBody2D
# Jugador: caminar, saltar, agacharse, atacar, esquivar, agarrar, trepar y sonrisa que crece con la maldad

enum Estado { LIBRE, ATACANDO, ESQUIVANDO, AGARRANDO, TREPANDO }

const VELOCIDAD = 220.0
const VELOCIDAD_AGACHADO = 110.0
const SALTO = -420.0
const GRAVEDAD = 1200.0
const VEL_ESQUIVA = 450.0
const VEL_TREPAR = 140.0
const ALTURA_NORMAL = 60.0
const ALTURA_AGACHADO = 30.0
const DURACION_ATAQUE = 0.25
const DURACION_ESQUIVA = 0.3
const VENTANA_INVULNERABLE = 0.2   # solo los primeros 0.2 s de la esquiva te protegen
const DURACION_AGARRE = 0.35       # lo que tardas en agarrar (quedas vulnerable)
const ENFRIAMIENTO_AGARRE = 0.8
const ALCANCE_AGARRE = 70.0

var estado = Estado.LIBRE
var direccion = 1
var tiempo_estado = 0.0
var enfriamiento_agarre = 0.0
var invulnerable = false
var agachado = false
var maldad = 0.0                   # de 0 a 100
var golpeados = []                 # evita pegarle dos veces al mismo enemigo en un ataque
var sonrisa = null
var en_escalera = 0                # lo modifica el script de la escalera

@onready var hitbox = $Hitbox
@onready var cuerpo = $Cuerpo
@onready var forma = $CollisionShape2D


func _ready():
	add_to_group("jugador")
	# Copia propia de la forma de colisión, para poder cambiar su altura al agacharte
	forma.shape = forma.shape.duplicate()
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	_crear_sonrisa()


func _physics_process(delta):
	# Mientras trepas no hay gravedad
	if not is_on_floor() and estado != Estado.TREPANDO:
		velocity.y += GRAVEDAD * delta

	if enfriamiento_agarre > 0:
		enfriamiento_agarre -= delta

	match estado:
		Estado.LIBRE:
			_estado_libre()
		Estado.ATACANDO:
			tiempo_estado -= delta
			velocity.x = move_toward(velocity.x, 0, 1500 * delta)
			if tiempo_estado <= 0:
				_terminar_ataque()
		Estado.ESQUIVANDO:
			tiempo_estado -= delta
			var transcurrido = DURACION_ESQUIVA - tiempo_estado
			invulnerable = transcurrido < VENTANA_INVULNERABLE
			cuerpo.modulate.a = 0.5 if invulnerable else 1.0
			velocity.x = direccion * VEL_ESQUIVA
			if tiempo_estado <= 0:
				_terminar_esquiva()
		Estado.AGARRANDO:
			tiempo_estado -= delta
			velocity.x = move_toward(velocity.x, 0, 1500 * delta)
			if tiempo_estado <= 0:
				cuerpo.modulate = Color.WHITE
				estado = Estado.LIBRE
		Estado.TREPANDO:
			velocity.x = 0
			velocity.y = Input.get_axis("arriba", "abajo") * VEL_TREPAR
			if Input.is_action_just_pressed("saltar"):
				# Saltar para soltarte de la escalera
				estado = Estado.LIBRE
				velocity.y = SALTO
				velocity.x = Input.get_axis("izquierda", "derecha") * VELOCIDAD
			elif en_escalera <= 0:
				# Saliste de la escalera (por arriba o por abajo)
				estado = Estado.LIBRE

	move_and_slide()
	_empujar_cajas()


func _estado_libre():
	# Agarrarte a la escalera si estás en ella y presionas arriba o abajo
	if en_escalera > 0 and (Input.is_action_pressed("arriba") or Input.is_action_pressed("abajo")):
		_agachar(false)
		estado = Estado.TREPANDO
		return

	# Agacharte: mantén abajo (S) en el suelo; no te levantas si hay techo encima
	_agachar(is_on_floor() and Input.is_action_pressed("abajo"))

	var eje = Input.get_axis("izquierda", "derecha")
	var vel = VELOCIDAD_AGACHADO if agachado else VELOCIDAD
	velocity.x = eje * vel
	if eje != 0:
		direccion = 1 if eje > 0 else -1

	if Input.is_action_just_pressed("agarrar") and enfriamiento_agarre <= 0:
		_iniciar_agarre()
	elif not agachado:
		if Input.is_action_just_pressed("saltar") and is_on_floor():
			velocity.y = SALTO
		if Input.is_action_just_pressed("atacar"):
			_iniciar_ataque()
		elif Input.is_action_just_pressed("esquivar"):
			_iniciar_esquiva()


func _agachar(valor):
	if valor == agachado:
		return
	# Para levantarte necesitas espacio libre encima de ti
	if not valor and test_move(global_transform, Vector2(0, -(ALTURA_NORMAL - ALTURA_AGACHADO))):
		return
	agachado = valor
	var altura = ALTURA_AGACHADO if valor else ALTURA_NORMAL
	forma.shape.size.y = altura
	forma.position.y = (ALTURA_NORMAL - altura) / 2.0
	cuerpo.size.y = altura
	cuerpo.position.y = -30.0 + (ALTURA_NORMAL - altura)


func _iniciar_ataque():
	estado = Estado.ATACANDO
	tiempo_estado = DURACION_ATAQUE
	golpeados.clear()
	hitbox.position.x = 40 * direccion
	hitbox.set_deferred("monitoring", true)


func _terminar_ataque():
	hitbox.set_deferred("monitoring", false)
	estado = Estado.LIBRE


func _iniciar_esquiva():
	estado = Estado.ESQUIVANDO
	tiempo_estado = DURACION_ESQUIVA


func _terminar_esquiva():
	invulnerable = false
	cuerpo.modulate.a = 1.0
	estado = Estado.LIBRE


func _iniciar_agarre():
	estado = Estado.AGARRANDO
	tiempo_estado = DURACION_AGARRE
	enfriamiento_agarre = ENFRIAMIENTO_AGARRE
	cuerpo.modulate = Color(0.5, 0.8, 1.0)     # azul claro mientras agarras
	_intentar_agarrar()


func _intentar_agarrar():
	# 1) Un enemigo delante de ti, al alcance del brazo
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		var dx = (enemigo.global_position.x - global_position.x) * direccion
		var dy = abs(enemigo.global_position.y - global_position.y)
		if dx > 0 and dx < ALCANCE_AGARRE and dy < 60:
			enemigo.aturdir()
			print("¡Agarraste al enemigo!")
			return
	# 2) Un objeto agarrable cerca (por ejemplo, una pieza del código)
	for cosa in get_tree().get_nodes_in_group("agarrables"):
		if global_position.distance_to(cosa.global_position) < ALCANCE_AGARRE:
			cosa.recoger()
			print("¡Agarraste algo!")
			return


func _on_hitbox_body_entered(body):
	if body.is_in_group("enemigos") and body not in golpeados:
		golpeados.append(body)
		body.recibir_golpe(10)


func _empujar_cajas():
	for i in get_slide_collision_count():
		var choque = get_slide_collision(i)
		var objeto = choque.get_collider()
		# Solo empuja si el choque es de lado (no si estás parado encima)
		if objeto is RigidBody2D and abs(choque.get_normal().x) > 0.5:
			var eje = Input.get_axis("izquierda", "derecha")
			objeto.linear_velocity.x = eje * VELOCIDAD * 0.8


# ---------- Sonrisa que crece con la maldad ----------

func _crear_sonrisa():
	sonrisa = Line2D.new()
	sonrisa.width = 3.0
	sonrisa.default_color = Color.BLACK
	sonrisa.position = Vector2(15, 20)   # dentro del Cuerpo (30x60), parte alta
	cuerpo.add_child(sonrisa)
	_actualizar_sonrisa()


func _actualizar_sonrisa():
	sonrisa.clear_points()
	if maldad <= 0:
		return                            # sin maldad, sin sonrisa
	var ancho = 4.0 + maldad * 0.22       # de 4 a 26 píxeles
	var altura = 1.0 + maldad * 0.07      # de 1 a 8 píxeles (qué tan curva)
	for i in range(9):
		var t = i / 8.0
		var x = lerp(-ancho / 2.0, ancho / 2.0, t)
		var y = altura * (1.0 - pow(2.0 * t - 1.0, 2.0))
		sonrisa.add_point(Vector2(x, y))


# La llama el enemigo cuando muere
func enemigo_muerto():
	maldad = min(maldad + 10.0, 100.0)
	cuerpo.color = Color.WHITE.lerp(Color(0.8, 0.1, 0.1), maldad / 100.0)
	_actualizar_sonrisa()
	print("Maldad: ", maldad)


# La llama el enemigo (o una bala) cuando te golpea
func recibir_golpe(_dano):
	if invulnerable:
		print("¡Esquivaste!")
		return
	morir()


func morir():
	print("Moriste")
	get_tree().call_deferred("reload_current_scene")
