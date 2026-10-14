extends Area2D
# Zona de escalera: le avisa al jugador cuando está dentro de ella

func _ready():
	body_entered.connect(_al_entrar)
	body_exited.connect(_al_salir)


func _al_entrar(cuerpo):
	if cuerpo.is_in_group("jugador"):
		cuerpo.en_escalera += 1


func _al_salir(cuerpo):
	if cuerpo.is_in_group("jugador"):
		cuerpo.en_escalera -= 1
