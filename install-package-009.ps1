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

$files["packages/009_environment_hub/package.cfg"] = @'
[package]

id="009_environment_hub"
name="Environment Hub"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system"
)
'@

$files["packages/009_environment_hub/README.md"] = @'
# Package 009 — Environment Hub

Environment Hub monitors indoor and outdoor environmental conditions.

It owns normalized environmental readings, zone snapshots, alert evaluation and
the environmental command panel.

## Responsibilities

Environment Hub processes temperature, humidity, air quality, pressure, light,
noise and particulate readings.

Device communication remains in Package 010.
Automation reactions remain in Package 012.
'@

$files["packages/009_environment_hub/CHANGELOG.md"] = @'
# Environment Hub changelog

## [0.1.0] - 2026-07-17

### Added

- Added environmental metric types.
- Added immutable environmental readings.
- Added zone environment aggregate.
- Added threshold evaluation.
- Added Environment Hub service.
- Added environment metric and zone widgets.
- Added Environment Hub panel.
- Added demo provider and tests.
'@

$files["packages/009_environment_hub/docs/architecture.md"] = @'
# Environment Hub architecture

Environment Hub normalizes environmental data behind a provider contract.

The domain layer owns readings, thresholds and zone state.

The application layer refreshes snapshots and publishes domain events.

The presentation layer consumes normalized snapshots and never talks directly
to sensors.
'@

$files["packages/009_environment_hub/docs/metrics.md"] = @'
# Environmental metrics

Supported metrics:

- Temperature in degrees Celsius.
- Relative humidity in percent.
- Carbon dioxide in parts per million.
- PM2.5 concentration in micrograms per cubic metre.
- Atmospheric pressure in hectopascals.
- Illuminance in lux.
- Noise level in decibels.
- Volatile organic compound index.
'@

$files["packages/009_environment_hub/resources/environment_thresholds.gd"] = @'
class_name EnvironmentThresholds
extends Resource
## Defines warning and critical environmental thresholds.


#region Temperature

@export_group("Temperature")
@export var minimum_temperature_warning_celsius: float = 16.0
@export var minimum_temperature_critical_celsius: float = 10.0
@export var maximum_temperature_warning_celsius: float = 28.0
@export var maximum_temperature_critical_celsius: float = 35.0

#endregion


#region Humidity

@export_group("Humidity")
@export_range(0.0, 100.0, 0.5) var minimum_humidity_warning_percent: float = 30.0
@export_range(0.0, 100.0, 0.5) var maximum_humidity_warning_percent: float = 65.0
@export_range(0.0, 100.0, 0.5) var maximum_humidity_critical_percent: float = 80.0

#endregion


#region Air quality

@export_group("Air Quality")
@export var co2_warning_ppm: float = 1000.0
@export var co2_critical_ppm: float = 2000.0
@export var pm25_warning_ug_m3: float = 25.0
@export var pm25_critical_ug_m3: float = 50.0
@export var voc_warning_index: float = 150.0
@export var voc_critical_index: float = 250.0

#endregion
'@

$files["packages/009_environment_hub/resources/environment_hub_configuration.gd"] = @'
class_name EnvironmentHubConfiguration
extends Resource
## Stores Environment Hub runtime configuration.


#region Refresh

@export_group("Refresh")
@export_range(0.25, 120.0, 0.25) var refresh_interval_seconds: float = 3.0
@export var automatic_refresh_enabled: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export var temperature_decimals: int = 1
@export var humidity_decimals: int = 0
@export var air_quality_decimals: int = 0
@export var show_inactive_zones: bool = true

#endregion


#region Thresholds

@export_group("Thresholds")
@export var thresholds: EnvironmentThresholds

#endregion
'@

