@abstract
class_name WidgetBase
extends Control
## Base class for reusable HYDRA HUD widgets.


#region Signals

signal widget_ready(widget_id: StringName)
signal widget_enabled(widget_id: StringName)
signal widget_disabled(widget_id: StringName)

#endregion


#region Exported properties

@export var widget_id: StringName = &""
@export var starts_enabled: bool = true

#endregion


#region Lifecycle

func _ready() -> void:
	assert(not widget_id.is_empty(), "WidgetBase requires widget_id.")

	set_process(starts_enabled)
	visible = starts_enabled
	_on_widget_ready()
	widget_ready.emit(widget_id)


func enable_widget() -> void:
	set_process(true)
	visible = true
	_on_widget_enabled()
	widget_enabled.emit(widget_id)


func disable_widget() -> void:
	set_process(false)
	visible = false
	_on_widget_disabled()
	widget_disabled.emit(widget_id)

#endregion


#region Extension points

func _on_widget_ready() -> void:
	pass


func _on_widget_enabled() -> void:
	pass


func _on_widget_disabled() -> void:
	pass

#endregion