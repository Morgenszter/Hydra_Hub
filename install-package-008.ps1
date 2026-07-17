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

$files["packages/008_central_hub/package.cfg"] = @'
[package]

id="008_central_hub"
name="Central Hub"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system",
	"006_voice_hub",
	"007_home_hub"
)
'@

$files["packages/008_central_hub/README.md"] = @'
# Package 008 — Central Hub

Central Hub is the primary navigation and operational coordination surface for
HYDRA AI HOME OS.

It does not own device, environment, voice or AI business logic. It coordinates
presentation modules through stable route identifiers and EventBus events.
'@

$files["packages/008_central_hub/CHANGELOG.md"] = @'
# Central Hub changelog

## [0.1.0] - 2026-07-17

### Added

- Added route definition resource.
- Added navigation state aggregate.
- Added module launcher widget.
- Added Central Hub service.
- Added Central Hub panel and demo scene.
- Added navigation tests.
'@

$files["packages/008_central_hub/docs/architecture.md"] = @'
# Central Hub architecture

Central Hub is a presentation-composition package.

It owns navigation state, registered route metadata and module activation
requests.

It communicates with packages through EventBus events and does not instantiate
infrastructure implementations directly.
'@

$files["packages/008_central_hub/docs/navigation.md"] = @'
# Navigation model

Every route has a stable route identifier, display name, description, package
identifier, scene path and access state.

Central Hub publishes route activation events. The application composition root
decides which scene or panel is mounted for the requested route.
'@

$files["packages/008_central_hub/resources/hub_route.gd"] = @'
class_name HubRoute
extends Resource
## Defines one navigable Central Hub destination.


#region Identity

@export_group("Identity")
@export var route_id: StringName = &""
@export var package_id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

#endregion


#region Presentation

@export_group("Presentation")
@export var scene_path: String = ""
@export var icon_path: String = ""
@export var sort_order: int = 0
@export var accent_color: Color = Color("#32d8ff")

#endregion


#region Access

@export_group("Access")
@export var enabled: bool = true
@export var visible: bool = true

#endregion


#region Validation

## Returns a structured validation result.
func validate() -> Result:
	if route_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Hub route requires route_id."
			)
		)

	if package_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Hub route requires package_id.",
				{&"route_id": route_id}
			)
		)

	if display_name.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Hub route requires display_name.",
				{&"route_id": route_id}
			)
		)

	if scene_path.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Hub route requires scene_path.",
				{&"route_id": route_id}
			)
		)

	return Result.success()

#endregion
'@

$files["packages/008_central_hub/resources/central_hub_configuration.gd"] = @'
class_name CentralHubConfiguration
extends Resource
## Stores Central Hub runtime configuration.


#region Startup

@export_group("Startup")
@export var default_route_id: StringName = &"home"
@export var restore_last_route: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export var show_disabled_routes: bool = true
@export var launcher_columns: int = 3
@export var launcher_width: float = 320.0
@export var launcher_height: float = 130.0
@export var launcher_horizontal_gap: float = 24.0
@export var launcher_vertical_gap: float = 20.0

#endregion
'@

