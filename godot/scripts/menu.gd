class_name Menu extends Control

@export_category("Nodes")
@export var play_button: Button

signal started


func _ready() -> void:
	assert(play_button, "menu.gd - @export play_button is not set in the editor on: " + self.name)
	var _error: int = play_button.pressed.connect(func() -> void: _report_started())


func _report_started() -> void:
	started.emit()
