class_name Health extends Node

@export var max_health: int = 100

# Seeded here for a Health built with new() and never added to a tree. A node in
# a scene gets its exported max_health after _init, so _ready reseeds from it.
var current: int = max_health

signal damaged(amount: int)
signal died


func _ready() -> void:
	current = max_health


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
