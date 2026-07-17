class_name ModuleLauncherWidget
extends WidgetBase
## Displays and activates one Central Hub route.


#region Signals

signal route_requested(route_id: StringName)

#endregion


#region Nodes

@onready var _accent: ColorRect = %Accent
@onready var _title: RichTextLabel = %Title
@onready var _description: RichTextLabel = %Description
@onready var _status: RichTextLabel = %Status

#endregion


#region State

var _route: HubRoute

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if _route == null or not _route.enabled:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and mouse_event.pressed
		):
			route_requested.emit(_route.route_id)
			accept_event()

#endregion


#region Public API

## Applies route metadata.
func apply_route(route: HubRoute) -> void:
	assert(route != null, "Module launcher route cannot be null.")

	_route = route

	if not is_node_ready():
		return

	_accent.color = route.accent_color
	_title.text = route.display_name
	_description.text = route.description
	_status.text = (
		"AVAILABLE"
		if route.enabled
		else "OFFLINE"
	)
	modulate = (
		Color.WHITE
		if route.enabled
		else Color(0.45, 0.5, 0.55, 1.0)
	)

#endregion