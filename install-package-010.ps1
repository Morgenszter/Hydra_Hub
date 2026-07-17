#requires -Version 5.1

[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Get-Location).Path,
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)

function Write-HydraFile {
    param(
        [Parameter(Mandatory)]
        [string]$RelativePath,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    $destination = Join-Path $RepositoryRoot $RelativePath
    $directory = Split-Path $destination -Parent

    if (-not (Test-Path $directory)) {
        [System.IO.Directory]::CreateDirectory($directory) | Out-Null
    }

    if ((Test-Path $destination) -and -not $Force) {
        Write-Host "[SKIP]  $RelativePath" -ForegroundColor Yellow
        return
    }

    [System.IO.File]::WriteAllText(
        $destination,
        $Content.TrimStart(),
        $utf8WithoutBom
    )

    Write-Host "[WRITE] $RelativePath" -ForegroundColor Green
}

function Assert-HydraRepository {
    $projectFile = Join-Path $RepositoryRoot "project.godot"

    if (-not (Test-Path $projectFile)) {
        throw "Nie znaleziono project.godot w: $RepositoryRoot"
    }
}

Assert-HydraRepository

$files = [ordered]@{}

$files["packages/010_device_hub/package.cfg"] = @'
[package]

id="010_device_hub"
name="Device Hub"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system"
)
'@

$files["packages/010_device_hub/README.md"] = @'
# Package 010 — Device Hub

Device Hub owns normalized smart-device identities, capabilities, operational
state, commands and the device-management interface.

Protocol-specific adapters implement DeviceProviderPort and remain isolated from
the domain and presentation layers.

## Responsibilities

Device Hub provides:

- Device discovery.
- Device inventory.
- Device state refresh.
- Capability-aware commands.
- Connection health.
- Device grouping and presentation.

Environment processing belongs to Package 009.
Automation orchestration belongs to Package 012.
'@

$files["packages/010_device_hub/CHANGELOG.md"] = @'
# Device Hub changelog

## [0.1.0] - 2026-07-17

### Added

- Added normalized device identity and state.
- Added capability and connection-state definitions.
- Added device command model.
- Added device provider contract.
- Added deterministic demo provider.
- Added Device Hub application service.
- Added device card and Device Hub panel.
- Added demo scene and tests.
'@

$files["packages/010_device_hub/docs/architecture.md"] = @'
# Device Hub architecture

Device Hub separates normalized device behavior from protocol implementations.

The domain layer owns device identity, capabilities and state transitions.

The application layer coordinates discovery, refresh and command execution.

The infrastructure layer contains adapters for protocols such as MQTT, Matter,
Home Assistant or vendor APIs.

The presentation layer displays normalized device state and never communicates
with protocol adapters directly.
'@

$files["packages/010_device_hub/docs/provider-contract.md"] = @'
# Device provider contract

A provider must expose a stable provider identifier.

Discovery returns normalized DeviceDescriptor values.

State refresh returns DeviceStateSnapshot values.

Command execution receives DeviceCommand and returns a Result.

Provider implementations must not expose credentials through logs, scenes or
resources committed to the repository.
'@

$files["packages/010_device_hub/resources/device_hub_configuration.gd"] = @'
class_name DeviceHubConfiguration
extends Resource
## Stores Device Hub runtime configuration.


#region Discovery

@export_group("Discovery")
@export var automatic_discovery_enabled: bool = true
@export_range(1.0, 3600.0, 1.0) var discovery_interval_seconds: float = 60.0

#endregion


#region Refresh

@export_group("Refresh")
@export var automatic_refresh_enabled: bool = true
@export_range(0.25, 300.0, 0.25) var refresh_interval_seconds: float = 5.0
@export_range(1.0, 3600.0, 1.0) var offline_timeout_seconds: float = 30.0

#endregion


#region Presentation

@export_group("Presentation")
@export var show_offline_devices: bool = true
@export var show_disabled_devices: bool = true
@export_range(1, 6, 1) var card_columns: int = 3
@export var card_width: float = 310.0
@export var card_height: float = 164.0
@export var card_horizontal_gap: float = 22.0
@export var card_vertical_gap: float = 20.0

#endregion
'@

