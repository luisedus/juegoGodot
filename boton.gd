extends Area2D
# Botón que abre la puerta mientras haya algo encima (caja o jugador)

@export var puerta: Node
var encima = 0


func _ready():
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _cuenta(cuerpo):
	return cuerpo.is_in_group("cajas") or cuerpo.is_in_group("jugador")


func _al_entrar(cuerpo):
	if _cuenta(cuerpo) and puerta != null:
		encima += 1
		if encima == 1:
			puerta.abrir()
			$ColorRect.color = Color(0, 1, 0)   # verde: activado


func _al_salir(cuerpo):
	if _cuenta(cuerpo) and puerta != null:
		encima -= 1
		if encima == 0:
			puerta.cerrar()
			$ColorRect.color = Color(1, 0, 0)   # rojo: desactivado
