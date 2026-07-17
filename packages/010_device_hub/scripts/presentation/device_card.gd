class_name DeviceCard
extends WidgetBase
## Displays one managed device and exposes its primary action.


#region Signals

signal primary_action_requested(device_id: StringName)

#endregion


#region Nodes

@onready var _accent: ColorRect = %Accent
@onready var _device_name: RichTextLabel = %DeviceName
@onready var _model_label: RichTextLabel = %ModelLabel
@onready var _zone_label: RichTextLabel = %ZoneLabel
@onready var _state_label: RichTextLabel = %StateLabel
@onready var _property_label: RichTextLabel = %PropertyLabel
@onready var _battery_label: RichTextLabel = %BatteryLabel

#endregion


#region State

var _device: ManagedDevice

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _gui_input(event: InputEvent) -> void:
	if _device == null:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		if (
			mouse_event.button_index == MOUSE_BUTTON_LEFT
			and mouse_event.pressed
		):
			primary_action_requested.emit(
				_device.get_device_id()
			)
			accept_event()

#endregion


#region Public API

## Applies a managed-device snapshot.
func apply_device(device: ManagedDevice) -> void:
	assert(device != null, "Device card requires a device.")

	_device = device

	if not is_node_ready():
		return

	var descriptor := device.get_descriptor()
	var state := device.get_state()
	var connection_state := DeviceConnectionState.Value.UNKNOWN

	if state != null:
		connection_state = state.get_connection_state()

	_device_name.text = descriptor.get_display_name()
	_model_label.text = "%s  //  %s" % [
		descriptor.get_manufacturer(),
		descriptor.get_model(),
	]
	_zone_label.text = (
		"ZONE  //  %s"
		% String(descriptor.get_zone_id()).to_upper()
	)
	_state_label.text = String(
		DeviceConnectionState.to_string_name(
			connection_state
		)
	).to_upper()
	_accent.color = DeviceConnectionState.to_color(
		connection_state
	)

	_property_label.text = _build_property_text(state)
	_battery_label.text = _build_battery_text(state)

#endregion


#region Private methods

func _build_property_text(
	state: DeviceStateSnapshot
) -> String:
	if state == null:
		return "NO STATE DATA"

	var properties := state.get_properties()

	if properties.has(&"locked"):
		return (
			"LOCKED"
			if bool(properties[&"locked"])
			else "UNLOCKED"
		)

	if properties.has(&"power"):
		var power_text := (
			"POWER ON"
			if bool(properties[&"power"])
			else "POWER OFF"
		)

		if properties.has(&"brightness"):
			power_text += "  //  %d%%" % int(
				properties[&"brightness"]
			)

		if properties.has(&"speed_percent"):
			power_text += "  //  SPEED %d%%" % int(
				properties[&"speed_percent"]
			)

		return power_text

	return "STATE AVAILABLE"


func _build_battery_text(
	state: DeviceStateSnapshot
) -> String:
	if state == null:
		return "SIGNAL  //  N/A"

	var battery := state.get_battery_percent()
	var signal_strength := state.get_signal_strength_percent()

	if battery >= 0.0:
		return "BATTERY  //  %d%%" % int(battery)

	if signal_strength >= 0.0:
		return "SIGNAL  //  %d%%" % int(signal_strength)

	return "SIGNAL  //  N/A"

#endregion