$files["packages/009_environment_hub/resources/default_environment_thresholds.tres"] = @'
[gd_resource type="Resource" script_class="EnvironmentThresholds" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/009_environment_hub/resources/environment_thresholds.gd" id="1"]

[resource]
script = ExtResource("1")
minimum_temperature_warning_celsius = 16.0
minimum_temperature_critical_celsius = 10.0
maximum_temperature_warning_celsius = 28.0
maximum_temperature_critical_celsius = 35.0
minimum_humidity_warning_percent = 30.0
maximum_humidity_warning_percent = 65.0
maximum_humidity_critical_percent = 80.0
co2_warning_ppm = 1000.0
co2_critical_ppm = 2000.0
pm25_warning_ug_m3 = 25.0
pm25_critical_ug_m3 = 50.0
voc_warning_index = 150.0
voc_critical_index = 250.0
'@

$files["packages/009_environment_hub/resources/default_environment_hub_configuration.tres"] = @'
[gd_resource type="Resource" script_class="EnvironmentHubConfiguration" load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/009_environment_hub/resources/environment_hub_configuration.gd" id="1"]
[ext_resource type="Resource" path="res://packages/009_environment_hub/resources/default_environment_thresholds.tres" id="2"]

[resource]
script = ExtResource("1")
refresh_interval_seconds = 3.0
automatic_refresh_enabled = true
temperature_decimals = 1
humidity_decimals = 0
air_quality_decimals = 0
show_inactive_zones = true
thresholds = ExtResource("2")
'@

$files["packages/009_environment_hub/scripts/domain/environment_metric_type.gd"] = @'
class_name EnvironmentMetricType
extends RefCounted
## Defines normalized environmental metric identifiers.


#region Values

enum Value {
	TEMPERATURE,
	HUMIDITY,
	CO2,
	PM25,
	PRESSURE,
	ILLUMINANCE,
	NOISE,
	VOC_INDEX,
}

#endregion


#region Public API

## Returns a stable metric identifier.
static func to_string_name(metric: Value) -> StringName:
	match metric:
		Value.TEMPERATURE:
			return &"temperature"
		Value.HUMIDITY:
			return &"humidity"
		Value.CO2:
			return &"co2"
		Value.PM25:
			return &"pm25"
		Value.PRESSURE:
			return &"pressure"
		Value.ILLUMINANCE:
			return &"illuminance"
		Value.NOISE:
			return &"noise"
		Value.VOC_INDEX:
			return &"voc_index"
		_:
			return &"unknown"


## Returns the standard display unit.
static func get_unit(metric: Value) -> String:
	match metric:
		Value.TEMPERATURE:
			return "°C"
		Value.HUMIDITY:
			return "%"
		Value.CO2:
			return "ppm"
		Value.PM25:
			return "µg/m³"
		Value.PRESSURE:
			return "hPa"
		Value.ILLUMINANCE:
			return "lx"
		Value.NOISE:
			return "dB"
		Value.VOC_INDEX:
			return "INDEX"
		_:
			return ""

#endregion
'@

$files["packages/009_environment_hub/scripts/domain/environment_alert_level.gd"] = @'
class_name EnvironmentAlertLevel
extends RefCounted
## Defines environmental alert severity.


#region Values

enum Value {
	NORMAL,
	WARNING,
	CRITICAL,
	UNAVAILABLE,
}

#endregion


#region Public API

## Returns a stable alert label.
static func to_label(level: Value) -> String:
	match level:
		Value.NORMAL:
			return "NORMAL"
		Value.WARNING:
			return "WARNING"
		Value.CRITICAL:
			return "CRITICAL"
		Value.UNAVAILABLE:
			return "UNAVAILABLE"
		_:
			return "UNKNOWN"


## Returns the presentation color for an alert level.
static func to_color(level: Value) -> Color:
	match level:
		Value.NORMAL:
			return Color("#55f2a3")
		Value.WARNING:
			return Color("#ffbf47")
		Value.CRITICAL:
			return Color("#ff4f62")
		Value.UNAVAILABLE:
			return Color("#40515b")
		_:
			return Color.WHITE

#endregion
'@

$files["packages/009_environment_hub/scripts/domain/environment_reading.gd"] = @'
class_name EnvironmentReading
extends ValueObject
## Represents one immutable normalized environmental reading.


#region State

var _metric_type: EnvironmentMetricType.Value
var _value: float
var _unit: String
var _measured_at_unix_ms: int
var _source_id: StringName
var _available: bool

#endregion


#region Construction

## Creates a normalized environmental reading.
func _init(
	metric_type: EnvironmentMetricType.Value,
	value: float,
	measured_at_unix_ms: int,
	source_id: StringName,
	available: bool = true
) -> void:
	assert(
		measured_at_unix_ms >= 0,
		"EnvironmentReading timestamp cannot be negative."
	)
	assert(
		not source_id.is_empty(),
		"EnvironmentReading requires source_id."
	)

	_metric_type = metric_type
	_value = value
	_unit = EnvironmentMetricType.get_unit(metric_type)
	_measured_at_unix_ms = measured_at_unix_ms
	_source_id = source_id
	_available = available

#endregion


#region Public API

func get_metric_type() -> EnvironmentMetricType.Value:
	return _metric_type


func get_value() -> float:
	return _value


func get_unit() -> String:
	return _unit


func get_measured_at_unix_ms() -> int:
	return _measured_at_unix_ms


func get_source_id() -> StringName:
	return _source_id


func is_available() -> bool:
	return _available

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_metric_type,
		_value,
		_unit,
		_measured_at_unix_ms,
		_source_id,
		_available,
	]

#endregion
'@

$files["packages/009_environment_hub/scripts/domain/environment_zone.gd"] = @'
class_name EnvironmentZone
extends AggregateRoot
## Owns the normalized environmental state of one physical zone.


#region Events

const EVENT_UPDATED: StringName = \
	&"hydra.environment.zone.updated"
const EVENT_ALERT_CHANGED: StringName = \
	&"hydra.environment.zone.alert_changed"

#endregion


#region State

var _zone_id: StringName
var _display_name: String
var _readings: Dictionary[int, EnvironmentReading] = {}
var _alert_level: EnvironmentAlertLevel.Value = \
	EnvironmentAlertLevel.Value.UNAVAILABLE
var _updated_at_unix_ms: int = 0

#endregion


#region Construction

func _init(
	id: EntityId,
	zone_id: StringName,
	display_name: String
) -> void:
	super(id)

	assert(not zone_id.is_empty(), "EnvironmentZone requires zone_id.")
	assert(
		not display_name.strip_edges().is_empty(),
		"EnvironmentZone requires display_name."
	)

	_zone_id = zone_id
	_display_name = display_name.strip_edges()

#endregion


#region Public API

func get_zone_id() -> StringName:
	return _zone_id


func get_display_name() -> String:
	return _display_name


func get_alert_level() -> EnvironmentAlertLevel.Value:
	return _alert_level


func get_updated_at_unix_ms() -> int:
	return _updated_at_unix_ms


func get_reading(
	metric_type: EnvironmentMetricType.Value
) -> EnvironmentReading:
	return _readings.get(metric_type)


func get_readings() -> Array[EnvironmentReading]:
	var result: Array[EnvironmentReading] = []

	for reading: EnvironmentReading in _readings.values():
		result.append(reading)

	return result


## Replaces current readings and evaluates alert severity.
func update_readings(
	readings: Array[EnvironmentReading],
	thresholds: EnvironmentThresholds
) -> Result:
	if thresholds == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Environment thresholds cannot be null."
			)
		)

	var previous_alert_level := _alert_level
	_readings.clear()

	for reading in readings:
		if reading == null:
			continue

		_readings[reading.get_metric_type()] = reading

	_alert_level = _evaluate_alert_level(thresholds)
	_updated_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_UPDATED,
			{
				&"zone_id": _zone_id,
				&"reading_count": _readings.size(),
				&"alert_level":
					EnvironmentAlertLevel.to_label(
						_alert_level
					),
			}
		)
	)

	if previous_alert_level != _alert_level:
		_record_domain_event(
			DomainEvent.new(
				EVENT_ALERT_CHANGED,
				{
					&"zone_id": _zone_id,
					&"previous_level":
						EnvironmentAlertLevel.to_label(
							previous_alert_level
						),
					&"current_level":
						EnvironmentAlertLevel.to_label(
							_alert_level
						),
				}
			)
		)

	return Result.success()

