class_name DeviceHubService
extends Node
## Coordinates device discovery, refresh and command execution.


#region Signals

signal discovery_completed(devices: Array[ManagedDevice])
signal device_registered(device: ManagedDevice)
signal device_updated(device: ManagedDevice)
signal device_command_completed(
	device: ManagedDevice,
	command: DeviceCommand
)
signal device_command_failed(
	device: ManagedDevice,
	command: DeviceCommand,
	error: DomainError
)
signal operation_failed(error: DomainError)

#endregion


#region State

var _configuration: DeviceHubConfiguration
var _providers: Dictionary[StringName, DeviceProviderPort] = {}
var _devices: Dictionary[StringName, ManagedDevice] = {}
var _refresh_timer: Timer
var _discovery_timer: Timer

#endregion


#region Lifecycle

func _ready() -> void:
	_refresh_timer = Timer.new()
	_refresh_timer.name = "DeviceRefreshTimer"
	_refresh_timer.one_shot = false
	_refresh_timer.timeout.connect(_on_refresh_timeout)
	add_child(_refresh_timer)

	_discovery_timer = Timer.new()
	_discovery_timer.name = "DeviceDiscoveryTimer"
	_discovery_timer.one_shot = false
	_discovery_timer.timeout.connect(_on_discovery_timeout)
	add_child(_discovery_timer)

#endregion


#region Public API

## Configures Device Hub.
func configure(
	configuration: DeviceHubConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Device Hub configuration cannot be null."
			)
		)

	if configuration.card_columns <= 0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Device Hub card_columns must be positive."
			)
		)

	_configuration = configuration
	_refresh_timer.wait_time = configuration.refresh_interval_seconds
	_discovery_timer.wait_time = configuration.discovery_interval_seconds

	return Result.success()


## Registers a provider adapter.
func register_provider(
	provider: DeviceProviderPort
) -> Result:
	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Device provider cannot be null."
			)
		)

	var provider_id := provider.get_provider_id()

	if provider_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Device provider requires a provider identifier."
			)
		)

	if _providers.has(provider_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_ALREADY_REGISTERED,
				"Device provider is already registered.",
				{&"provider_id": provider_id}
			)
		)

	_providers[provider_id] = provider

	return Result.success()


## Starts automatic discovery and refresh.
func start() -> Result:
	if _configuration == null:
		return _not_configured()

	if _configuration.automatic_discovery_enabled:
		_discovery_timer.start()

	if _configuration.automatic_refresh_enabled:
		_refresh_timer.start()

	return discover_devices()


## Stops automatic Device Hub operations.
func stop() -> void:
	_discovery_timer.stop()
	_refresh_timer.stop()


## Discovers devices through all available providers.
func discover_devices() -> Result:
	if _configuration == null:
		return _not_configured()

	for provider: DeviceProviderPort in _providers.values():
		if not provider.is_available():
			continue

		var discovery_result := provider.discover_devices()

		if discovery_result.is_failure():
			operation_failed.emit(discovery_result.get_error())
			continue

		var descriptors: Array = discovery_result.get_value()

		for descriptor in descriptors:
			if descriptor is DeviceDescriptor:
				_register_descriptor(
					descriptor as DeviceDescriptor
				)

	var devices := get_devices()
	discovery_completed.emit(devices)

	var refresh_result := refresh_all()

	if refresh_result.is_failure():
		return refresh_result

	return Result.success(devices)


## Refreshes all registered device states.
func refresh_all() -> Result:
	for device: ManagedDevice in _devices.values():
		var result := refresh_device(device.get_device_id())

		if result.is_failure():
			continue

	return Result.success(get_devices())


## Refreshes one device state.
func refresh_device(
	device_id: StringName
) -> Result:
	var device := _devices.get(device_id) as ManagedDevice

	if device == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Device Hub does not contain the requested device.",
				{&"device_id": device_id}
			)
		)

	var provider_id := device.get_descriptor().get_provider_id()
	var provider := _providers.get(provider_id) as DeviceProviderPort

	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Device provider is not registered.",
				{&"provider_id": provider_id}
			)
		)

	var state_result := provider.fetch_device_state(device_id)

	if state_result.is_failure():
		operation_failed.emit(state_result.get_error())
		return state_result

	var snapshot := state_result.get_value() as DeviceStateSnapshot
	var update_result := device.update_state(snapshot)

	if update_result.is_failure():
		operation_failed.emit(update_result.get_error())
		return update_result

	_publish_device_events(device)
	device_updated.emit(device)

	return Result.success(device)


## Executes a command through the owning provider.
func execute_command(
	command: DeviceCommand
) -> Result:
	if command == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Device command cannot be null."
			)
		)

	var device := _devices.get(
		command.get_device_id()
	) as ManagedDevice

	if device == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Device command target does not exist.",
				{&"device_id": command.get_device_id()}
			)
		)

	if not device.get_descriptor().is_enabled():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Device is disabled.",
				{&"device_id": command.get_device_id()}
			)
		)

	var provider_id := device.get_descriptor().get_provider_id()
	var provider := _providers.get(provider_id) as DeviceProviderPort

	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Device provider is not registered.",
				{&"provider_id": provider_id}
			)
		)

	var command_result := provider.execute_command(command)

	if command_result.is_failure():
		var error := command_result.get_error()

		device.record_command_failed(command, error)
		_publish_device_events(device)
		device_command_failed.emit(device, command, error)

		return command_result

	var state := command_result.get_value() as DeviceStateSnapshot

	if state != null:
		device.update_state(state)

	device.record_command_completed(command)
	_publish_device_events(device)
	device_updated.emit(device)
	device_command_completed.emit(device, command)

	return Result.success(device)


## Returns all managed devices sorted by display name.
func get_devices() -> Array[ManagedDevice]:
	var result: Array[ManagedDevice] = []

	for device: ManagedDevice in _devices.values():
		if (
			not _configuration.show_disabled_devices
			and not device.get_descriptor().is_enabled()
		):
			continue

		if (
			not _configuration.show_offline_devices
			and device.get_state() != null
			and device.get_state().get_connection_state()
				== DeviceConnectionState.Value.OFFLINE
		):
			continue

		result.append(device)

	result.sort_custom(
		func(left: ManagedDevice, right: ManagedDevice) -> bool:
			return (
				left.get_descriptor().get_display_name()
				< right.get_descriptor().get_display_name()
			)
	)

	return result


## Returns one managed device.
func get_device(
	device_id: StringName
) -> ManagedDevice:
	return _devices.get(device_id)

#endregion


#region Private methods

func _register_descriptor(
	descriptor: DeviceDescriptor
) -> void:
	if _devices.has(descriptor.get_device_id()):
		return

	var device := ManagedDevice.new(
		EntityId.from_string(
			String(descriptor.get_device_id())
		),
		descriptor
	)

	_devices[descriptor.get_device_id()] = device
	_publish_device_events(device)
	device_registered.emit(device)


func _publish_device_events(
	device: ManagedDevice
) -> void:
	var events := device.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Device Hub is not configured."
		)
	)


func _on_refresh_timeout() -> void:
	refresh_all()


func _on_discovery_timeout() -> void:
	discover_devices()

#endregion