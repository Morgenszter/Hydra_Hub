class_name TacticalNavigationRail
extends WidgetBase
## Displays Final HUD module navigation buttons.


#region Signals

signal route_requested(route_id: StringName)

#endregion


#region Constants

const BUTTON_HEIGHT: float = 62.0
const BUTTON_GAP: float = 12.0
const BUTTON_START_Y: float = 110.0
const BUTTON_LEFT: float = 18.0
const BUTTON_RIGHT: float = 242.0

#endregion


#region Nodes

@onready var _button_layer: Control = %ButtonLayer
@onready var _active_label: RichTextLabel = %ActiveLabel

#endregion


#region State

var _service: FinalHudService
var _buttons: Dictionary[StringName, Button] = {}

#endregion


#region Public API

## Binds this navigation rail to FinalHudService.
func bind_service(service: FinalHudService) -> void:
	assert(service != null, "Final HUD service cannot be null.")

	_disconnect_service()
	_service = service
	_service.module_registered.connect(
		_on_module_registered
	)
	_service.route_changed.connect(
		_on_route_changed
	)

	rebuild_modules()


## Rebuilds navigation buttons.
func rebuild_modules() -> void:
	for child in _button_layer.get_children():
		child.queue_free()

	_buttons.clear()

	if _service == null:
		return

	var modules := _service.get_modules()

	for index in modules.size():
		var module := modules[index]
		var button := Button.new()

		button.name = "Route_%s" % module.route_id
		button.text = (
			module.short_label
			if not module.short_label.is_empty()
			else module.display_name
		)
		button.position = Vector2(
			BUTTON_LEFT,
			BUTTON_START_Y + (
				index * (BUTTON_HEIGHT + BUTTON_GAP)
			)
		)
		button.size = Vector2(
			BUTTON_RIGHT - BUTTON_LEFT,
			BUTTON_HEIGHT
		)
		button.disabled = not module.enabled
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND
		)

		button.pressed.connect(
			_on_route_button_pressed.bind(
				module.route_id
			)
		)

		_button_layer.add_child(button)
		_buttons[module.route_id] = button

	_refresh_active_state(
		_service.get_active_route_id()
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.module_registered.is_connected(
		_on_module_registered
	):
		_service.module_registered.disconnect(
			_on_module_registered
		)

	if _service.route_changed.is_connected(
		_on_route_changed
	):
		_service.route_changed.disconnect(
			_on_route_changed
		)


func _refresh_active_state(
	route_id: StringName
) -> void:
	for current_route_id in _buttons:
		var button := _buttons[current_route_id]
		button.modulate = (
			Color("#d6aa48")
			if current_route_id == route_id
			else Color.WHITE
		)

	var module_name := "NONE"

	if _service != null:
		for module in _service.get_modules():
			if module.route_id == route_id:
				module_name = module.display_name
				break

	_active_label.text = (
		"ACTIVE  //  %s"
		% module_name
	)


func _on_route_button_pressed(
	route_id: StringName
) -> void:
	route_requested.emit(route_id)

	if _service != null:
		_service.activate_route(route_id)


func _on_module_registered(
	_module: HudModuleDefinition
) -> void:
	rebuild_modules()


func _on_route_changed(
	module: HudModuleDefinition,
	_previous_route_id: StringName
) -> void:
	_refresh_active_state(module.route_id)

#endregion