$files["packages/010_device_hub/resources/default_device_hub_configuration.tres"] = @'
[gd_resource type="Resource" script_class="DeviceHubConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/010_device_hub/resources/device_hub_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
automatic_discovery_enabled = true
discovery_interval_seconds = 60.0
automatic_refresh_enabled = true
refresh_interval_seconds = 5.0
offline_timeout_seconds = 30.0
show_offline_devices = true
show_disabled_devices = true
card_columns = 3
card_width = 310.0
card_height = 164.0
card_horizontal_gap = 22.0
card_vertical_gap = 20.0
'@

$files["packages/010_device_hub/scripts/domain/device_connection_state.gd"] = @'
class_name DeviceConnectionState
extends RefCounted
## Defines normalized device connection states.


#region Values

enum Value {
	UNKNOWN,
	DISCOVERING,
	CONNECTING,
	ONLINE,
	DEGRADED,
	OFFLINE,
	ERROR,
}

#endregion


#region Public API

## Returns a stable lowercase state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.DISCOVERING:
			return &"discovering"
		Value.CONNECTING:
			return &"connecting"
		Value.ONLINE:
			return &"online"
		Value.DEGRADED:
			return &"degraded"
		Value.OFFLINE:
			return &"offline"
		Value.ERROR:
			return &"error"
		_:
			return &"unknown"


## Returns a presentation color for the state.
static func to_color(state: Value) -> Color:
	match state:
		Value.DISCOVERING:
			return Color("#32d8ff")
		Value.CONNECTING:
			return Color("#d6aa48")
		Value.ONLINE:
			return Color("#55f2a3")
		Value.DEGRADED:
			return Color("#ffbf47")
		Value.OFFLINE:
			return Color("#40515b")
		Value.ERROR:
			return Color("#ff4f62")
		_:
			return Color("#6e8794")

#endregion
'@

$files["packages/010_device_hub/scripts/domain/device_capability.gd"] = @'
class_name DeviceCapability
extends RefCounted
## Defines normalized device capability identifiers.


#region Values

enum Value {
	POWER,
	DIMMER,
	COLOR,
	TEMPERATURE,
	HUMIDITY,
	MOTION,
	CONTACT,
	LOCK,
	THERMOSTAT,
	ENERGY_METER,
	CAMERA,
	AUDIO,
	BATTERY,
}

#endregion


#region Public API

## Returns a stable capability identifier.
static func to_string_name(capability: Value) -> StringName:
	match capability:
		Value.POWER:
			return &"power"
		Value.DIMMER:
			return &"dimmer"
		Value.COLOR:
			return &"color"
		Value.TEMPERATURE:
			return &"temperature"
		Value.HUMIDITY:
			return &"humidity"
		Value.MOTION:
			return &"motion"
		Value.CONTACT:
			return &"contact"
		Value.LOCK:
			return &"lock"
		Value.THERMOSTAT:
			return &"thermostat"
		Value.ENERGY_METER:
			return &"energy_meter"
		Value.CAMERA:
			return &"camera"
		Value.AUDIO:
			return &"audio"
		Value.BATTERY:
			return &"battery"
		_:
			return &"unknown"

#endregion
'@

$files["packages/010_device_hub/scripts/domain/device_descriptor.gd"] = @'
class_name DeviceDescriptor
extends ValueObject
## Represents immutable device identity and capability metadata.


#region State

var _device_id: StringName
var _provider_id: StringName
var _display_name: String
var _manufacturer: String
var _model: String
var _zone_id: StringName
var _capabilities: Array[DeviceCapability.Value]
var _enabled: bool

#endregion


#region Construction

## Creates normalized device metadata.
func _init(
	device_id: StringName,
	provider_id: StringName,
	display_name: String,
	manufacturer: String,
	model: String,
	zone_id: StringName,
	capabilities: Array[DeviceCapability.Value],
	enabled: bool = true
) -> void:
	assert(
		not device_id.is_empty(),
		"DeviceDescriptor requires device_id."
	)
	assert(
		not provider_id.is_empty(),
		"DeviceDescriptor requires provider_id."
	)
	assert(
		not display_name.strip_edges().is_empty(),
		"DeviceDescriptor requires display_name."
	)

	_device_id = device_id
	_provider_id = provider_id
	_display_name = display_name.strip_edges()
	_manufacturer = manufacturer.strip_edges()
	_model = model.strip_edges()
	_zone_id = zone_id
	_capabilities = capabilities.duplicate()
	_enabled = enabled

#endregion


#region Public API

func get_device_id() -> StringName:
	return _device_id


func get_provider_id() -> StringName:
	return _provider_id


func get_display_name() -> String:
	return _display_name


func get_manufacturer() -> String:
	return _manufacturer


func get_model() -> String:
	return _model


func get_zone_id() -> StringName:
	return _zone_id


func get_capabilities() -> Array[DeviceCapability.Value]:
	return _capabilities.duplicate()


func is_enabled() -> bool:
	return _enabled


func has_capability(
	capability: DeviceCapability.Value
) -> bool:
	return capability in _capabilities

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_device_id,
		_provider_id,
		_display_name,
		_manufacturer,
		_model,
		_zone_id,
		_capabilities,
		_enabled,
	]

