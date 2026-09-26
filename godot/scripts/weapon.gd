class_name Weapon extends Node

@export_category("Settings")
@export var max_ammo: int = 6

var c_ammo: int = max_ammo

signal fired(target: Vector2)


func _ready() -> void:
	c_ammo = max_ammo


func can_fire() -> bool:
	return c_ammo > 0


func fire(target: Vector2) -> void:
	if !can_fire():
		return
	c_ammo -= 1
	fired.emit(target)


func reload() -> void:
	c_ammo = max_ammo
