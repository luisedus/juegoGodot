extends CharacterBody2D
# Enemigo tirador (sonriente): no pega, solo dispara proyectiles que matan de un golpe.
# Se esquivan con Shift, agachándote (S) o saltando.

enum Estado { QUIETO, AVISO, ENFRIAMIENTO, ATURDIDO }

@export var vida = 40
@export var radio_vision = 550.0
@export var tiempo_aviso = 0.6            # aviso amarillo antes de disparar
@export var tiempo_enfriamiento = 1.3
@export var velocidad_bala = 320.0
@export var distancia_minima = 140.0      # si te acercas más, retrocede
@export var velocidad_retroceso = 80.0
@export var duracion_aturdimiento = 2.0
@export var color_base = Color(0.6, 0.1, 0.6)

const GRAVEDAD = 1200.0

var estado = Estado.QUIETO
var tiempo_estado = 0.0
var direccion = 1
var jugador = null

@onready var cuerpo = $Cuerpo


func _ready():
	add_to_group("enemigos")
	cuerpo.color = color_base
	# Sonrisa blanca (todos los tiradores son sonrientes)
	var sonrisa = Line2D.new()
	sonrisa.width = 2.5
	sonrisa.default_color = Color.WHITE
	sonrisa.position = Vector2(15, 18)
	for i in range(9):
		var t = i / 8.0
		sonrisa.add_point(Vector2(lerp(-10.0, 10.0, t), 5.0 * (1.0 - pow(2.0 * t - 1.0, 2.0))))
	cuerpo.add_child(sonrisa)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += GRAVEDAD * delta

	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		move_and_slide()
		return

	var dx = jugador.global_position.x - global_position.x
	var dy = abs(jugador.global_position.y - global_position.y)

	match estado:
		Estado.QUIETO:
			if dx != 0:
				direccion = 1 if dx > 0 else -1
			if abs(dx) < distancia_minima:
				velocity.x = -direccion * velocidad_retroceso
			else:
				velocity.x = 0
			if abs(dx) < radio_vision and dy < 150:
				_iniciar_aviso()

		Estado.AVISO:
			velocity.x = 0
			tiempo_estado -= delta
			if tiempo_estado <= 0:
				_disparar()
				estado = Estado.ENFRIAMIENTO
				tiempo_estado = tiempo_enfriamiento
				cuerpo.color = color_base.darkened(0.5)

		Estado.ENFRIAMIENTO:
			velocity.x = 0
			tiempo_estado -= delta
			if tiempo_estado <= 0:
				cuerpo.color = color_base
				estado = Estado.QUIETO

		Estado.ATURDIDO:
			velocity.x = 0
			tiempo_estado -= delta
			if tiempo_estado <= 0:
				cuerpo.color = color_base
				estado = Estado.QUIETO

	move_and_slide()


func _iniciar_aviso():
	estado = Estado.AVISO
	tiempo_estado = tiempo_aviso
	cuerpo.color = Color(1, 1, 0)                 # amarillo: ¡va a disparar!


func _disparar():
	var bala = Area2D.new()
	bala.set_script(preload("res://bala.gd"))
	bala.direccion = direccion
	bala.velocidad = velocidad_bala

	var forma = CollisionShape2D.new()
	var circulo = CircleShape2D.new()
	circulo.radius = 8.0
	forma.shape = circulo
	bala.add_child(forma)

	var dibujo = ColorRect.new()
	dibujo.color = Color(1, 0.9, 0.2)
	dibujo.size = Vector2(16, 16)
	dibujo.position = Vector2(-8, -8)
	bala.add_child(dibujo)

	get_tree().current_scene.add_child(bala)
	# La bala sale a la altura del pecho: pasa por encima si estás agachado
	bala.global_position = global_position + Vector2(direccion * 30, -15)


# La llama el jugador cuando lo agarra: cancela su disparo
func aturdir():
	if estado == Estado.ATURDIDO:
		return
	estado = Estado.ATURDIDO
	tiempo_estado = duracion_aturdimiento
	cuerpo.color = Color(0.3, 0.5, 1)             # azul: aturdido


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