#endregion


#region Private methods

func _evaluate_alert_level(
	thresholds: EnvironmentThresholds
) -> EnvironmentAlertLevel.Value:
	if _readings.is_empty():
		return EnvironmentAlertLevel.Value.UNAVAILABLE

	var highest_level := EnvironmentAlertLevel.Value.NORMAL

	for reading: EnvironmentReading in _readings.values():
		var level := _evaluate_reading(reading, thresholds)

		if level == EnvironmentAlertLevel.Value.CRITICAL:
			return level

		if level == EnvironmentAlertLevel.Value.WARNING:
			highest_level = level

	return highest_level


func _evaluate_reading(
	reading: EnvironmentReading,
	thresholds: EnvironmentThresholds
) -> EnvironmentAlertLevel.Value:
	if not reading.is_available():
		return EnvironmentAlertLevel.Value.UNAVAILABLE

	var value := reading.get_value()

	match reading.get_metric_type():
		EnvironmentMetricType.Value.TEMPERATURE:
			if (
				value <= thresholds.minimum_temperature_critical_celsius
				or value >= thresholds.maximum_temperature_critical_celsius
			):
				return EnvironmentAlertLevel.Value.CRITICAL

			if (
				value <= thresholds.minimum_temperature_warning_celsius
				or value >= thresholds.maximum_temperature_warning_celsius
			):
				return EnvironmentAlertLevel.Value.WARNING

		EnvironmentMetricType.Value.HUMIDITY:
			if value >= thresholds.maximum_humidity_critical_percent:
				return EnvironmentAlertLevel.Value.CRITICAL

			if (
				value <= thresholds.minimum_humidity_warning_percent
				or value >= thresholds.maximum_humidity_warning_percent
			):
				return EnvironmentAlertLevel.Value.WARNING

		EnvironmentMetricType.Value.CO2:
			if value >= thresholds.co2_critical_ppm:
				return EnvironmentAlertLevel.Value.CRITICAL

			if value >= thresholds.co2_warning_ppm:
				return EnvironmentAlertLevel.Value.WARNING

		EnvironmentMetricType.Value.PM25:
			if value >= thresholds.pm25_critical_ug_m3:
				return EnvironmentAlertLevel.Value.CRITICAL

			if value >= thresholds.pm25_warning_ug_m3:
				return EnvironmentAlertLevel.Value.WARNING

		EnvironmentMetricType.Value.VOC_INDEX:
			if value >= thresholds.voc_critical_index:
				return EnvironmentAlertLevel.Value.CRITICAL

			if value >= thresholds.voc_warning_index:
				return EnvironmentAlertLevel.Value.WARNING

	return EnvironmentAlertLevel.Value.NORMAL

