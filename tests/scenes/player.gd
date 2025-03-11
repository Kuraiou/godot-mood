extends Area2D

@export var current_stamina: float = 100.0:
	set(val):
		if current_stamina == val:
			return

		if floor(val) != floor(current_stamina):
			stamina_changed.emit(val)

		current_stamina = val

@export var max_stamina := 100

@export var move_speed := 20
@export var sprint_speed := 50

@export var sprint_machine: MoodMachine

signal stamina_changed(stamina: float)