#endregion
'@

$files["packages/010_device_hub/scripts/domain/device_state_snapshot.gd"] = @'
class_name DeviceStateSnapshot
extends ValueObject
## Represents an immutable normalized device-state snapshot.


#region State

var _device_id: StringName
var _connection_state: DeviceConnectionState.Value
var _properties: Dictionary[StringName, Variant]
var _updated_at_unix_ms: int
var _battery_percent: float
var _signal_strength_percent: float

#endregion


#region Construction

## Creates a normalized device-state snapshot.
func _init(
	device_id: StringName,
	connection_state: DeviceConnectionState.Value,
	properties: Dictionary[StringName, Variant],
	updated_at_unix_ms: int,
	battery_percent: float = -1.0,
	signal_strength_percent: float = -1.0
) -> void:
	assert(
		not device_id.is_empty(),
		"DeviceStateSnapshot requires device_id."
	)
	assert(
		updated_at_unix_ms >= 0,
		"DeviceStateSnapshot timestamp cannot be negative."
	)

	_device_id = device_id
	_connection_state = connection_state
	_properties = properties.duplicate(true)
	_updated_at_unix_ms = updated_at_unix_ms
	_battery_percent = battery_percent
	_signal_strength_percent = signal_strength_percent

#endregion


#region Public API

func get_device_id() -> StringName:
	return _device_id


func get_connection_state() -> DeviceConnectionState.Value:
	return _connection_state


func get_properties() -> Dictionary[StringName, Variant]:
	return _properties.duplicate(true)


func get_property(
	property_id: StringName,
	default_value: Variant = null
) -> Variant:
	return _properties.get(property_id, default_value)


func get_updated_at_unix_ms() -> int:
	return _updated_at_unix_ms


func get_battery_percent() -> float:
	return _battery_percent


func get_signal_strength_percent() -> float:
	return _signal_strength_percent

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_device_id,
		_connection_state,
		_properties,
		_updated_at_unix_ms,
		_battery_percent,
		_signal_strength_percent,
	]

#endregion
'@

$files["packages/010_device_hub/scripts/domain/device_command.gd"] = @'
class_name DeviceCommand
extends RefCounted
## Represents an immutable command addressed to one normalized device.


#region State

var _command_id: StringName
var _device_id: StringName
var _command_name: StringName
var _arguments: Dictionary[StringName, Variant]
var _created_at_unix_ms: int
var _correlation_id: StringName

#endregion


#region Construction

## Creates a device command.
func _init(
	device_id: StringName,
	command_name: StringName,
	arguments: Dictionary[StringName, Variant] = {},
	correlation_id: StringName = &""
) -> void:
	assert(
		not device_id.is_empty(),
		"DeviceCommand requires device_id."
	)
	assert(
		not command_name.is_empty(),
		"DeviceCommand requires command_name."
	)

	_command_id = StringName(UUID.v4())
	_device_id = device_id
	_command_name = command_name
	_arguments = arguments.duplicate(true)
	_created_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	_correlation_id = correlation_id

	if _correlation_id.is_empty():
		_correlation_id = _command_id

#endregion


#region Public API

func get_command_id() -> StringName:
	return _command_id


func get_device_id() -> StringName:
	return _device_id


func get_command_name() -> StringName:
	return _command_name


func get_arguments() -> Dictionary[StringName, Variant]:
	return _arguments.duplicate(true)


func get_argument(
	argument_name: StringName,
	default_value: Variant = null
) -> Variant:
	return _arguments.get(argument_name, default_value)


func get_created_at_unix_ms() -> int:
	return _created_at_unix_ms


