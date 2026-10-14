extends CharacterBody2D
# Enemigo ajustable: persigue, avisa, golpea y puede ser aturdido con el agarre

enum Estado { QUIETO, PERSIGUE, AVISO, GOLPE, ENFRIAMIENTO, ATURDIDO }

@export var vida = 30
@export var es_sonriente = false      # el sonriente es más rápido y preciso
@export var velocidad = 100.0
@export var radio_vision = 350.0
@export var alcance_ataque = 55.0
@export var tiempo_aviso = 0.5        # tiempo que tienes para reaccionar
@export var tiempo_golpe = 0.15
@export var tiempo_enfriamiento = 0.8
@export var duracion_aturdimiento = 2.0   # cuánto dura aturdido si lo agarras
@export var color_base = Color(1, 0, 0)

const GRAVEDAD = 1200.0

var estado = Estado.QUIETO
var tiempo_estado = 0.0
var jugador = null

@onready var cuerpo = $Cuerpo


func _ready():
	add_to_group("enemigos")
	cuerpo.color = color_base
	if es_sonriente:
		# Sonrisa blanca de prueba; luego la cambiamos por un sprite
		var sonrisa = ColorRect.new()
		sonrisa.color = Color.WHITE
		sonrisa.size = Vector2(18, 4)
		sonrisa.position = Vector2(6, 16)
		cuerpo.add_child(sonrisa)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVEDAD * delta

	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")

	match estado:
		Estado.QUIETO:
			velocity.x = 0
			if _distancia_al_jugador() < radio_vision:
				estado = Estado.PERSIGUE

		Estado.PERSIGUE:
			var dx = jugador.global_position.x - global_position.x
			velocity.x = sign(dx) * velocidad
			if _distancia_al_jugador() > radio_vision * 1.5:
				estado = Estado.QUIETO
			elif abs(dx) < alcance_ataque:
				_iniciar_aviso()

		Estado.AVISO:
			velocity.x = 0
			tiempo_estado -= delta
			if tiempo_estado <= 0:
				estado = Estado.GOLPE
				tiempo_estado = tiempo_golpe
				cuerpo.color = Color(1, 0.5, 0)      # naranja: golpe activo
				_intentar_golpear()

		Estado.GOLPE:
			velocity.x = 0
			tiempo_estado -= delta
			_intentar_golpear()
			if tiempo_estado <= 0:
				estado = Estado.ENFRIAMIENTO
				tiempo_estado = tiempo_enfriamiento
				cuerpo.color = color_base.darkened(0.5)   # descansando

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


func _distancia_al_jugador():
	if jugador == null:
		return 99999.0
	return abs(jugador.global_position.x - global_position.x)


func _iniciar_aviso():
	estado = Estado.AVISO
	tiempo_estado = tiempo_aviso
	cuerpo.color = Color(1, 1, 0)                    # amarillo: ¡cuidado!


func _intentar_golpear():
	if jugador == null:
		return
	var dx = abs(jugador.global_position.x - global_position.x)
	var dy = abs(jugador.global_position.y - global_position.y)
	if dx < alcance_ataque + 10 and dy < 60 * scale.y:
		jugador.recibir_golpe(1)


# La llama el jugador cuando lo agarra: cancela su ataque y lo deja indefenso
func aturdir():
	if estado == Estado.ATURDIDO:
		return
	estado = Estado.ATURDIDO
	tiempo_estado = duracion_aturdimiento
	cuerpo.color = Color(0.3, 0.5, 1)                # azul: aturdido


func recibir_golpe(dano):
	vida -= dano
	cuerpo.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		cuerpo.modulate = Color.WHITE
	if vida <= 0:
		morir()


func morir():
	get_tree().call_group("jugador", "enemigo_muerto")
	queue_free()