$files["packages/008_central_hub/resources/default_central_hub_configuration.tres"] = @'
[gd_resource type="Resource" script_class="CentralHubConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/008_central_hub/resources/central_hub_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
default_route_id = &"home"
restore_last_route = true
show_disabled_routes = true
launcher_columns = 3
launcher_width = 320.0
launcher_height = 130.0
launcher_horizontal_gap = 24.0
launcher_vertical_gap = 20.0
'@

$files["packages/008_central_hub/resources/routes/home_route.tres"] = @'
[gd_resource type="Resource" script_class="HubRoute" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/008_central_hub/resources/hub_route.gd" id="1"]

[resource]
script = ExtResource("1")
route_id = &"home"
package_id = &"007_home_hub"
display_name = "HOME HUB"
description = "Residential command overview."
scene_path = "res://packages/007_home_hub/scenes/home_hub_panel.tscn"
sort_order = 10
accent_color = Color(0.196078, 0.847059, 1, 1)
enabled = true
visible = true
'@

$files["packages/008_central_hub/resources/routes/voice_route.tres"] = @'
[gd_resource type="Resource" script_class="HubRoute" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/008_central_hub/resources/hub_route.gd" id="1"]

[resource]
script = ExtResource("1")
route_id = &"voice"
package_id = &"006_voice_hub"
display_name = "VOICE HUB"
description = "Tactical voice control interface."
scene_path = "res://packages/006_voice_hub/scenes/voice_hub_panel.tscn"
sort_order = 20
accent_color = Color(0.839216, 0.666667, 0.282353, 1)
enabled = true
visible = true
'@

$files["packages/008_central_hub/scripts/domain/navigation_state.gd"] = @'
class_name NavigationState
extends AggregateRoot
## Owns Central Hub route registration and active-route state.


#region Events

const EVENT_ROUTE_REGISTERED: StringName = \
	&"hydra.central_hub.route.registered"
const EVENT_ROUTE_ACTIVATED: StringName = \
	&"hydra.central_hub.route.activated"
const EVENT_ROUTE_REJECTED: StringName = \
	&"hydra.central_hub.route.rejected"

#endregion


#region State

var _routes: Dictionary[StringName, HubRoute] = {}
var _active_route_id: StringName = &""
var _previous_route_id: StringName = &""

#endregion


#region Construction

func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

## Registers a validated route.
func register_route(route: HubRoute) -> Result:
	if route == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Central Hub route cannot be null."
			)
		)

	var validation_result := route.validate()

	if validation_result.is_failure():
		return validation_result

	if _routes.has(route.route_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Central Hub route is already registered.",
				{&"route_id": route.route_id}
			)
		)

	_routes[route.route_id] = route
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_ROUTE_REGISTERED,
			{
				&"route_id": route.route_id,
				&"package_id": route.package_id,
			}
		)
	)

	return Result.success()


## Activates a registered and enabled route.
func activate_route(route_id: StringName) -> Result:
	if not _routes.has(route_id):
		return _reject_route(
			route_id,
			"Central Hub route is not registered."
		)

	var route: HubRoute = _routes[route_id]

	if not route.enabled:
		return _reject_route(
			route_id,
			"Central Hub route is disabled."
		)

	if _active_route_id == route_id:
		return Result.success(route)

	_previous_route_id = _active_route_id
	_active_route_id = route_id
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_ROUTE_ACTIVATED,
			{
				&"route_id": route.route_id,
				&"package_id": route.package_id,
				&"scene_path": route.scene_path,
				&"previous_route_id": _previous_route_id,
			}
		)
	)

	return Result.success(route)


## Returns a registered route.
func get_route(route_id: StringName) -> HubRoute:
	return _routes.get(route_id)


## Returns all routes sorted by sort_order.
func get_routes(
	include_hidden: bool = false
) -> Array[HubRoute]:
	var result: Array[HubRoute] = []

	for route: HubRoute in _routes.values():
		if route.visible or include_hidden:
			result.append(route)

	result.sort_custom(
		func(left: HubRoute, right: HubRoute) -> bool:
			return left.sort_order < right.sort_order
	)

	return result


## Returns the active route identifier.
func get_active_route_id() -> StringName:
	return _active_route_id


## Returns the previous route identifier.
func get_previous_route_id() -> StringName:
	return _previous_route_id

#endregion


#region Private methods

func _reject_route(
	route_id: StringName,
	message: String
) -> Result:
	var error := DomainError.new(
		HydraErrors.INVALID_STATE,
		message,
		{&"route_id": route_id}
	)

	_record_domain_event(
		DomainEvent.new(
			EVENT_ROUTE_REJECTED,
			{
				&"route_id": route_id,
				&"error": error.to_dictionary(),
			}
		)
	)

	return Result.failure(error)

#endregion
'@

$files["packages/008_central_hub/scripts/application/central_hub_service.gd"] = @'
class_name CentralHubService
extends Node
## Coordinates route registration and navigation requests.


#region Signals

signal route_registered(route: HubRoute)
signal route_activated(route: HubRoute)
signal route_activation_failed(error: DomainError)

#endregion


#region State

