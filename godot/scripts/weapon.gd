class_name Weapon extends Node

signal fired(target: Vector2)

@export var max_ammo: int = 6

var ammo: int = max_ammo


func _ready() -> void:
	ammo = max_ammo


func can_fire() -> bool:
	return ammo > 0


func fire(target: Vector2) -> void:
	if not can_fire():
		return
	ammo -= 1
	fired.emit(target)


func reload() -> void:
	ammo = max_ammo
