class_name Turret extends Node

@export var weapon: Weapon

var range_px: float = 200.0


## Fires at target when a weapon is wired, loaded and the target is in range.
func engage(from: Vector2, target: Vector2) -> bool:
	if weapon == null:
		return false
	if from.distance_to(target) > range_px:
		return false
	if not weapon.can_fire():
		return false
	weapon.fire(target)
	return true