var _configuration: CentralHubConfiguration
var _navigation: NavigationState
var _initialized: bool = false

#endregion


#region Public API

## Configures the Central Hub service.
func configure(
	configuration: CentralHubConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Central Hub configuration cannot be null."
			)
		)

	if configuration.launcher_columns <= 0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Central Hub launcher_columns must be positive."
			)
		)

	_configuration = configuration
	_navigation = NavigationState.new(EntityId.generate())
	_initialized = true

	return Result.success()


## Registers one route.
func register_route(route: HubRoute) -> Result:
	if not _initialized:
		return _not_initialized()

	var result := _navigation.register_route(route)

	if result.is_failure():
		return result

	_publish_events()
	route_registered.emit(route)

	return Result.success(route)


## Registers multiple routes.
func register_routes(routes: Array[HubRoute]) -> Result:
	for route in routes:
		var result := register_route(route)

		if result.is_failure():
			return result

	return Result.success()


## Activates a route.
func activate_route(route_id: StringName) -> Result:
	if not _initialized:
		return _not_initialized()

	var result := _navigation.activate_route(route_id)

	if result.is_failure():
		_publish_events()
		route_activation_failed.emit(result.get_error())
		return result

	var route: HubRoute = result.get_value()

	_publish_events()
	route_activated.emit(route)

	return Result.success(route)


## Activates the configured startup route.
func activate_default_route() -> Result:
	if not _initialized:
		return _not_initialized()

	return activate_route(
		_configuration.default_route_id
	)


## Returns sorted routes.
func get_routes(
	include_hidden: bool = false
) -> Array[HubRoute]:
	if _navigation == null:
		return []

	return _navigation.get_routes(include_hidden)


## Returns the active route.
func get_active_route() -> HubRoute:
	if _navigation == null:
		return null

	return _navigation.get_route(
		_navigation.get_active_route_id()
	)

#endregion


#region Private methods

func _not_initialized() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Central Hub service is not configured."
		)
	)


func _publish_events() -> void:
	if _navigation == null:
		return

	var events := _navigation.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)

#endregion
'@

$files["packages/008_central_hub/scripts/presentation/module_launcher_widget.gd"] = @'
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
'@

$files["packages/008_central_hub/scripts/presentation/central_hub_panel.gd"] = @'
class_name CentralHubPanel
extends PanelBase
## Primary HYDRA module-navigation panel.


#region Constants

const LAUNCHER_START_X: float = 60.0
const LAUNCHER_START_Y: float = 170.0

#endregion


#region Nodes

@onready var _launcher_layer: Control = %LauncherLayer
@onready var _active_route_label: RichTextLabel = %ActiveRouteLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: CentralHubService
var _configuration: CentralHubConfiguration
var _launcher_scene: PackedScene = preload(
	"res://packages/008_central_hub/scenes/module_launcher_widget.tscn"
)

#endregion


#region Public API

## Binds the panel to Central Hub.
func bind_service(
	service: CentralHubService,
	configuration: CentralHubConfiguration
) -> void:
	assert(service != null, "Central Hub service cannot be null.")
	assert(
		configuration != null,
		"Central Hub configuration cannot be null."
	)

	_disconnect_service()

	_service = service
	_configuration = configuration

	_service.route_registered.connect(_on_route_registered)
	_service.route_activated.connect(_on_route_activated)
	_service.route_activation_failed.connect(
		_on_route_activation_failed
	)

	rebuild_launchers()