func get_correlation_id() -> StringName:
	return _correlation_id

#endregion
'@

$files["packages/010_device_hub/scripts/domain/managed_device.gd"] = @'
class_name ManagedDevice
extends AggregateRoot
## Owns normalized state for one managed device.


#region Events

const EVENT_DISCOVERED: StringName = \
	&"hydra.device.discovered"
const EVENT_STATE_UPDATED: StringName = \
	&"hydra.device.state_updated"
const EVENT_CONNECTION_CHANGED: StringName = \
	&"hydra.device.connection_changed"
const EVENT_COMMAND_COMPLETED: StringName = \
	&"hydra.device.command_completed"
const EVENT_COMMAND_FAILED: StringName = \
	&"hydra.device.command_failed"

#endregion


#region State

var _descriptor: DeviceDescriptor
var _state: DeviceStateSnapshot

#endregion


#region Construction

## Creates a managed device from immutable metadata.
func _init(
	id: EntityId,
	descriptor: DeviceDescriptor
) -> void:
	super(id)

	assert(
		descriptor != null,
		"ManagedDevice requires a descriptor."
	)

	_descriptor = descriptor

	_record_domain_event(
		DomainEvent.new(
			EVENT_DISCOVERED,
			{
				&"device_id": descriptor.get_device_id(),
				&"provider_id": descriptor.get_provider_id(),
				&"display_name": descriptor.get_display_name(),
			}
		)
	)

#endregion


#region Public API

func get_descriptor() -> DeviceDescriptor:
	return _descriptor


func get_state() -> DeviceStateSnapshot:
	return _state


func get_device_id() -> StringName:
	return _descriptor.get_device_id()


## Applies a new state snapshot.
func update_state(
	state: DeviceStateSnapshot
) -> Result:
	if state == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Device state cannot be null."
			)
		)

	if state.get_device_id() != get_device_id():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Device state belongs to another device.",
				{
					&"expected_device_id": get_device_id(),
					&"actual_device_id": state.get_device_id(),
				}
			)
		)

	var previous_connection_state := (
		DeviceConnectionState.Value.UNKNOWN
		if _state == null
		else _state.get_connection_state()
	)

	_state = state
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_UPDATED,
			{
				&"device_id": get_device_id(),
				&"connection_state":
					DeviceConnectionState.to_string_name(
						state.get_connection_state()
					),
				&"properties": state.get_properties(),
			}
		)
	)

	if previous_connection_state != state.get_connection_state():
		_record_domain_event(
			DomainEvent.new(
				EVENT_CONNECTION_CHANGED,
				{
					&"device_id": get_device_id(),
					&"previous_state":
						DeviceConnectionState.to_string_name(
							previous_connection_state
						),
					&"current_state":
						DeviceConnectionState.to_string_name(
							state.get_connection_state()
						),
				}
			)
		)

	return Result.success()


## Records successful command execution.
func record_command_completed(
	command: DeviceCommand
) -> void:
	if command == null:
		return

	_record_domain_event(
		DomainEvent.new(
			EVENT_COMMAND_COMPLETED,
			{
				&"device_id": get_device_id(),
				&"command_id": command.get_command_id(),
				&"command_name": command.get_command_name(),
			}
		)
	)


## Records failed command execution.
func record_command_failed(
	command: DeviceCommand,
	error: DomainError
) -> void:
	if command == null or error == null:
		return

	_record_domain_event(
		DomainEvent.new(
			EVENT_COMMAND_FAILED,
			{
				&"device_id": get_device_id(),
				&"command_id": command.get_command_id(),
				&"command_name": command.get_command_name(),
				&"error": error.to_dictionary(),
			}
		)
	)

#endregion
'@

$files["packages/010_device_hub/scripts/contracts/device_provider_port.gd"] = @'
@abstract
class_name DeviceProviderPort
extends RefCounted
## Defines a provider-independent device integration boundary.


#region Public API

## Returns the stable provider identifier.
@abstract
func get_provider_id() -> StringName


## Returns whether the provider is currently available.
@abstract
func is_available() -> bool


## Returns a Result containing Array[DeviceDescriptor].
@abstract
func discover_devices() -> Result


## Returns a Result containing DeviceStateSnapshot.
@abstract
func fetch_device_state(
	device_id: StringName
) -> Result