#endregion
'@

$files["packages/009_environment_hub/scripts/contracts/environment_provider_port.gd"] = @'
@abstract
class_name EnvironmentProviderPort
extends RefCounted
## Defines the boundary for retrieving environmental zone snapshots.


#region Public API

## Returns a Result containing an array of zone dictionaries.
@abstract
func fetch_zones() -> Result

#endregion
'@

$files["packages/009_environment_hub/scripts/infrastructure/demo_environment_provider.gd"] = @'
class_name DemoEnvironmentProvider
extends EnvironmentProviderPort
## Provides deterministic local environmental data.


#region EnvironmentProviderPort

func fetch_zones() -> Result:
	var timestamp := int(
		Time.get_unix_time_from_system() * 1000.0
	)

	return Result.success(
		[
			{
				&"zone_id": &"command_room",
				&"display_name": "COMMAND ROOM",
				&"readings": [
					EnvironmentReading.new(
						EnvironmentMetricType.Value.TEMPERATURE,
						22.4,
						timestamp,
						&"demo_temperature_01"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.HUMIDITY,
						44.0,
						timestamp,
						&"demo_humidity_01"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.CO2,
						680.0,
						timestamp,
						&"demo_co2_01"
					),
				],
			},
			{
				&"zone_id": &"server_room",
				&"display_name": "SERVER ROOM",
				&"readings": [
					EnvironmentReading.new(
						EnvironmentMetricType.Value.TEMPERATURE,
						19.8,
						timestamp,
						&"demo_temperature_02"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.HUMIDITY,
						38.0,
						timestamp,
						&"demo_humidity_02"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.CO2,
						1120.0,
						timestamp,
						&"demo_co2_02"
					),
				],
			},
			{
				&"zone_id": &"garage",
				&"display_name": "GARAGE",
				&"readings": [
					EnvironmentReading.new(
						EnvironmentMetricType.Value.TEMPERATURE,
						15.5,
						timestamp,
						&"demo_temperature_03"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.HUMIDITY,
						72.0,
						timestamp,
						&"demo_humidity_03"
					),
					EnvironmentReading.new(
						EnvironmentMetricType.Value.PM25,
						31.0,
						timestamp,
						&"demo_pm25_03"
					),
				],
			},
		]
	)

#endregion
'@

$files["packages/009_environment_hub/scripts/application/environment_hub_service.gd"] = @'
class_name EnvironmentHubService
extends Node
## Coordinates environmental snapshot retrieval and publication.


#region Signals

signal zones_updated(zones: Array[EnvironmentZone])
signal refresh_failed(error: DomainError)
signal critical_environment_detected(zone: EnvironmentZone)

#endregion


#region State

var _configuration: EnvironmentHubConfiguration
var _provider: EnvironmentProviderPort
var _zones: Dictionary[StringName, EnvironmentZone] = {}
var _refresh_timer: Timer

#endregion


#region Lifecycle

func _ready() -> void:
	_refresh_timer = Timer.new()
	_refresh_timer.name = "EnvironmentRefreshTimer"
	_refresh_timer.one_shot = false
	_refresh_timer.timeout.connect(_on_refresh_timeout)
	add_child(_refresh_timer)

#endregion


#region Public API

## Configures Environment Hub.
func configure(
	configuration: EnvironmentHubConfiguration,
	provider: EnvironmentProviderPort
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Environment Hub configuration cannot be null."
			)
		)

	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Environment provider cannot be null."
			)
		)

	if configuration.thresholds == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Environment Hub requires thresholds."
			)
		)

	_configuration = configuration
	_provider = provider
	_refresh_timer.wait_time = configuration.refresh_interval_seconds

	return Result.success()


