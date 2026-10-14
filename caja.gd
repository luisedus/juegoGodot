extends RigidBody2D
# Caja que se puede empujar

func _ready():
	add_to_group("cajas")
	lock_rotation = true   # que no se voltee al empujarla
	linear_damp = 4.0      # que se frene sola
	mass = 3.0