## Executes a normalized command.
@abstract
func execute_command(
	command: DeviceCommand
) -> Result

#endregion
'@

$files["packages/010_device_hub/scripts/infrastructure/demo_device_provider.gd"] = @'
class_name DemoDeviceProvider
extends DeviceProviderPort
## Provides deterministic local devices for development and demos.


#region Constants

const PROVIDER_ID: StringName = &"demo"

#endregion


#region State

var _power_states: Dictionary[StringName, bool] = {
	&"command_light": true,
	&"living_light": false,
	&"garage_lock": true,
	&"server_fan": true,
}

#endregion


#region DeviceProviderPort

func get_provider_id() -> StringName:
	return PROVIDER_ID


func is_available() -> bool:
	return true


func discover_devices() -> Result:
	var devices: Array[DeviceDescriptor] = [
		DeviceDescriptor.new(
			&"command_light",
			PROVIDER_ID,
			"COMMAND LIGHT ARRAY",
			"HYDRA LABS",
			"HL-LIGHT-01",
			&"command_room",
			[
				DeviceCapability.Value.POWER,
				DeviceCapability.Value.DIMMER,
				DeviceCapability.Value.COLOR,
				DeviceCapability.Value.ENERGY_METER,
			]
		),
		DeviceDescriptor.new(
			&"living_light",
			PROVIDER_ID,
			"LIVING ROOM LIGHT",
			"HYDRA LABS",
			"HL-LIGHT-02",
			&"living_room",
			[
				DeviceCapability.Value.POWER,
				DeviceCapability.Value.DIMMER,
			]
		),
		DeviceDescriptor.new(
			&"garage_lock",
			PROVIDER_ID,
			"GARAGE SECURITY LOCK",
			"HYDRA SECURITY",
			"HS-LOCK-04",
			&"garage",
			[
				DeviceCapability.Value.LOCK,
				DeviceCapability.Value.BATTERY,
			]
		),
		DeviceDescriptor.new(
			&"server_fan",
			PROVIDER_ID,
			"SERVER COOLING ARRAY",
			"HYDRA INDUSTRIAL",
			"HI-FAN-09",
			&"server_room",
			[
				DeviceCapability.Value.POWER,
				DeviceCapability.Value.DIMMER,
				DeviceCapability.Value.ENERGY_METER,
			]
		),
	]

	return Result.success(devices)


func fetch_device_state(
	device_id: StringName
) -> Result:
	if not _power_states.has(device_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Demo provider does not contain the requested device.",
				{&"device_id": device_id}
			)
		)

	var timestamp := int(
		Time.get_unix_time_from_system() * 1000.0
	)
	var properties: Dictionary[StringName, Variant] = {
		&"power": _power_states[device_id],
	}

	match device_id:
		&"command_light":
			properties[&"brightness"] = 78.0
			properties[&"power_watts"] = 42.0
		&"living_light":
			properties[&"brightness"] = 0.0
			properties[&"power_watts"] = 0.0
		&"garage_lock":
			properties[&"locked"] = _power_states[device_id]
		&"server_fan":
			properties[&"speed_percent"] = 64.0
			properties[&"power_watts"] = 118.0

	var battery_percent := (
		82.0
		if device_id == &"garage_lock"
		else -1.0
	)

	return Result.success(
		DeviceStateSnapshot.new(
			device_id,
			DeviceConnectionState.Value.ONLINE,
			properties,
			timestamp,
			battery_percent,
			92.0
		)
	)


func execute_command(
	command: DeviceCommand
) -> Result:
	if command == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Demo provider command cannot be null."
			)
		)

	var device_id := command.get_device_id()

	if not _power_states.has(device_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Demo provider does not contain the requested device.",
				{&"device_id": device_id}
			)
		)

	match command.get_command_name():
		&"set_power":
			_power_states[device_id] = bool(
				command.get_argument(&"enabled", false)
			)
		&"toggle_power":
			_power_states[device_id] = not _power_states[device_id]
		&"lock":
			_power_states[device_id] = true
		&"unlock":
			_power_states[device_id] = false
		_:
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_ARGUMENT,
					"Demo provider command is unsupported.",
					{
						&"device_id": device_id,
						&"command_name": command.get_command_name(),
					}
				)
			)

	return fetch_device_state(device_id)

#endregion
'@

$files["packages/010_device_hub/scripts/application/device_hub_service.gd"] = @'
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
'@