## Starts automatic refresh.
func start() -> Result:
	if _configuration == null or _provider == null:
		return _not_configured()

	if _configuration.automatic_refresh_enabled:
		_refresh_timer.start()

	return refresh()


## Stops automatic refresh.
func stop() -> void:
	_refresh_timer.stop()


## Refreshes all environmental zones.
func refresh() -> Result:
	if _configuration == null or _provider == null:
		return _not_configured()

	var provider_result := _provider.fetch_zones()

	if provider_result.is_failure():
		refresh_failed.emit(provider_result.get_error())
		return provider_result

	var snapshots: Array = provider_result.get_value()

	for snapshot: Dictionary in snapshots:
		var zone_id: StringName = snapshot.get(&"zone_id", &"")

		if zone_id.is_empty():
			continue

		var zone := _zones.get(zone_id) as EnvironmentZone

		if zone == null:
			zone = EnvironmentZone.new(
				EntityId.from_string(String(zone_id)),
				zone_id,
				snapshot.get(&"display_name", String(zone_id))
			)
			_zones[zone_id] = zone

		var readings: Array[EnvironmentReading] = []

		for reading in snapshot.get(&"readings", []):
			if reading is EnvironmentReading:
				readings.append(reading)

		var update_result := zone.update_readings(
			readings,
			_configuration.thresholds
		)

		if update_result.is_failure():
			refresh_failed.emit(update_result.get_error())
			return update_result

		_publish_zone_events(zone)

		if (
			zone.get_alert_level()
			== EnvironmentAlertLevel.Value.CRITICAL
		):
			critical_environment_detected.emit(zone)

	var zone_list := get_zones()
	zones_updated.emit(zone_list)

	return Result.success(zone_list)


## Returns all zones sorted by display name.
func get_zones() -> Array[EnvironmentZone]:
	var result: Array[EnvironmentZone] = []

	for zone: EnvironmentZone in _zones.values():
		result.append(zone)

	result.sort_custom(
		func(left: EnvironmentZone, right: EnvironmentZone) -> bool:
			return left.get_display_name() < right.get_display_name()
	)

	return result


## Returns a zone by identifier.
func get_zone(zone_id: StringName) -> EnvironmentZone:
	return _zones.get(zone_id)

#endregion


#region Private methods

func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Environment Hub is not configured."
		)
	)


func _publish_zone_events(zone: EnvironmentZone) -> void:
	var events := zone.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _on_refresh_timeout() -> void:
	refresh()

#endregion
'@

$files["packages/009_environment_hub/scripts/presentation/environment_metric_widget.gd"] = @'
class_name EnvironmentMetricWidget
extends WidgetBase
## Displays one normalized environmental reading.


#region Nodes

@onready var _metric_label: RichTextLabel = %MetricLabel
@onready var _value_label: RichTextLabel = %ValueLabel
@onready var _source_label: RichTextLabel = %SourceLabel

#endregion


#region Public API

## Applies an environmental reading.
func apply_reading(
	reading: EnvironmentReading,
	decimals: int = 1
) -> void:
	if reading == null or not is_node_ready():
		return

	var metric_name := String(
		EnvironmentMetricType.to_string_name(
			reading.get_metric_type()
		)
	).to_upper()

	_metric_label.text = metric_name

	if not reading.is_available():
		_value_label.text = "[color=#40515b]N/A[/color]"
	else:
		_value_label.text = (
			"[color=#32d8ff]%.*f %s[/color]"
			% [
				decimals,
				reading.get_value(),
				reading.get_unit(),
			]
		)

	_source_label.text = (
		"SOURCE  //  %s"
		% String(reading.get_source_id()).to_upper()
	)

#endregion
'@

$files["packages/009_environment_hub/scripts/presentation/environment_zone_widget.gd"] = @'
class_name EnvironmentZoneWidget
extends WidgetBase
## Displays one environmental zone and its key readings.


#region Nodes

@onready var _zone_name: RichTextLabel = %ZoneName
@onready var _alert_label: RichTextLabel = %AlertLabel
@onready var _alert_indicator: ColorRect = %AlertIndicator
@onready var _temperature: RichTextLabel = %Temperature
@onready var _humidity: RichTextLabel = %Humidity
@onready var _air_quality: RichTextLabel = %AirQuality

#endregion


#region Public API

