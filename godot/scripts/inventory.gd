class_name Inventory extends RefCounted

const CAPACITY: int = 4

var _slots: Array[String] = []


func add(item: String) -> bool:
	if _slots.size() >= CAPACITY or _slots.has(item):
		return false
	_slots.append(item)
	return true


func drop(item: String) -> bool:
	var index: int = _slots.find(item)
	if index == -1:
		return false
	_slots.remove_at(index)
	return true


func items() -> Array[String]:
	return _slots.duplicate()


func is_full() -> bool:
	return _slots.size() >= CAPACITY
