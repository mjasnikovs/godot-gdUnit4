class_name Health extends Node

signal damaged(amount: int)
signal died

@export var max_health: int = 100

var current: int = 100


func take_damage(amount: int) -> void:
	if amount <= 0 or current == 0:
		return
	current = maxi(current - amount, 0)
	damaged.emit(amount)
	if current == 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0 or current == 0:
		return
	current = mini(current + amount, max_health)


func is_alive() -> bool:
	return current > 0
