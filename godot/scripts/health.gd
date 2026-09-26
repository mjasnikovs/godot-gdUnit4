class_name Health extends Node

@export_category("Settings")
@export var max_health: int = 100

# Seeded here for a Health built with new() and never added to a tree. A node in
# a scene gets its exported max_health after _init, so _ready reseeds from it.
var c_health: int = max_health

signal damaged(amount: int)
signal died


func _ready() -> void:
	c_health = max_health


func take_damage(amount: int) -> void:
	if amount <= 0 or c_health == 0:
		return
	c_health = maxi(c_health - amount, 0)
	damaged.emit(amount)
	if c_health == 0:
		died.emit()


func heal(amount: int) -> void:
	if amount <= 0 or c_health == 0:
		return
	c_health = mini(c_health + amount, max_health)


func is_alive() -> bool:
	return c_health > 0
