extends Area2D
# Terminal: al acercarte y presionar E abre el puzle circular.
# Si lo resuelves, abre la puerta asignada.

@export var puerta: Node
@export var zonas = 8
@export var rondas_necesarias = 5
@export var velocidad_inicial = 2.0
@export var aumento_velocidad = 1.4

var jugador_cerca = false
var resuelta = false
var abierta = false
var aviso


func _ready():
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)
	aviso = Label.new()
	aviso.text = "[E] Usar terminal"
	aviso.position = Vector2(-60, -80)
	aviso.visible = false
	add_child(aviso)


func _al_entrar(cuerpo):
	if cuerpo.is_in_group("jugador") and not resuelta:
		jugador_cerca = true
		aviso.visible = true


func _al_salir(cuerpo):
	if cuerpo.is_in_group("jugador"):
		jugador_cerca = false
		aviso.visible = false


func _process(_delta):
	if jugador_cerca and not abierta and not resuelta and Input.is_action_just_pressed("interactuar"):
		_abrir_puzle()


func _abrir_puzle():
	abierta = true
	var puzle = preload("res://puzzle_circular.gd").new()
	puzle.zonas = zonas
	puzle.rondas_necesarias = rondas_necesarias
	puzle.velocidad_inicial = velocidad_inicial
	puzle.aumento_velocidad = aumento_velocidad
	puzle.resuelto.connect(_al_resolver)
	puzle.cerrado.connect(_al_cerrar)
	get_tree().current_scene.add_child(puzle)


func _al_resolver():
	resuelta = true
	aviso.visible = false
	if has_node("ColorRect"):
		$ColorRect.color = Color(0, 1, 0)       # verde: terminal resuelta
	if puerta != null:
		puerta.abrir()


func _al_cerrar():
	abierta = false
