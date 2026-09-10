class_name Weapon extends Node

signal fired(target: Vector2)

@export var ammo: int = 6


func can_fire() -> bool:
	return ammo > 0


func fire(target: Vector2) -> void:
	if not can_fire():
		return
	ammo -= 1
	fired.emit(target)


func reload() -> void:
	ammo = 6
