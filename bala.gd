extends Area2D
# Proyectil del enemigo: viaja recto y mata al jugador si lo toca

var direccion = 1
var velocidad = 320.0
var tiempo_vida = 4.0
var esquivable = true      # si es false, Shift no protege: hay que saltar o agacharse


func _ready():
	body_entered.connect(_al_chocar)


func _physics_process(delta):
	global_position.x += direccion * velocidad * delta
	tiempo_vida -= delta
	if tiempo_vida <= 0:
		queue_free()


func _al_chocar(cuerpo):
	if cuerpo.is_in_group("jugador"):
		if esquivable:
			cuerpo.recibir_golpe(1)
		else:
			cuerpo.morir()
		queue_free()
	elif not cuerpo.is_in_group("enemigos"):
		queue_free()
