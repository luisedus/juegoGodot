extends StaticBody2D
# Puerta que se abre y se cierra

@onready var forma = $CollisionShape2D
@onready var cuerpo = $Cuerpo


func abrir():
	forma.set_deferred("disabled", true)
	cuerpo.visible = false


func cerrar():
	forma.set_deferred("disabled", false)
	cuerpo.visible = true