## Rebuilds all module launchers.
func rebuild_launchers() -> void:
	if _service == null or _configuration == null:
		return

	for child in _launcher_layer.get_children():
		child.queue_free()

	var routes := _service.get_routes(
		_configuration.show_disabled_routes
	)

	for index in routes.size():
		var route := routes[index]

		if (
			not route.enabled
			and not _configuration.show_disabled_routes
		):
			continue

		var launcher := (
			_launcher_scene.instantiate()
			as ModuleLauncherWidget
		)

		var column := index % _configuration.launcher_columns
		var row := index / _configuration.launcher_columns

		launcher.position = Vector2(
			LAUNCHER_START_X + (
				column * (
					_configuration.launcher_width
					+ _configuration.launcher_horizontal_gap
				)
			),
			LAUNCHER_START_Y + (
				row * (
					_configuration.launcher_height
					+ _configuration.launcher_vertical_gap
				)
			)
		)
		launcher.size = Vector2(
			_configuration.launcher_width,
			_configuration.launcher_height
		)

		_launcher_layer.add_child(launcher)
		launcher.apply_route(route)
		launcher.route_requested.connect(
			_on_route_requested
		)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.route_registered.is_connected(
		_on_route_registered
	):
		_service.route_registered.disconnect(
			_on_route_registered
		)

	if _service.route_activated.is_connected(
		_on_route_activated
	):
		_service.route_activated.disconnect(
			_on_route_activated
		)

	if _service.route_activation_failed.is_connected(
		_on_route_activation_failed
	):
		_service.route_activation_failed.disconnect(
			_on_route_activation_failed
		)


func _on_route_requested(route_id: StringName) -> void:
	if _service == null:
		return

	_service.activate_route(route_id)


func _on_route_registered(_route: HubRoute) -> void:
	rebuild_launchers()


func _on_route_activated(route: HubRoute) -> void:
	_error_label.visible = false
	_active_route_label.text = (
		"ACTIVE MODULE  //  %s"
		% route.display_name
	)


func _on_route_activation_failed(
	error: DomainError
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]NAVIGATION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

#endregion
'@

$files["packages/008_central_hub/scenes/module_launcher_widget.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/008_central_hub/scripts/presentation/module_launcher_widget.gd" id="1"]

[node name="ModuleLauncherWidget" type="Control"]
custom_minimum_size = Vector2(320, 130)
layout_mode = 3
anchors_preset = 0
offset_right = 320.0
offset_bottom = 130.0
mouse_filter = 0
script = ExtResource("1")
widget_id = &"module_launcher_widget"

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
offset_bottom = 118.0
mouse_filter = 2
color = Color(0.196078, 0.847059, 1, 1)

