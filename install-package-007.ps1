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

function Assert-PowerShellSyntax {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    $tokens = $null
    $errors = $null

    [System.Management.Automation.Language.Parser]::ParseFile(
        $ScriptPath,
        [ref]$tokens,
        [ref]$errors
    ) | Out-Null

    if ($errors.Count -gt 0) {
        $messages = $errors |
            ForEach-Object {
                "Line $($_.Extent.StartLineNumber): $($_.Message)"
            }

        throw "Błąd składni instalatora:`n$($messages -join "`n")"
    }
}

Assert-HydraRepository
Assert-PowerShellSyntax -ScriptPath $PSCommandPath

$files = [ordered]@{}

$files["packages/007_home_hub/package.cfg"] = @'
[package]

id="007_home_hub"
name="Home Hub"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system"
)
'@

$files["packages/007_home_hub/README.md"] = @'
# Package 007 — Home Hub

Home Hub provides the main residential overview for HYDRA AI HOME OS.

It aggregates home zones, occupancy, security state, energy summaries and
high-level environmental information without owning device-specific protocols.

## Responsibilities

Home Hub owns the home overview domain model, room summaries, operational status
and the primary home dashboard panel.

## Dependencies

Home Hub depends on Foundation, Design System, Widget Library and Animation
System.
'@

$files["packages/007_home_hub/CHANGELOG.md"] = @'
# Home Hub changelog

## [0.1.0] - 2026-07-17

### Added

- Added home overview domain model.
- Added room summary value object.
- Added home operational state.
- Added Home Hub application service.
- Added home summary and room widgets.
- Added Home Hub panel.
- Added demo scene and tests.
'@

$files["packages/007_home_hub/docs/architecture.md"] = @'
# Home Hub architecture

Home Hub is an aggregation boundary.

It consumes summarized state from other packages through ports and events.
It does not directly communicate with physical devices.

Device communication belongs to Package 010.
Environmental sensor processing belongs to Package 009.
Automation execution belongs to Package 012.
'@

$files["packages/007_home_hub/docs/domain-model.md"] = @'
# Home Hub domain model

The home overview contains:

- A stable home identifier.
- A human-readable display name.
- An operational state.
- Occupancy information.
- Security information.
- Energy summary.
- Room summaries.

Room summaries are immutable snapshots intended for presentation and application
queries.
'@

$files["packages/007_home_hub/resources/home_hub_configuration.gd"] = @'
class_name HomeHubConfiguration
extends Resource
## Stores runtime configuration for Home Hub.


#region Identity

@export_group("Identity")
@export var home_id: StringName = &"primary_home"
@export var display_name: String = "HYDRA RESIDENCE"

#endregion


#region Refresh

@export_group("Refresh")
@export_range(0.25, 60.0, 0.25) var refresh_interval_seconds: float = 2.0
@export var refresh_while_hidden: bool = false

#endregion


#region Presentation

@export_group("Presentation")
@export var show_occupancy: bool = true
@export var show_security: bool = true
@export var show_energy: bool = true
@export var show_room_status: bool = true

#endregion
'@

$files["packages/007_home_hub/resources/default_home_hub_configuration.tres"] = @'
[gd_resource type="Resource" script_class="HomeHubConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/007_home_hub/resources/home_hub_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
home_id = &"primary_home"
display_name = "HYDRA RESIDENCE"
refresh_interval_seconds = 2.0
refresh_while_hidden = false
show_occupancy = true
show_security = true
show_energy = true
show_room_status = true
'@

$files["packages/007_home_hub/scripts/domain/home_operational_state.gd"] = @'
class_name HomeOperationalState
extends RefCounted
## Defines stable operational states for a managed home.


#region Values

enum Value {
	UNKNOWN,
	OFFLINE,
	DEGRADED,
	NORMAL,
	ALERT,
	EMERGENCY,
}

#endregion


#region Public API

## Returns a stable lowercase identifier for the supplied state.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.OFFLINE:
			return &"offline"
		Value.DEGRADED:
			return &"degraded"
		Value.NORMAL:
			return &"normal"
		Value.ALERT:
			return &"alert"
		Value.EMERGENCY:
			return &"emergency"
		_:
			return &"unknown"


## Returns the presentation color for the supplied state.
static func to_color(state: Value) -> Color:
	match state:
		Value.OFFLINE:
			return Color("#40515b")
		Value.DEGRADED:
			return Color("#ffbf47")
		Value.NORMAL:
			return Color("#55f2a3")
		Value.ALERT:
			return Color("#ff8b3d")
		Value.EMERGENCY:
			return Color("#ff4f62")
		_:
			return Color("#6e8794")

#endregion
'@

$files["packages/007_home_hub/scripts/domain/security_state.gd"] = @'
class_name SecurityState
extends RefCounted
## Defines stable residential security states.


#region Values

enum Value {
	UNKNOWN,
	DISARMED,
	ARMED_HOME,
	ARMED_AWAY,
	ALARM,
}

#endregion


#region Public API

## Returns a stable display label for the supplied state.
static func to_label(state: Value) -> String:
	match state:
		Value.DISARMED:
			return "DISARMED"
		Value.ARMED_HOME:
			return "ARMED HOME"
		Value.ARMED_AWAY:
			return "ARMED AWAY"
		Value.ALARM:
			return "ALARM"
		_:
			return "UNKNOWN"

#endregion
'@

$files["packages/007_home_hub/scripts/domain/room_summary.gd"] = @'
class_name RoomSummary
extends ValueObject
## Represents an immutable room overview snapshot.


#region State

var _room_id: StringName
var _display_name: String
var _occupied: bool
var _temperature_celsius: float
var _active_device_count: int
var _alert_count: int

#endregion


#region Construction

## Creates a room summary snapshot.
func _init(
	room_id: StringName,
	display_name: String,
	occupied: bool,
	temperature_celsius: float,
	active_device_count: int,
	alert_count: int
) -> void:
	assert(not room_id.is_empty(), "RoomSummary requires room_id.")
	assert(
		not display_name.strip_edges().is_empty(),
		"RoomSummary requires display_name."
	)
	assert(
		active_device_count >= 0,
		"RoomSummary active_device_count cannot be negative."
	)
	assert(
		alert_count >= 0,
		"RoomSummary alert_count cannot be negative."
	)

	_room_id = room_id
	_display_name = display_name.strip_edges()
	_occupied = occupied
	_temperature_celsius = temperature_celsius
	_active_device_count = active_device_count
	_alert_count = alert_count

#endregion


#region Public API

func get_room_id() -> StringName:
	return _room_id


func get_display_name() -> String:
	return _display_name


func is_occupied() -> bool:
	return _occupied


func get_temperature_celsius() -> float:
	return _temperature_celsius


func get_active_device_count() -> int:
	return _active_device_count


func get_alert_count() -> int:
	return _alert_count

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_room_id,
		_display_name,
		_occupied,
		_temperature_celsius,
		_active_device_count,
		_alert_count,
	]

#endregion
'@

$files["packages/007_home_hub/scripts/domain/home_overview.gd"] = @'
class_name HomeOverview
extends AggregateRoot
## Represents the aggregated operational state of a managed home.


#region Events

const EVENT_UPDATED: StringName = &"hydra.home.overview.updated"
const EVENT_STATE_CHANGED: StringName = &"hydra.home.state.changed"
const EVENT_SECURITY_CHANGED: StringName = &"hydra.home.security.changed"

#endregion


#region State

var _display_name: String
var _operational_state: HomeOperationalState.Value = \
	HomeOperationalState.Value.UNKNOWN
var _security_state: SecurityState.Value = SecurityState.Value.UNKNOWN
var _occupant_count: int = 0
var _current_power_watts: float = 0.0
var _room_summaries: Array[RoomSummary] = []
var _updated_at_unix_ms: int = 0

#endregion


#region Construction

## Creates a home overview aggregate.
func _init(
	id: EntityId,
	display_name: String
) -> void:
	super(id)

	assert(
		not display_name.strip_edges().is_empty(),
		"HomeOverview requires display_name."
	)

	_display_name = display_name.strip_edges()

#endregion


#region Public API

func get_display_name() -> String:
	return _display_name


func get_operational_state() -> HomeOperationalState.Value:
	return _operational_state


func get_security_state() -> SecurityState.Value:
	return _security_state


func get_occupant_count() -> int:
	return _occupant_count


func get_current_power_watts() -> float:
	return _current_power_watts


func get_updated_at_unix_ms() -> int:
	return _updated_at_unix_ms


func get_room_summaries() -> Array[RoomSummary]:
	return _room_summaries.duplicate()


## Updates the aggregated home snapshot.
func update_snapshot(
	operational_state: HomeOperationalState.Value,
	security_state: SecurityState.Value,
	occupant_count: int,
	current_power_watts: float,
	room_summaries: Array[RoomSummary]
) -> Result:
	if occupant_count < 0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Home occupant count cannot be negative."
			)
		)

	if current_power_watts < 0.0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Home power consumption cannot be negative."
			)
		)

	var previous_operational_state := _operational_state
	var previous_security_state := _security_state

	_operational_state = operational_state
	_security_state = security_state
	_occupant_count = occupant_count
	_current_power_watts = current_power_watts
	_room_summaries = room_summaries.duplicate()
	_updated_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)

	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_UPDATED,
			{
				&"home_id": get_id().as_string(),
				&"operational_state":
					HomeOperationalState.to_string_name(
						_operational_state
					),
				&"security_state":
					SecurityState.to_label(_security_state),
				&"occupant_count": _occupant_count,
				&"current_power_watts": _current_power_watts,
				&"room_count": _room_summaries.size(),
			}
		)
	)

	if previous_operational_state != _operational_state:
		_record_domain_event(
			DomainEvent.new(
				EVENT_STATE_CHANGED,
				{
					&"home_id": get_id().as_string(),
					&"previous_state":
						HomeOperationalState.to_string_name(
							previous_operational_state
						),
					&"current_state":
						HomeOperationalState.to_string_name(
							_operational_state
						),
				}
			)
		)

	if previous_security_state != _security_state:
		_record_domain_event(
			DomainEvent.new(
				EVENT_SECURITY_CHANGED,
				{
					&"home_id": get_id().as_string(),
					&"previous_state":
						SecurityState.to_label(
							previous_security_state
						),
					&"current_state":
						SecurityState.to_label(
							_security_state
						),
				}
			)
		)

	return Result.success()

#endregion
'@

$files["packages/007_home_hub/scripts/contracts/home_overview_provider_port.gd"] = @'
@abstract
class_name HomeOverviewProviderPort
extends RefCounted
## Defines the boundary for retrieving aggregated home state.


#region Public API

## Returns a Result containing a dictionary snapshot.
@abstract
func fetch_overview(home_id: StringName) -> Result

#endregion
'@

$files["packages/007_home_hub/scripts/infrastructure/demo_home_overview_provider.gd"] = @'
class_name DemoHomeOverviewProvider
extends HomeOverviewProviderPort
## Provides deterministic local data for demos and development.


#region HomeOverviewProviderPort

func fetch_overview(_home_id: StringName) -> Result:
	var rooms: Array[RoomSummary] = [
		RoomSummary.new(
			&"command_room",
			"COMMAND ROOM",
			true,
			22.4,
			6,
			0
		),
		RoomSummary.new(
			&"living_room",
			"LIVING ROOM",
			true,
			21.8,
			4,
			0
		),
		RoomSummary.new(
			&"server_room",
			"SERVER ROOM",
			false,
			19.6,
			11,
			1
		),
		RoomSummary.new(
			&"garage",
			"GARAGE",
			false,
			16.2,
			2,
			0
		),
	]

	return Result.success(
		{
			&"operational_state":
				HomeOperationalState.Value.NORMAL,
			&"security_state":
				SecurityState.Value.ARMED_HOME,
			&"occupant_count": 2,
			&"current_power_watts": 1840.0,
			&"rooms": rooms,
		}
	)

#endregion
'@

$files["packages/007_home_hub/scripts/application/home_hub_service.gd"] = @'
class_name HomeHubService
extends Node
## Coordinates retrieval and publication of home overview state.


#region Signals

signal overview_updated(overview: HomeOverview)
signal refresh_failed(error: DomainError)

#endregion


#region State

var _configuration: HomeHubConfiguration
var _provider: HomeOverviewProviderPort
var _overview: HomeOverview
var _refresh_timer: Timer

#endregion


#region Lifecycle

func _ready() -> void:
	_refresh_timer = Timer.new()
	_refresh_timer.name = "HomeHubRefreshTimer"
	_refresh_timer.one_shot = false
	_refresh_timer.timeout.connect(_on_refresh_timeout)
	add_child(_refresh_timer)

#endregion


#region Public API

## Configures Home Hub.
func configure(
	configuration: HomeHubConfiguration,
	provider: HomeOverviewProviderPort
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Home Hub configuration cannot be null."
			)
		)

	if provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Home overview provider cannot be null."
			)
		)

	if configuration.home_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Home Hub configuration requires home_id."
			)
		)

	_configuration = configuration
	_provider = provider
	_overview = HomeOverview.new(
		EntityId.from_string(String(configuration.home_id)),
		configuration.display_name
	)

	_refresh_timer.wait_time = configuration.refresh_interval_seconds

	return Result.success()


## Starts automatic overview refresh.
func start() -> Result:
	if _configuration == null or _provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Home Hub is not configured."
			)
		)

	_refresh_timer.start()

	return refresh()


## Stops automatic overview refresh.
func stop() -> void:
	_refresh_timer.stop()


## Refreshes the current home overview.
func refresh() -> Result:
	if _configuration == null or _provider == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Home Hub is not configured."
			)
		)

	var provider_result := _provider.fetch_overview(
		_configuration.home_id
	)

	if provider_result.is_failure():
		refresh_failed.emit(provider_result.get_error())
		return provider_result

	var snapshot: Dictionary = provider_result.get_value()

	var update_result := _overview.update_snapshot(
		snapshot.get(
			&"operational_state",
			HomeOperationalState.Value.UNKNOWN
		),
		snapshot.get(
			&"security_state",
			SecurityState.Value.UNKNOWN
		),
		snapshot.get(&"occupant_count", 0),
		snapshot.get(&"current_power_watts", 0.0),
		snapshot.get(&"rooms", [])
	)

	if update_result.is_failure():
		refresh_failed.emit(update_result.get_error())
		return update_result

	_publish_domain_events()
	overview_updated.emit(_overview)

	return Result.success(_overview)


## Returns the current overview.
func get_overview() -> HomeOverview:
	return _overview

#endregion


#region Private methods

func _publish_domain_events() -> void:
	if _overview == null:
		return

	var events := _overview.pull_domain_events()

	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _on_refresh_timeout() -> void:
	refresh()

#endregion
'@

$files["packages/007_home_hub/scripts/presentation/home_summary_widget.gd"] = @'
class_name HomeSummaryWidget
extends WidgetBase
## Displays high-level home operational metrics.


#region Nodes

@onready var _home_name: RichTextLabel = %HomeName
@onready var _operational_state: RichTextLabel = %OperationalState
@onready var _security_state: RichTextLabel = %SecurityState
@onready var _occupancy_value: RichTextLabel = %OccupancyValue
@onready var _power_value: RichTextLabel = %PowerValue
@onready var _state_indicator: ColorRect = %StateIndicator

#endregion


#region Public API

## Applies a home overview snapshot.
func apply_overview(overview: HomeOverview) -> void:
	if overview == null or not is_node_ready():
		return

	var state := overview.get_operational_state()

	_home_name.text = overview.get_display_name()
	_operational_state.text = (
		"STATUS  //  %s"
		% String(
			HomeOperationalState.to_string_name(state)
		).to_upper()
	)
	_security_state.text = (
		"SECURITY  //  %s"
		% SecurityState.to_label(
			overview.get_security_state()
		)
	)
	_occupancy_value.text = str(
		overview.get_occupant_count()
	)
	_power_value.text = "%0.2f kW" % (
		overview.get_current_power_watts() / 1000.0
	)
	_state_indicator.color = HomeOperationalState.to_color(state)

#endregion
'@

$files["packages/007_home_hub/scripts/presentation/room_summary_widget.gd"] = @'
class_name RoomSummaryWidget
extends WidgetBase
## Displays one immutable room summary.


#region Nodes

@onready var _room_name: RichTextLabel = %RoomName
@onready var _occupancy: RichTextLabel = %Occupancy
@onready var _temperature: RichTextLabel = %Temperature
@onready var _device_count: RichTextLabel = %DeviceCount
@onready var _alert_indicator: ColorRect = %AlertIndicator

#endregion


#region Public API

## Applies a room summary snapshot.
func apply_summary(summary: RoomSummary) -> void:
	if summary == null or not is_node_ready():
		return

	_room_name.text = summary.get_display_name()
	_occupancy.text = (
		"OCCUPIED"
		if summary.is_occupied()
		else "VACANT"
	)
	_temperature.text = "%0.1f °C" % (
		summary.get_temperature_celsius()
	)
	_device_count.text = (
		"%d ACTIVE DEVICES"
		% summary.get_active_device_count()
	)
	_alert_indicator.visible = summary.get_alert_count() > 0

#endregion
'@

$files["packages/007_home_hub/scripts/presentation/home_hub_panel.gd"] = @'
class_name HomeHubPanel
extends PanelBase
## Main residential overview panel.


#region Constants

const ROOM_WIDGET_WIDTH: float = 360.0
const ROOM_WIDGET_HEIGHT: float = 148.0
const ROOM_COLUMN_GAP: float = 24.0
const ROOM_ROW_GAP: float = 20.0
const ROOM_START_X: float = 56.0
const ROOM_START_Y: float = 330.0
const ROOM_COLUMN_COUNT: int = 2

#endregion


#region Nodes

@onready var _summary_widget: HomeSummaryWidget = %HomeSummaryWidget
@onready var _rooms_layer: Control = %RoomsLayer
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: HomeHubService
var _room_scene: PackedScene = preload(
	"res://packages/007_home_hub/scenes/room_summary_widget.tscn"
)

#endregion


#region Public API

## Binds the panel to Home Hub.
func bind_service(service: HomeHubService) -> void:
	assert(service != null, "Home Hub service cannot be null.")

	_disconnect_service()
	_service = service

	_service.overview_updated.connect(_on_overview_updated)
	_service.refresh_failed.connect(_on_refresh_failed)


## Refreshes the bound service.
func refresh() -> Result:
	if _service == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Home Hub panel is not bound to a service."
			)
		)

	return _service.refresh()

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.overview_updated.is_connected(
		_on_overview_updated
	):
		_service.overview_updated.disconnect(
			_on_overview_updated
		)

	if _service.refresh_failed.is_connected(
		_on_refresh_failed
	):
		_service.refresh_failed.disconnect(
			_on_refresh_failed
		)


func _on_overview_updated(overview: HomeOverview) -> void:
	_error_label.visible = false
	_summary_widget.apply_overview(overview)
	_render_rooms(overview.get_room_summaries())


func _on_refresh_failed(error: DomainError) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]HOME HUB ERROR[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()


func _render_rooms(rooms: Array[RoomSummary]) -> void:
	for child in _rooms_layer.get_children():
		child.queue_free()

	for index in rooms.size():
		var widget := _room_scene.instantiate() as RoomSummaryWidget
		var column := index % ROOM_COLUMN_COUNT
		var row := index / ROOM_COLUMN_COUNT

		widget.position = Vector2(
			ROOM_START_X + (
				column * (ROOM_WIDGET_WIDTH + ROOM_COLUMN_GAP)
			),
			ROOM_START_Y + (
				row * (ROOM_WIDGET_HEIGHT + ROOM_ROW_GAP)
			)
		)
		widget.size = Vector2(
			ROOM_WIDGET_WIDTH,
			ROOM_WIDGET_HEIGHT
		)

		_rooms_layer.add_child(widget)
		widget.apply_summary(rooms[index])

#endregion
'@

$files["packages/007_home_hub/scenes/home_summary_widget.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/007_home_hub/scripts/presentation/home_summary_widget.gd" id="1"]

[node name="HomeSummaryWidget" type="Control"]
custom_minimum_size = Vector2(808, 210)
layout_mode = 3
anchors_preset = 0
offset_right = 808.0
offset_bottom = 210.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"home_summary_widget"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.92)

[node name="StateIndicator" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 20.0
offset_top = 20.0
offset_right = 28.0
offset_bottom = 190.0
mouse_filter = 2
color = Color(0.333333, 0.94902, 0.639216, 1)

[node name="HomeName" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 52.0
offset_top = 20.0
offset_right = 520.0
offset_bottom = 58.0
bbcode_enabled = true
text = "[font_size=24][color=#32d8ff]HYDRA RESIDENCE[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="OperationalState" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 52.0
offset_top = 70.0
offset_right = 400.0
offset_bottom = 102.0
text = "STATUS  //  UNKNOWN"
fit_content = true
scroll_active = false

[node name="SecurityState" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 52.0
offset_top = 112.0
offset_right = 400.0
offset_bottom = 144.0
text = "SECURITY  //  UNKNOWN"
fit_content = true
scroll_active = false

[node name="OccupancyLabel" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 460.0
offset_top = 36.0
offset_right = 610.0
offset_bottom = 68.0
text = "OCCUPANTS"
fit_content = true
scroll_active = false

[node name="OccupancyValue" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 460.0
offset_top = 76.0
offset_right = 610.0
offset_bottom = 134.0
bbcode_enabled = true
text = "[font_size=32][color=#32d8ff]0[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="PowerLabel" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 630.0
offset_top = 36.0
offset_right = 780.0
offset_bottom = 68.0
text = "POWER"
fit_content = true
scroll_active = false

[node name="PowerValue" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 630.0
offset_top = 76.0
offset_right = 790.0
offset_bottom = 134.0
bbcode_enabled = true
text = "[font_size=28][color=#d6aa48]0.00 kW[/color][/font_size]"
fit_content = true
scroll_active = false
'@

$files["packages/007_home_hub/scenes/room_summary_widget.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/007_home_hub/scripts/presentation/room_summary_widget.gd" id="1"]

[node name="RoomSummaryWidget" type="Control"]
custom_minimum_size = Vector2(360, 148)
layout_mode = 3
anchors_preset = 0
offset_right = 360.0
offset_bottom = 148.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"room_summary_widget"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.82)

[node name="Accent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 14.0
offset_top = 16.0
offset_right = 18.0
offset_bottom = 132.0
mouse_filter = 2
color = Color(0.196078, 0.847059, 1, 1)

[node name="RoomName" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 14.0
offset_right = 300.0
offset_bottom = 44.0
bbcode_enabled = true
text = "[color=#32d8ff]ROOM[/color]"
fit_content = true
scroll_active = false

[node name="Occupancy" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 54.0
offset_right = 166.0
offset_bottom = 82.0
text = "VACANT"
fit_content = true
scroll_active = false

[node name="Temperature" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 210.0
offset_top = 50.0
offset_right = 336.0
offset_bottom = 84.0
bbcode_enabled = true
text = "[color=#d6aa48]0.0 °C[/color]"
fit_content = true
scroll_active = false

[node name="DeviceCount" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 98.0
offset_right = 300.0
offset_bottom = 128.0
text = "0 ACTIVE DEVICES"
fit_content = true
scroll_active = false

[node name="AlertIndicator" type="ColorRect" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 326.0
offset_top = 16.0
offset_right = 342.0
offset_bottom = 32.0
mouse_filter = 2
color = Color(1, 0.309804, 0.384314, 1)
'@

$files["packages/007_home_hub/scenes/home_hub_panel.tscn"] = @'
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://packages/007_home_hub/scripts/presentation/home_hub_panel.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/007_home_hub/scenes/home_summary_widget.tscn" id="2"]

[node name="HomeHubPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 920.0
offset_bottom = 900.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"home_hub_panel"
starts_open = true

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.0117647, 0.0313725, 0.0509804, 0.96)

[node name="HeaderAccent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 28.0
offset_top = 26.0
offset_right = 34.0
offset_bottom = 92.0
mouse_filter = 2
color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 22.0
offset_right = 640.0
offset_bottom = 62.0
bbcode_enabled = true
text = "[font_size=28][color=#32d8ff]HOME HUB[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 64.0
offset_right = 720.0
offset_bottom = 94.0
bbcode_enabled = true
text = "[color=#6e8794]RESIDENTIAL COMMAND OVERVIEW  //  CHANNEL 007[/color]"
fit_content = true
scroll_active = false

[node name="HomeSummaryWidget" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 56.0
offset_top = 104.0
offset_right = 864.0
offset_bottom = 314.0

[node name="RoomsTitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 56.0
offset_top = 326.0
offset_right = 420.0
offset_bottom = 360.0
bbcode_enabled = true
text = "[color=#d6aa48]ZONE STATUS MATRIX[/color]"
fit_content = true
scroll_active = false

[node name="RoomsLayer" type="Control" parent="."]
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
offset_left = 56.0
offset_top = 812.0
offset_right = 864.0
offset_bottom = 876.0
bbcode_enabled = true
text = "[color=#ff4f62]HOME HUB ERROR[/color]"
scroll_active = false
'@

$files["packages/007_home_hub/demo/home_hub_demo.gd"] = @'
class_name HomeHubDemo
extends Control
## Demonstrates Home Hub with a deterministic local provider.


#region Nodes

@onready var _panel: HomeHubPanel = %HomeHubPanel

#endregion


#region State

var _service: HomeHubService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = HomeHubService.new()
	_service.name = "HomeHubService"
	add_child(_service)

	var configuration := HomeHubConfiguration.new()
	var provider := DemoHomeOverviewProvider.new()

	var result := _service.configure(
		configuration,
		provider
	)

	if result.is_failure():
		push_error(result.get_error().get_message())
		return

	_panel.bind_service(_service)
	_service.start()

#endregion
'@

$files["packages/007_home_hub/demo/home_hub_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/007_home_hub/demo/home_hub_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/007_home_hub/scenes/home_hub_panel.tscn" id="2"]

[node name="HomeHubDemo" type="Control"]
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

[node name="HomeHubPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 500.0
offset_top = 90.0
offset_right = 1420.0
offset_bottom = 990.0
'@

$files["packages/007_home_hub/tests/unit/test_room_summary.gd"] = @'
class_name RoomSummaryTest
extends RefCounted
## Provides executable RoomSummary tests.


#region Tests

static func run() -> void:
	var summary := RoomSummary.new(
		&"office",
		"OFFICE",
		true,
		22.5,
		5,
		1
	)

	assert(summary.get_room_id() == &"office")
	assert(summary.get_display_name() == "OFFICE")
	assert(summary.is_occupied())
	assert(
		is_equal_approx(
			summary.get_temperature_celsius(),
			22.5
		)
	)
	assert(summary.get_active_device_count() == 5)
	assert(summary.get_alert_count() == 1)

#endregion
'@

$files["packages/007_home_hub/tests/unit/test_home_overview.gd"] = @'
class_name HomeOverviewTest
extends RefCounted
## Provides executable HomeOverview tests.


#region Tests

static func run() -> void:
	var overview := HomeOverview.new(
		EntityId.generate(),
		"TEST HOME"
	)

	var rooms: Array[RoomSummary] = [
		RoomSummary.new(
			&"office",
			"OFFICE",
			true,
			22.0,
			3,
			0
		),
	]

	var result := overview.update_snapshot(
		HomeOperationalState.Value.NORMAL,
		SecurityState.Value.ARMED_HOME,
		1,
		1500.0,
		rooms
	)

	assert(result.is_success())
	assert(
		overview.get_operational_state()
		== HomeOperationalState.Value.NORMAL
	)
	assert(
		overview.get_security_state()
		== SecurityState.Value.ARMED_HOME
	)
	assert(overview.get_occupant_count() == 1)
	assert(
		is_equal_approx(
			overview.get_current_power_watts(),
			1500.0
		)
	)
	assert(overview.get_room_summaries().size() == 1)
	assert(not overview.pull_domain_events().is_empty())

#endregion
'@

$files["packages/007_home_hub/tests/integration/test_home_hub_service.gd"] = @'
class_name HomeHubServiceTest
extends RefCounted
## Provides Home Hub service composition tests.


#region Tests

static func run() -> void:
	var service := HomeHubService.new()
	var configuration := HomeHubConfiguration.new()
	var provider := DemoHomeOverviewProvider.new()

	var result := service.configure(
		configuration,
		provider
	)

	assert(result.is_success())
	assert(service.get_overview() != null)

#endregion
'@

$files["autoload/home_hub.gd"] = @'
extends HomeHubService
## Global Home Hub application service.
##
## Runtime composition must call configure() before Home Hub is started.
'@

$files["docs/package-dependencies-007.md"] = @'
# Package dependency 007

```text
007_home_hub
├── 001_foundation
├── 002_design_system
├── 003_widget_library
└── 004_animation_system
'@

Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing Package 007 - Home Hub..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
    Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

Write-Host ""
Write-Host "Package 007 installed." -ForegroundColor Green
Write-Host ""
Write-Host "Optional autoload:" -ForegroundColor Cyan
Write-Host "HomeHub res://autoload/home_hub.gd"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(home-hub): implement package 007"'
Write-Host "git push"