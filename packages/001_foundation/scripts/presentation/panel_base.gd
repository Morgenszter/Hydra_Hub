@abstract
class_name PanelBase
extends Control
## Base class for top-level HYDRA interface panels.


#region Signals

signal panel_opened(panel_id: StringName)
signal panel_closed(panel_id: StringName)

#endregion


#region Exported properties

@export var panel_id: StringName = &""
@export var starts_open: bool = false

#endregion


#region Lifecycle

func _ready() -> void:
	assert(not panel_id.is_empty(), "PanelBase requires panel_id.")

	visible = starts_open

	if starts_open:
		_on_panel_opened()


func open_panel() -> void:
	if visible:
		return

	visible = true
	_on_panel_opened()
	panel_opened.emit(panel_id)


func close_panel() -> void:
	if not visible:
		return

	_on_panel_closed()
	visible = false
	panel_closed.emit(panel_id)

#endregion


#region Extension points

func _on_panel_opened() -> void:
	pass


func _on_panel_closed() -> void:
	pass

#endregion