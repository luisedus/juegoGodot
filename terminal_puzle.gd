extends Area2D
# Terminal de puzles: al acercarte y presionar E abre un puzle.
# tipo "codigo": teclado numérico; al acertar llama a objetivo.abrir()
# tipo "cuchillos": puzle de cuchillos; al acertar llama a objetivo.cortar_cuerda()

@export_enum("codigo", "cuchillos") var tipo: String = "codigo"
@export var objetivo: Node
@export var codigo_correcto = "371"

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
	var puzle
	if tipo == "codigo":
		puzle = load("res://panel_codigo.gd").new()
		puzle.codigo_correcto = codigo_correcto
	else:
		puzle = load("res://puzzle_cuchillos.gd").new()
	puzle.resuelto.connect(_al_resolver)
	puzle.cerrado.connect(_al_cerrar)
	get_tree().current_scene.add_child(puzle)


func _al_resolver():
	if objetivo == null:
		return
	if tipo == "codigo":
		objetivo.abrir()
		resuelta = true
	else:
		resuelta = objetivo.cortar_cuerda()
	if resuelta:
		aviso.visible = false
		if has_node("ColorRect"):
			$ColorRect.color = Color(0, 1, 0)


func _al_cerrar():
	abierta = false