## Applies a zone snapshot.
func apply_zone(zone: EnvironmentZone) -> void:
	if zone == null or not is_node_ready():
		return

	var alert_level := zone.get_alert_level()

	_zone_name.text = zone.get_display_name()
	_alert_label.text = EnvironmentAlertLevel.to_label(alert_level)
	_alert_indicator.color = EnvironmentAlertLevel.to_color(
		alert_level
	)

	_temperature.text = _format_reading(
		zone.get_reading(
			EnvironmentMetricType.Value.TEMPERATURE
		),
		1
	)
	_humidity.text = _format_reading(
		zone.get_reading(
			EnvironmentMetricType.Value.HUMIDITY
		),
		0
	)

	var air_reading := zone.get_reading(
		EnvironmentMetricType.Value.CO2
	)

	if air_reading == null:
		air_reading = zone.get_reading(
			EnvironmentMetricType.Value.PM25
		)

	_air_quality.text = _format_reading(air_reading, 0)

#endregion


#region Private methods

func _format_reading(
	reading: EnvironmentReading,
	decimals: int
) -> String:
	if reading == null or not reading.is_available():
		return "N/A"

	return "%.*f %s" % [
		decimals,
		reading.get_value(),
		reading.get_unit(),
	]

#endregion
'@

$files["packages/009_environment_hub/scripts/presentation/environment_hub_panel.gd"] = @'
class_name EnvironmentHubPanel
extends PanelBase
## Main environmental monitoring panel.


#region Constants

const ZONE_WIDGET_WIDTH: float = 382.0
const ZONE_WIDGET_HEIGHT: float = 188.0
const ZONE_COLUMN_GAP: float = 24.0
const ZONE_ROW_GAP: float = 20.0
const ZONE_START_X: float = 56.0
const ZONE_START_Y: float = 176.0
const ZONE_COLUMNS: int = 2

#endregion


#region Nodes

@onready var _zone_layer: Control = %ZoneLayer
@onready var _summary_label: RichTextLabel = %SummaryLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: EnvironmentHubService
var _zone_scene: PackedScene = preload(
	"res://packages/009_environment_hub/scenes/environment_zone_widget.tscn"
)

#endregion


#region Public API

## Binds the panel to Environment Hub.
func bind_service(service: EnvironmentHubService) -> void:
	assert(service != null, "Environment Hub service cannot be null.")

	_disconnect_service()
	_service = service

	_service.zones_updated.connect(_on_zones_updated)
	_service.refresh_failed.connect(_on_refresh_failed)
	_service.critical_environment_detected.connect(
		_on_critical_environment_detected
	)


## Requests an immediate refresh.
func refresh() -> Result:
	if _service == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Environment Hub panel is not bound."
			)
		)

	return _service.refresh()

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.zones_updated.is_connected(_on_zones_updated):
		_service.zones_updated.disconnect(_on_zones_updated)

	if _service.refresh_failed.is_connected(_on_refresh_failed):
		_service.refresh_failed.disconnect(_on_refresh_failed)

	if _service.critical_environment_detected.is_connected(
		_on_critical_environment_detected
	):
		_service.critical_environment_detected.disconnect(
			_on_critical_environment_detected
		)


func _on_zones_updated(
	zones: Array[EnvironmentZone]
) -> void:
	_error_label.visible = false

	var warning_count := 0
	var critical_count := 0

	for zone in zones:
		match zone.get_alert_level():
			EnvironmentAlertLevel.Value.WARNING:
				warning_count += 1
			EnvironmentAlertLevel.Value.CRITICAL:
				critical_count += 1

	_summary_label.text = (
		"ZONES  //  %d    WARNINGS  //  %d    CRITICAL  //  %d"
		% [
			zones.size(),
			warning_count,
			critical_count,
		]
	)

	_render_zones(zones)


