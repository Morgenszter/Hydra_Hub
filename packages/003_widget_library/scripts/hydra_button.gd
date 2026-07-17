class_name HydraButton
extends WidgetBase
## Military HUD button with explicit manual layout.


#region Signals

signal pressed(action_id: StringName)

#endregion


#region Exported properties

@export var action_id: StringName = &""
@export var text: String = "ACTION"
@export var accent_color: Color = Color("#32d8ff")

#endregion


#region Nodes

@onready var _background: NinePatchRect = %Background
@onready var _label: RichTextLabel = %Label

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_label.text = text
	_background.modulate = accent_color


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and mouse_event.pressed
		):
			pressed.emit(action_id)
			accept_event()

#endregion