class_name DeviceHubPanel
extends PanelBase
## Main device discovery and management panel.


#region Constants

const CARD_START_X: float = 52.0
const CARD_START_Y: float = 184.0

#endregion


#region Nodes

@onready var _device_layer: Control = %DeviceLayer
@onready var _summary_label: RichTextLabel = %SummaryLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: DeviceHubService
var _configuration: DeviceHubConfiguration
var _device_card_scene: PackedScene = preload(
	"res://packages/010_device_hub/scenes/device_card.tscn"
)

#endregion


#region Public API

## Binds the panel to Device Hub.
func bind_service(
	service: DeviceHubService,
	configuration: DeviceHubConfiguration
) -> void:
	assert(service != null, "Device Hub service cannot be null.")
	assert(
		configuration != null,
		"Device Hub configuration cannot be null."
	)

	_disconnect_service()
	_service = service
	_configuration = configuration

	_service.discovery_completed.connect(
		_on_discovery_completed
	)
	_service.device_registered.connect(
		_on_device_registered
	)
	_service.device_updated.connect(
		_on_device_updated
	)
	_service.device_command_failed.connect(
		_on_device_command_failed
	)
	_service.operation_failed.connect(
		_on_operation_failed
	)

	rebuild_cards()


## Rebuilds device cards.
func rebuild_cards() -> void:
	if _service == null or _configuration == null:
		return

	var devices := _service.get_devices()
	_render_devices(devices)
	_update_summary(devices)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.discovery_completed.is_connected(
		_on_discovery_completed
	):
		_service.discovery_completed.disconnect(
			_on_discovery_completed
		)

	if _service.device_registered.is_connected(
		_on_device_registered
	):
		_service.device_registered.disconnect(
			_on_device_registered
		)

	if _service.device_updated.is_connected(
		_on_device_updated
	):
		_service.device_updated.disconnect(
			_on_device_updated
		)

	if _service.device_command_failed.is_connected(
		_on_device_command_failed
	):
		_service.device_command_failed.disconnect(
			_on_device_command_failed
		)

	if _service.operation_failed.is_connected(
		_on_operation_failed
	):
		_service.operation_failed.disconnect(
			_on_operation_failed
		)


func _render_devices(
	devices: Array[ManagedDevice]
) -> void:
	for child in _device_layer.get_children():
		child.queue_free()

	for index in devices.size():
		var card := (
			_device_card_scene.instantiate()
			as DeviceCard
		)
		var column := index % _configuration.card_columns
		var row := index / _configuration.card_columns

		card.position = Vector2(
			CARD_START_X + (
				column * (
					_configuration.card_width
					+ _configuration.card_horizontal_gap
				)
			),
			CARD_START_Y + (
				row * (
					_configuration.card_height
					+ _configuration.card_vertical_gap
				)
			)
		)
		card.size = Vector2(
			_configuration.card_width,
			_configuration.card_height
		)

		_device_layer.add_child(card)
		card.apply_device(devices[index])
		card.primary_action_requested.connect(
			_on_primary_action_requested
		)


func _update_summary(
	devices: Array[ManagedDevice]
) -> void:
	var online_count := 0
	var offline_count := 0
	var error_count := 0

	for device in devices:
		var state := device.get_state()

		if state == null:
			continue

		match state.get_connection_state():
			DeviceConnectionState.Value.ONLINE:
				online_count += 1
			DeviceConnectionState.Value.OFFLINE:
				offline_count += 1
			DeviceConnectionState.Value.ERROR:
				error_count += 1

	_summary_label.text = (
		"DEVICES  //  %d    ONLINE  //  %d    OFFLINE  //  %d    ERRORS  //  %d"
		% [
			devices.size(),
			online_count,
			offline_count,
			error_count,
		]
	)


func _on_primary_action_requested(
	device_id: StringName
) -> void:
	if _service == null:
		return

	var device := _service.get_device(device_id)

	if device == null:
		return

	var descriptor := device.get_descriptor()
	var command_name := &"toggle_power"

	if descriptor.has_capability(
		DeviceCapability.Value.LOCK
	):
		var state := device.get_state()
		var locked := false

		if state != null:
			locked = bool(
				state.get_property(&"locked", false)
			)

		command_name = &"unlock" if locked else &"lock"

	var command := DeviceCommand.new(
		device_id,
		command_name
	)

	var result := _service.execute_command(command)

	if result.is_failure():
		_on_operation_failed(result.get_error())


func _on_discovery_completed(
	devices: Array[ManagedDevice]
) -> void:
	_error_label.visible = false
	_render_devices(devices)
	_update_summary(devices)


func _on_device_registered(
	_device: ManagedDevice
) -> void:
	rebuild_cards()


func _on_device_updated(
	_device: ManagedDevice
) -> void:
	rebuild_cards()


func _on_device_command_failed(
	_device: ManagedDevice,
	_command: DeviceCommand,
	error: DomainError
) -> void:
	_on_operation_failed(error)


func _on_operation_failed(
	error: DomainError
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]DEVICE HUB ERROR[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

#endregion