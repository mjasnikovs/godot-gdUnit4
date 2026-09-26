class_name Turret extends Node

# Handed in by the code that builds the turret, so it is not an export. A turret
# with no weapon is a valid state and never engages.
var weapon: Weapon
var range_px: float = 200.0


func engage(from: Vector2, target: Vector2) -> bool:
	if weapon == null:
		return false
	if from.distance_to(target) > range_px:
		return false
	if !weapon.can_fire():
		return false
	weapon.fire(target)
	return true