func _on_refresh_failed(error: DomainError) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]ENVIRONMENT HUB ERROR[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()


func _on_critical_environment_detected(
	zone: EnvironmentZone
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]CRITICAL ENVIRONMENT[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % zone.get_display_name()


func _render_zones(
	zones: Array[EnvironmentZone]
) -> void:
	for child in _zone_layer.get_children():
		child.queue_free()

	for index in zones.size():
		var widget := (
			_zone_scene.instantiate()
			as EnvironmentZoneWidget
		)
		var column := index % ZONE_COLUMNS
		var row := index / ZONE_COLUMNS

		widget.position = Vector2(
			ZONE_START_X + (
				column * (
					ZONE_WIDGET_WIDTH + ZONE_COLUMN_GAP
				)
			),
			ZONE_START_Y + (
				row * (
					ZONE_WIDGET_HEIGHT + ZONE_ROW_GAP
				)
			)
		)
		widget.size = Vector2(
			ZONE_WIDGET_WIDTH,
			ZONE_WIDGET_HEIGHT
		)

		_zone_layer.add_child(widget)
		widget.apply_zone(zones[index])

#endregion
'@

$files["packages/009_environment_hub/scenes/environment_metric_widget.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/009_environment_hub/scripts/presentation/environment_metric_widget.gd" id="1"]

[node name="EnvironmentMetricWidget" type="Control"]
custom_minimum_size = Vector2(240, 110)
layout_mode = 3
anchors_preset = 0
offset_right = 240.0
offset_bottom = 110.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"environment_metric_widget"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.86)

[node name="MetricLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 16.0
offset_top = 12.0
offset_right = 224.0
offset_bottom = 38.0
text = "METRIC"
fit_content = true
scroll_active = false

[node name="ValueLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 16.0
offset_top = 42.0
offset_right = 224.0
offset_bottom = 76.0
bbcode_enabled = true
text = "[color=#32d8ff]0.0[/color]"
fit_content = true
scroll_active = false

[node name="SourceLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 16.0
offset_top = 80.0
offset_right = 224.0
offset_bottom = 104.0
text = "SOURCE  //  UNKNOWN"
fit_content = true
scroll_active = false
'@

$files["packages/009_environment_hub/scenes/environment_zone_widget.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/009_environment_hub/scripts/presentation/environment_zone_widget.gd" id="1"]

[node name="EnvironmentZoneWidget" type="Control"]
custom_minimum_size = Vector2(382, 188)
layout_mode = 3
anchors_preset = 0
offset_right = 382.0
offset_bottom = 188.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"environment_zone_widget"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.9)

[node name="AlertIndicator" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 14.0
offset_top = 14.0
offset_right = 20.0
offset_bottom = 174.0
mouse_filter = 2
color = Color(0.333333, 0.94902, 0.639216, 1)

[node name="ZoneName" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 38.0
offset_top = 14.0
offset_right = 250.0
offset_bottom = 44.0
bbcode_enabled = true
text = "[color=#32d8ff]ZONE[/color]"
fit_content = true
scroll_active = false

[node name="AlertLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 262.0
offset_top = 14.0
offset_right = 364.0
offset_bottom = 44.0
text = "NORMAL"
fit_content = true
scroll_active = false

[node name="TemperatureTitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 38.0
offset_top = 62.0
offset_right = 150.0
offset_bottom = 88.0
text = "TEMP"
fit_content = true
scroll_active = false

[node name="Temperature" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 38.0
offset_top = 92.0
offset_right = 150.0
offset_bottom = 126.0
bbcode_enabled = true
text = "[color=#32d8ff]N/A[/color]"
fit_content = true
scroll_active = false

[node name="HumidityTitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 154.0
offset_top = 62.0
offset_right = 252.0
offset_bottom = 88.0
text = "HUMIDITY"
fit_content = true
scroll_active = false

[node name="Humidity" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 154.0
offset_top = 92.0
offset_right = 252.0
offset_bottom = 126.0
bbcode_enabled = true
text = "[color=#32d8ff]N/A[/color]"
fit_content = true
scroll_active = false

[node name="AirTitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 258.0
offset_top = 62.0
offset_right = 350.0
offset_bottom = 88.0
text = "AIR"
fit_content = true
scroll_active = false

[node name="AirQuality" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 258.0
offset_top = 92.0
offset_right = 358.0
offset_bottom = 126.0
bbcode_enabled = true
text = "[color=#d6aa48]N/A[/color]"
fit_content = true
scroll_active = false
'@

$files["packages/009_environment_hub/scenes/environment_hub_panel.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/009_environment_hub/scripts/presentation/environment_hub_panel.gd" id="1"]

[node name="EnvironmentHubPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 920.0
offset_bottom = 900.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"environment_hub_panel"
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
offset_right = 680.0
offset_bottom = 60.0
bbcode_enabled = true
text = "[font_size=30][color=#32d8ff]ENVIRONMENT HUB[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 820.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]ATMOSPHERIC MONITORING  //  CHANNEL 009[/color]"
fit_content = true
scroll_active = false

[node name="SummaryLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 114.0
offset_right = 850.0
offset_bottom = 148.0
bbcode_enabled = true
text = "[color=#d6aa48]ZONES  //  0    WARNINGS  //  0    CRITICAL  //  0[/color]"
fit_content = true
scroll_active = false

[node name="ZoneLayer" type="Control" parent="."]
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
offset_right = 866.0
offset_bottom = 884.0
bbcode_enabled = true
text = "[color=#ff4f62]ENVIRONMENT HUB ERROR[/color]"
scroll_active = false
'@

$files["packages/009_environment_hub/demo/environment_hub_demo.gd"] = @'
class_name EnvironmentHubDemo
extends Control
## Demonstrates Environment Hub with deterministic local readings.


#region Nodes

@onready var _panel: EnvironmentHubPanel = %EnvironmentHubPanel

#endregion


#region State

var _service: EnvironmentHubService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = EnvironmentHubService.new()
	_service.name = "EnvironmentHubService"
	add_child(_service)

	var configuration: EnvironmentHubConfiguration = preload(
		"res://packages/009_environment_hub/resources/default_environment_hub_configuration.tres"
	)
	var provider := DemoEnvironmentProvider.new()

	var configuration_result := _service.configure(
		configuration,
		provider
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_panel.bind_service(_service)
	_service.start()

#endregion
'@

$files["packages/009_environment_hub/demo/environment_hub_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/009_environment_hub/demo/environment_hub_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/009_environment_hub/scenes/environment_hub_panel.tscn" id="2"]

[node name="EnvironmentHubDemo" type="Control"]
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

[node name="EnvironmentHubPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 500.0
offset_top = 90.0
offset_right = 1420.0
offset_bottom = 990.0
'@

$files["packages/009_environment_hub/tests/unit/test_environment_reading.gd"] = @'
class_name EnvironmentReadingTest
extends RefCounted
## Provides EnvironmentReading value-object tests.


#region Tests

static func run() -> void:
	var reading := EnvironmentReading.new(
		EnvironmentMetricType.Value.TEMPERATURE,
		22.5,
		1000,
		&"sensor_01"
	)

	assert(
		reading.get_metric_type()
		== EnvironmentMetricType.Value.TEMPERATURE
	)
	assert(is_equal_approx(reading.get_value(), 22.5))
	assert(reading.get_unit() == "°C")
	assert(reading.get_source_id() == &"sensor_01")
	assert(reading.is_available())

#endregion
'@

$files["packages/009_environment_hub/tests/unit/test_environment_zone.gd"] = @'
class_name EnvironmentZoneTest
extends RefCounted
## Provides EnvironmentZone alert-evaluation tests.


#region Tests

static func run() -> void:
	var zone := EnvironmentZone.new(
		EntityId.generate(),
		&"office",
		"OFFICE"
	)
	var thresholds := EnvironmentThresholds.new()
	var timestamp := 1000

	var normal_readings: Array[EnvironmentReading] = [
		EnvironmentReading.new(
			EnvironmentMetricType.Value.TEMPERATURE,
			22.0,
			timestamp,
			&"temperature"
		),
		EnvironmentReading.new(
			EnvironmentMetricType.Value.CO2,
			700.0,
			timestamp,
			&"co2"
		),
	]

	assert(
		zone.update_readings(
			normal_readings,
			thresholds
		).is_success()
	)
	assert(
		zone.get_alert_level()
		== EnvironmentAlertLevel.Value.NORMAL
	)

	var warning_readings: Array[EnvironmentReading] = [
		EnvironmentReading.new(
			EnvironmentMetricType.Value.CO2,
			1200.0,
			timestamp,
			&"co2"
		),
	]

	assert(
		zone.update_readings(
			warning_readings,
			thresholds
		).is_success()
	)
	assert(
		zone.get_alert_level()
		== EnvironmentAlertLevel.Value.WARNING
	)

#endregion
'@

$files["packages/009_environment_hub/tests/integration/test_environment_hub_service.gd"] = @'
class_name EnvironmentHubServiceTest
extends RefCounted
## Provides Environment Hub service composition tests.


#region Tests

static func run() -> void:
	var service := EnvironmentHubService.new()
	var configuration := EnvironmentHubConfiguration.new()
	configuration.thresholds = EnvironmentThresholds.new()
	var provider := DemoEnvironmentProvider.new()

	var result := service.configure(
		configuration,
		provider
	)

	assert(result.is_success())

#endregion
'@

$files["autoload/environment_hub.gd"] = @'
extends EnvironmentHubService
## Global Environment Hub application service.
##
## Runtime composition must configure the provider before startup.
'@

$files["docs/package-dependencies-009.md"] = @'
# Package dependency 009

```text
009_environment_hub
├── 001_foundation
├── 002_design_system
├── 003_widget_library
└── 004_animation_system
'@

Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing Package 009 - Environment Hub..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

Write-Host ""
Write-Host "Package 009 installed." -ForegroundColor Green
Write-Host ""
Write-Host "Optional autoload:" -ForegroundColor Cyan
Write-Host "EnvironmentHub res://autoload/environment_hub.gd"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(environment-hub): implement package 009"'
Write-Host "git push"