[node name="Title" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 14.0
offset_right = 292.0
offset_bottom = 44.0
mouse_filter = 2
bbcode_enabled = true
text = "[color=#32d8ff]MODULE[/color]"
fit_content = true
scroll_active = false

[node name="Description" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 50.0
offset_right = 292.0
offset_bottom = 92.0
mouse_filter = 2
text = "Module description."
scroll_active = false

[node name="Status" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 98.0
offset_right = 292.0
offset_bottom = 122.0
mouse_filter = 2
bbcode_enabled = true
text = "[color=#55f2a3]AVAILABLE[/color]"
fit_content = true
scroll_active = false
'@

$files["packages/008_central_hub/scenes/central_hub_panel.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/008_central_hub/scripts/presentation/central_hub_panel.gd" id="1"]

[node name="CentralHubPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 1180.0
offset_bottom = 820.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"central_hub_panel"
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
offset_right = 700.0
offset_bottom = 60.0
bbcode_enabled = true
text = "[font_size=30][color=#32d8ff]CENTRAL HUB[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 840.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]TACTICAL MODULE CONTROL  //  CHANNEL 008[/color]"
fit_content = true
scroll_active = false

[node name="ActiveRouteLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 112.0
offset_right = 720.0
offset_bottom = 144.0
bbcode_enabled = true
text = "[color=#d6aa48]ACTIVE MODULE  //  NONE[/color]"
fit_content = true
scroll_active = false

[node name="LauncherLayer" type="Control" parent="."]
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
offset_top = 744.0
offset_right = 1126.0
offset_bottom = 800.0
bbcode_enabled = true
text = "[color=#ff4f62]NAVIGATION FAILURE[/color]"
scroll_active = false
'@

$files["packages/008_central_hub/demo/central_hub_demo.gd"] = @'
class_name CentralHubDemo
extends Control
## Demonstrates Central Hub route registration and activation.


#region Resources

const HOME_ROUTE: HubRoute = preload(
	"res://packages/008_central_hub/resources/routes/home_route.tres"
)
const VOICE_ROUTE: HubRoute = preload(
	"res://packages/008_central_hub/resources/routes/voice_route.tres"
)

#endregion


#region Nodes

@onready var _panel: CentralHubPanel = %CentralHubPanel

#endregion


#region State

var _service: CentralHubService
var _configuration: CentralHubConfiguration

#endregion


#region Lifecycle

func _ready() -> void:
	_service = CentralHubService.new()
	_service.name = "CentralHubService"
	add_child(_service)

	_configuration = CentralHubConfiguration.new()

	var configuration_result := _service.configure(
		_configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_panel.bind_service(
		_service,
		_configuration
	)

	var registration_result := _service.register_routes(
		[
			HOME_ROUTE,
			VOICE_ROUTE,
		]
	)

	if registration_result.is_failure():
		push_error(
			registration_result.get_error().get_message()
		)
		return

	_service.activate_default_route()

#endregion
'@

$files["packages/008_central_hub/demo/central_hub_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/008_central_hub/demo/central_hub_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/008_central_hub/scenes/central_hub_panel.tscn" id="2"]

[node name="CentralHubDemo" type="Control"]
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

[node name="CentralHubPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 370.0
offset_top = 130.0
offset_right = 1550.0
offset_bottom = 950.0
'@

$files["packages/008_central_hub/tests/unit/test_navigation_state.gd"] = @'
class_name NavigationStateTest
extends RefCounted
## Provides NavigationState domain tests.


#region Tests

static func run() -> void:
	var navigation := NavigationState.new(
		EntityId.generate()
	)

	var route := HubRoute.new()
	route.route_id = &"test"
	route.package_id = &"test_package"
	route.display_name = "TEST"
	route.scene_path = "res://test_scene.tscn"

	assert(
		navigation.register_route(route).is_success()
	)
	assert(
		navigation.activate_route(&"test").is_success()
	)
	assert(
		navigation.get_active_route_id() == &"test"
	)
	assert(
		navigation.get_routes().size() == 1
	)
	assert(
		not navigation.pull_domain_events().is_empty()
	)

#endregion
'@

$files["packages/008_central_hub/tests/unit/test_hub_route.gd"] = @'
class_name HubRouteTest
extends RefCounted
## Provides HubRoute validation tests.


#region Tests

static func run() -> void:
	var invalid_route := HubRoute.new()
	assert(invalid_route.validate().is_failure())

	var valid_route := HubRoute.new()
	valid_route.route_id = &"home"
	valid_route.package_id = &"007_home_hub"
	valid_route.display_name = "HOME HUB"
	valid_route.scene_path = (
		"res://packages/007_home_hub/scenes/home_hub_panel.tscn"
	)

	assert(valid_route.validate().is_success())

#endregion
'@

$files["packages/008_central_hub/tests/integration/test_central_hub_service.gd"] = @'
class_name CentralHubServiceTest
extends RefCounted
## Provides Central Hub service composition tests.


#region Tests

static func run() -> void:
	var service := CentralHubService.new()
	var configuration := CentralHubConfiguration.new()

	assert(
		service.configure(configuration).is_success()
	)

	var route := HubRoute.new()
	route.route_id = &"home"
	route.package_id = &"007_home_hub"
	route.display_name = "HOME HUB"
	route.scene_path = (
		"res://packages/007_home_hub/scenes/home_hub_panel.tscn"
	)

	assert(service.register_route(route).is_success())
	assert(service.activate_route(&"home").is_success())
	assert(service.get_active_route() == route)

#endregion
'@

$files["autoload/central_hub.gd"] = @'
extends CentralHubService
## Global Central Hub navigation service.
##
## Runtime composition must call configure() and register routes during startup.
'@

$files["docs/package-dependencies-008.md"] = @'
# Package dependency 008

```text
008_central_hub
├── 001_foundation
├── 002_design_system
├── 003_widget_library
├── 004_animation_system
├── 006_voice_hub
└── 007_home_hub
'@

Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing Package 008 - Central Hub..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

Write-Host ""
Write-Host "Package 008 installed." -ForegroundColor Green
Write-Host ""
Write-Host "Optional autoload:" -ForegroundColor Cyan
Write-Host "CentralHub res://autoload/central_hub.gd"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(central-hub): implement package 008"'
Write-Host "git push"