$files["packages/010_device_hub/scripts/presentation/device_card.gd"] = @'
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
'@

$files["packages/010_device_hub/scripts/presentation/device_hub_panel.gd"] = @'
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
'@

$files["packages/010_device_hub/scenes/device_card.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/010_device_hub/scripts/presentation/device_card.gd" id="1"]

[node name="DeviceCard" type="Control"]
custom_minimum_size = Vector2(310, 164)
layout_mode = 3
anchors_preset = 0
offset_right = 310.0
offset_bottom = 164.0
mouse_filter = 0
script = ExtResource("1")
widget_id = &"device_card"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.9)

[node name="Accent" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 12.0
offset_top = 12.0
offset_right = 18.0
offset_bottom = 152.0
mouse_filter = 2
color = Color(0.333333, 0.94902, 0.639216, 1)

[node name="DeviceName" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 12.0
offset_right = 286.0
offset_bottom = 42.0
mouse_filter = 2
bbcode_enabled = true
text = "[color=#32d8ff]DEVICE[/color]"
fit_content = true
scroll_active = false

[node name="ModelLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 44.0
offset_right = 286.0
offset_bottom = 68.0
mouse_filter = 2
text = "MANUFACTURER  //  MODEL"
fit_content = true
scroll_active = false

[node name="ZoneLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 70.0
offset_right = 286.0
offset_bottom = 94.0
mouse_filter = 2
text = "ZONE  //  UNKNOWN"
fit_content = true
scroll_active = false

[node name="StateLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 212.0
offset_top = 12.0
offset_right = 292.0
offset_bottom = 40.0
mouse_filter = 2
text = "UNKNOWN"
fit_content = true
scroll_active = false

[node name="PropertyLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 104.0
offset_right = 286.0
offset_bottom = 130.0
mouse_filter = 2
bbcode_enabled = true
text = "[color=#d6aa48]NO STATE DATA[/color]"
fit_content = true
scroll_active = false

[node name="BatteryLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 134.0
offset_right = 286.0
offset_bottom = 158.0
mouse_filter = 2
text = "SIGNAL  //  N/A"
fit_content = true
scroll_active = false
'@

$files["packages/010_device_hub/scenes/device_hub_panel.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/010_device_hub/scripts/presentation/device_hub_panel.gd" id="1"]

[node name="DeviceHubPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 1100.0
offset_bottom = 900.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"device_hub_panel"
starts_open = true

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.0117647, 0.0313725, 0.0509804, 0.97)

[node name="HeaderAccent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 28.0
offset_top = 24.0
offset_right = 34.0
offset_bottom = 94.0
mouse_filter = 2
color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 20.0
offset_right = 690.0
offset_bottom = 60.0
bbcode_enabled = true
text = "[font_size=30][color=#32d8ff]DEVICE HUB[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 900.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]DEVICE CONTROL AND TELEMETRY  //  CHANNEL 010[/color]"
fit_content = true
scroll_active = false

[node name="SummaryLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 116.0
offset_right = 1038.0
offset_bottom = 150.0
bbcode_enabled = true
text = "[color=#d6aa48]DEVICES  //  0    ONLINE  //  0    OFFLINE  //  0    ERRORS  //  0[/color]"
fit_content = true
scroll_active = false

[node name="DeviceLayer" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 1

[node name="ErrorLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 54.0
offset_top = 824.0
offset_right = 1046.0
offset_bottom = 884.0
bbcode_enabled = true
text = "[color=#ff4f62]DEVICE HUB ERROR[/color]"
scroll_active = false
'@

$files["packages/010_device_hub/demo/device_hub_demo.gd"] = @'
class_name DeviceHubDemo
extends Control
## Demonstrates Device Hub with deterministic local devices.


#region Nodes

@onready var _panel: DeviceHubPanel = %DeviceHubPanel

#endregion


#region State

var _service: DeviceHubService
var _configuration: DeviceHubConfiguration

#endregion


#region Lifecycle

func _ready() -> void:
	_service = DeviceHubService.new()
	_service.name = "DeviceHubService"
	add_child(_service)

	_configuration = DeviceHubConfiguration.new()

	var configuration_result := _service.configure(
		_configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	var provider := DemoDeviceProvider.new()
	var provider_result := _service.register_provider(provider)

	if provider_result.is_failure():
		push_error(
			provider_result.get_error().get_message()
		)
		return

	_panel.bind_service(
		_service,
		_configuration
	)
	_service.start()

#endregion
'@

$files["packages/010_device_hub/demo/device_hub_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/010_device_hub/demo/device_hub_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/010_device_hub/scenes/device_hub_panel.tscn" id="2"]

[node name="DeviceHubDemo" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00392157, 0.0117647, 0.0196078, 1)

[node name="DeviceHubPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 410.0
offset_top = 90.0
offset_right = 1510.0
offset_bottom = 990.0
'@

$files["packages/010_device_hub/tests/unit/test_device_descriptor.gd"] = @'
class_name DeviceDescriptorTest
extends RefCounted
## Provides DeviceDescriptor value-object tests.


#region Tests

static func run() -> void:
	var descriptor := DeviceDescriptor.new(
		&"device_01",
		&"test_provider",
		"TEST DEVICE",
		"HYDRA",
		"TEST-01",
		&"office",
		[
			DeviceCapability.Value.POWER,
			DeviceCapability.Value.DIMMER,
		]
	)

	assert(descriptor.get_device_id() == &"device_01")
	assert(descriptor.get_provider_id() == &"test_provider")
	assert(descriptor.get_display_name() == "TEST DEVICE")
	assert(
		descriptor.has_capability(
			DeviceCapability.Value.POWER
		)
	)
	assert(
		not descriptor.has_capability(
			DeviceCapability.Value.CAMERA
		)
	)

#endregion
'@

$files["packages/010_device_hub/tests/unit/test_managed_device.gd"] = @'
class_name ManagedDeviceTest
extends RefCounted
## Provides ManagedDevice aggregate tests.


#region Tests

static func run() -> void:
	var descriptor := DeviceDescriptor.new(
		&"device_01",
		&"test_provider",
		"TEST DEVICE",
		"HYDRA",
		"TEST-01",
		&"office",
		[DeviceCapability.Value.POWER]
	)
	var device := ManagedDevice.new(
		EntityId.generate(),
		descriptor
	)
	var snapshot := DeviceStateSnapshot.new(
		&"device_01",
		DeviceConnectionState.Value.ONLINE,
		{&"power": true},
		1000
	)

	assert(device.update_state(snapshot).is_success())
	assert(device.get_state() == snapshot)
	assert(
		device.get_state().get_connection_state()
		== DeviceConnectionState.Value.ONLINE
	)
	assert(not device.pull_domain_events().is_empty())

#endregion
'@

$files["packages/010_device_hub/tests/unit/test_device_command.gd"] = @'
class_name DeviceCommandTest
extends RefCounted
## Provides DeviceCommand tests.


#region Tests

static func run() -> void:
	var command := DeviceCommand.new(
		&"device_01",
		&"set_power",
		{&"enabled": true}
	)

	assert(not command.get_command_id().is_empty())
	assert(command.get_device_id() == &"device_01")
	assert(command.get_command_name() == &"set_power")
	assert(command.get_argument(&"enabled") == true)
	assert(not command.get_correlation_id().is_empty())

#endregion
'@

$files["packages/010_device_hub/tests/integration/test_device_hub_service.gd"] = @'
class_name DeviceHubServiceTest
extends RefCounted
## Provides Device Hub service composition tests.


#region Tests

static func run() -> void:
	var service := DeviceHubService.new()
	var configuration := DeviceHubConfiguration.new()
	var provider := DemoDeviceProvider.new()

	assert(service.configure(configuration).is_success())
	assert(service.register_provider(provider).is_success())

#endregion
'@

$files["autoload/device_hub.gd"] = @'
extends DeviceHubService
## Global Device Hub application service.
##
## Runtime composition must configure Device Hub and register provider adapters.
'@

$files["docs/package-dependencies-010.md"] = @'
# Package dependency 010

```text
010_device_hub
├── 001_foundation
├── 002_design_system
├── 003_widget_library
└── 004_animation_system
'@

Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing Package 010 - Device Hub..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

Write-Host ""
Write-Host "Package 010 installed." -ForegroundColor Green
Write-Host ""
Write-Host "Optional autoload:" -ForegroundColor Cyan
Write-Host "DeviceHub res://autoload/device_hub.gd"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(device-hub): implement package 010"'
Write-Host "git push"