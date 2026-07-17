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
        Write-Host "[SKIP] $RelativePath" -ForegroundColor Yellow
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

# Package 001 — Foundation -----------------------------------------------------

$files["packages/001_foundation/package.cfg"] = @'
[package]

id="001_foundation"
name="Foundation"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray()
'@

$files["packages/001_foundation/README.md"] = @'
# Package 001 — Foundation

Foundation contains stable contracts, domain primitives, module lifecycle
abstractions and presentation base classes used by HYDRA AI HOME OS.

## Dependency rule

Foundation cannot depend on another HYDRA package.
'@

$files["packages/001_foundation/CHANGELOG.md"] = @'
# Foundation changelog

## [0.1.0] - 2026-07-17

### Added

- Added domain primitives.
- Added application result type.
- Added module lifecycle.
- Added event bus contract.
- Added widget and panel base classes.
'@

$files["packages/001_foundation/docs/architecture.md"] = @'
# Foundation architecture

Foundation is the innermost architectural layer.

Higher packages may import Foundation classes. Foundation must not import
classes from higher packages.
'@

$files["packages/001_foundation/scripts/kernel/hydra_constants.gd"] = @'
class_name HydraConstants
extends RefCounted
## Defines stable platform-wide constants.


#region Application

const APPLICATION_ID: StringName = &"hydra_ai_home_os"
const APPLICATION_NAME: String = "HYDRA AI HOME OS"
const APPLICATION_VERSION: String = "0.1.0"

#endregion


#region Resolution

const REFERENCE_WIDTH: int = 1920
const REFERENCE_HEIGHT: int = 1080
const REFERENCE_SIZE: Vector2 = Vector2(
	REFERENCE_WIDTH,
	REFERENCE_HEIGHT
)

#endregion


#region Services

const SERVICE_EVENT_BUS: StringName = &"event_bus"
const SERVICE_THEME_MANAGER: StringName = &"theme_manager"
const SERVICE_ANIMATION_MANAGER: StringName = &"animation_manager"

#endregion
'@

$files["packages/001_foundation/scripts/kernel/hydra_errors.gd"] = @'
class_name HydraErrors
extends RefCounted
## Defines stable machine-readable error codes.


#region General

const UNKNOWN: StringName = &"hydra.error.unknown"
const INVALID_ARGUMENT: StringName = &"hydra.error.invalid_argument"
const INVALID_STATE: StringName = &"hydra.error.invalid_state"
const VALUE_REQUIRED: StringName = &"hydra.error.value_required"

#endregion


#region Services

const SERVICE_NOT_FOUND: StringName = &"hydra.service.not_found"
const SERVICE_ALREADY_REGISTERED: StringName = \
	&"hydra.service.already_registered"

#endregion


#region Modules

const MODULE_INITIALIZATION_FAILED: StringName = \
	&"hydra.module.initialization_failed"
const MODULE_START_FAILED: StringName = &"hydra.module.start_failed"
const MODULE_STOP_FAILED: StringName = &"hydra.module.stop_failed"

#endregion
'@

$files["packages/001_foundation/scripts/domain/entity_id.gd"] = @'
class_name EntityId
extends RefCounted
## Represents an immutable domain entity identifier.


#region State

var _value: StringName

#endregion


#region Construction

func _init(value: StringName) -> void:
	assert(not value.is_empty(), "EntityId cannot be empty.")
	_value = value


static func generate() -> EntityId:
	return EntityId.new(StringName(UUID.v4()))


static func from_string(value: String) -> EntityId:
	var normalized := value.strip_edges()
	assert(not normalized.is_empty(), "EntityId cannot be empty.")

	return EntityId.new(StringName(normalized))

#endregion


#region Public API

func get_value() -> StringName:
	return _value


func as_string() -> String:
	return String(_value)


func equals(other: EntityId) -> bool:
	return other != null and _value == other._value


func get_hash() -> int:
	return hash(_value)

#endregion


#region Object

func _to_string() -> String:
	return as_string()

#endregion
'@

$files["packages/001_foundation/scripts/domain/domain_error.gd"] = @'
class_name DomainError
extends RefCounted
## Represents a structured domain or application failure.


#region State

var _code: StringName
var _message: String
var _details: Dictionary[StringName, Variant]

#endregion


#region Construction

func _init(
	code: StringName,
	message: String,
	details: Dictionary[StringName, Variant] = {}
) -> void:
	assert(not code.is_empty(), "DomainError code cannot be empty.")
	assert(not message.is_empty(), "DomainError message cannot be empty.")

	_code = code
	_message = message
	_details = details.duplicate(true)

#endregion


#region Public API

func get_code() -> StringName:
	return _code


func get_message() -> String:
	return _message


func get_details() -> Dictionary[StringName, Variant]:
	return _details.duplicate(true)


func to_dictionary() -> Dictionary[StringName, Variant]:
	return {
		&"code": _code,
		&"message": _message,
		&"details": _details.duplicate(true),
	}

#endregion
'@

$files["packages/001_foundation/scripts/domain/domain_event.gd"] = @'
class_name DomainEvent
extends RefCounted
## Represents an immutable fact emitted by a domain aggregate.


#region State

var _event_id: StringName
var _event_name: StringName
var _occurred_at_unix_ms: int
var _payload: Dictionary[StringName, Variant]

#endregion


#region Construction

func _init(
	event_name: StringName,
	payload: Dictionary[StringName, Variant] = {}
) -> void:
	assert(not event_name.is_empty(), "DomainEvent name cannot be empty.")

	_event_id = StringName(UUID.v4())
	_event_name = event_name
	_occurred_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	_payload = payload.duplicate(true)

#endregion


#region Public API

func get_event_id() -> StringName:
	return _event_id


func get_event_name() -> StringName:
	return _event_name


func get_occurred_at_unix_ms() -> int:
	return _occurred_at_unix_ms


func get_payload() -> Dictionary[StringName, Variant]:
	return _payload.duplicate(true)

#endregion
'@

$files["packages/001_foundation/scripts/domain/value_object.gd"] = @'
@abstract
class_name ValueObject
extends RefCounted
## Base class for immutable value objects.


#region Public API

func equals(other: ValueObject) -> bool:
	if other == null:
		return false

	if get_script() != other.get_script():
		return false

	return _get_atomic_values() == other._get_atomic_values()


func get_hash() -> int:
	return hash(_get_atomic_values())

#endregion


#region Extension points

@abstract
func _get_atomic_values() -> Array[Variant]

#endregion
'@

$files["packages/001_foundation/scripts/domain/domain_entity.gd"] = @'
@abstract
class_name DomainEntity
extends RefCounted
## Base class for domain objects identified by EntityId.


#region State

var _id: EntityId

#endregion


#region Construction

func _init(id: EntityId) -> void:
	assert(id != null, "DomainEntity requires an EntityId.")
	_id = id

#endregion


#region Public API

func get_id() -> EntityId:
	return _id


func equals(other: DomainEntity) -> bool:
	if other == null:
		return false

	return (
		get_script() == other.get_script()
		and _id.equals(other._id)
	)

#endregion
'@

$files["packages/001_foundation/scripts/domain/aggregate_root.gd"] = @'
@abstract
class_name AggregateRoot
extends DomainEntity
## Base class for domain consistency boundaries.


#region State

var _domain_events: Array[DomainEvent] = []
var _version: int = 0

#endregion


#region Construction

func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

func get_version() -> int:
	return _version


func increment_version() -> void:
	_version += 1


func pull_domain_events() -> Array[DomainEvent]:
	var events := _domain_events.duplicate()
	_domain_events.clear()

	return events

#endregion


#region Protected API

func _record_domain_event(event: DomainEvent) -> void:
	assert(event != null, "DomainEvent cannot be null.")
	_domain_events.append(event)

#endregion
'@

$files["packages/001_foundation/scripts/application/result.gd"] = @'
class_name Result
extends RefCounted
## Represents a successful or failed application operation.


#region State

var _successful: bool
var _value: Variant
var _error: DomainError

#endregion


#region Construction

func _init(
	successful: bool,
	value: Variant = null,
	error: DomainError = null
) -> void:
	_successful = successful
	_value = value
	_error = error


static func success(value: Variant = null) -> Result:
	return Result.new(true, value)


static func failure(error: DomainError) -> Result:
	assert(error != null, "Result.failure() requires DomainError.")
	return Result.new(false, null, error)

#endregion


#region Public API

func is_success() -> bool:
	return _successful


func is_failure() -> bool:
	return not _successful


func get_value() -> Variant:
	assert(_successful, "Failed Result has no value.")
	return _value


func get_error() -> DomainError:
	assert(not _successful, "Successful Result has no error.")
	return _error

#endregion
'@

$files["packages/001_foundation/scripts/contracts/event_bus_port.gd"] = @'
@abstract
class_name EventBusPort
extends Node
## Defines the cross-package event communication contract.


#region Public API

@abstract
func publish(event: DomainEvent) -> void


@abstract
func subscribe(
	event_name: StringName,
	handler: Callable
) -> Result


@abstract
func unsubscribe(
	event_name: StringName,
	handler: Callable
) -> Result

#endregion
'@

$files["packages/001_foundation/scripts/presentation/widget_base.gd"] = @'
@abstract
class_name WidgetBase
extends Control
## Base class for reusable HYDRA HUD widgets.


#region Signals

signal widget_ready(widget_id: StringName)
signal widget_enabled(widget_id: StringName)
signal widget_disabled(widget_id: StringName)

#endregion


#region Exported properties

@export var widget_id: StringName = &""
@export var starts_enabled: bool = true

#endregion


#region Lifecycle

func _ready() -> void:
	assert(not widget_id.is_empty(), "WidgetBase requires widget_id.")

	set_process(starts_enabled)
	visible = starts_enabled
	_on_widget_ready()
	widget_ready.emit(widget_id)


func enable_widget() -> void:
	set_process(true)
	visible = true
	_on_widget_enabled()
	widget_enabled.emit(widget_id)


func disable_widget() -> void:
	set_process(false)
	visible = false
	_on_widget_disabled()
	widget_disabled.emit(widget_id)

#endregion


#region Extension points

func _on_widget_ready() -> void:
	pass


func _on_widget_enabled() -> void:
	pass


func _on_widget_disabled() -> void:
	pass

#endregion
'@

$files["packages/001_foundation/scripts/presentation/panel_base.gd"] = @'
@abstract
class_name PanelBase
extends Control
## Base class for top-level HYDRA interface panels.


#region Signals

signal panel_opened(panel_id: StringName)
signal panel_closed(panel_id: StringName)

#endregion


#region Exported properties

@export var panel_id: StringName = &""
@export var starts_open: bool = false

#endregion


#region Lifecycle

func _ready() -> void:
	assert(not panel_id.is_empty(), "PanelBase requires panel_id.")

	visible = starts_open

	if starts_open:
		_on_panel_opened()


func open_panel() -> void:
	if visible:
		return

	visible = true
	_on_panel_opened()
	panel_opened.emit(panel_id)


func close_panel() -> void:
	if not visible:
		return

	_on_panel_closed()
	visible = false
	panel_closed.emit(panel_id)

#endregion


#region Extension points

func _on_panel_opened() -> void:
	pass


func _on_panel_closed() -> void:
	pass

#endregion
'@

$files["packages/001_foundation/scripts/infrastructure/hydra_event_bus.gd"] = @'
class_name HydraEventBus
extends EventBusPort
## In-memory EventBus implementation used by the desktop runtime.


#region State

var _subscribers: Dictionary[StringName, Array] = {}

#endregion


#region Public API

func publish(event: DomainEvent) -> void:
	if event == null:
		return

	var event_name := event.get_event_name()
	var handlers: Array = _subscribers.get(event_name, []).duplicate()

	for handler: Callable in handlers:
		if handler.is_valid():
			handler.call(event)


func subscribe(
	event_name: StringName,
	handler: Callable
) -> Result:
	if event_name.is_empty() or not handler.is_valid():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Event subscription is invalid."
			)
		)

	if not _subscribers.has(event_name):
		_subscribers[event_name] = []

	var handlers: Array = _subscribers[event_name]

	if handler not in handlers:
		handlers.append(handler)

	return Result.success()


func unsubscribe(
	event_name: StringName,
	handler: Callable
) -> Result:
	if not _subscribers.has(event_name):
		return Result.success()

	var handlers: Array = _subscribers[event_name]
	handlers.erase(handler)

	if handlers.is_empty():
		_subscribers.erase(event_name)

	return Result.success()

#endregion
'@

$files["packages/001_foundation/scenes/widget_base.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/001_foundation/scripts/presentation/widget_base.gd" id="1"]

[node name="WidgetBase" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 320.0
offset_bottom = 120.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"widget_base"
'@

$files["packages/001_foundation/scenes/panel_base.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/001_foundation/scripts/presentation/panel_base.gd" id="1"]

[node name="PanelBase" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 1
script = ExtResource("1")
panel_id = &"panel_base"
'@

$files["packages/001_foundation/demo/foundation_demo.gd"] = @'
class_name FoundationDemo
extends Control
## Demonstrates Foundation event communication.


#region Lifecycle

func _ready() -> void:
	var bus := HydraEventBus.new()
	add_child(bus)

	bus.subscribe(
		&"hydra.foundation.demo",
		_on_demo_event
	)

	bus.publish(
		DomainEvent.new(
			&"hydra.foundation.demo",
			{&"message": "Foundation operational"}
		)
	)

#endregion


#region Event handlers

func _on_demo_event(event: DomainEvent) -> void:
	print(event.get_payload())

#endregion
'@

$files["packages/001_foundation/demo/foundation_demo.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/001_foundation/demo/foundation_demo.gd" id="1"]

[node name="FoundationDemo" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
'@

$files["packages/001_foundation/tests/unit/test_result.gd"] = @'
class_name FoundationResultTest
extends RefCounted
## Provides executable Result smoke tests.


#region Tests

static func run() -> void:
	var success_result := Result.success(42)
	assert(success_result.is_success())
	assert(success_result.get_value() == 42)

	var error := DomainError.new(
		HydraErrors.UNKNOWN,
		"Expected failure."
	)
	var failure_result := Result.failure(error)
	assert(failure_result.is_failure())
	assert(failure_result.get_error() == error)

#endregion
'@

# Package 002 — Design System --------------------------------------------------

$files["packages/002_design_system/package.cfg"] = @'
[package]

id="002_design_system"
name="Design System"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray("001_foundation")
'@

$files["packages/002_design_system/README.md"] = @'
# Package 002 — Design System

Defines HYDRA color, spacing, typography and visual state tokens.
'@

$files["packages/002_design_system/CHANGELOG.md"] = @'
# Design System changelog

## [0.1.0] - 2026-07-17

### Added

- Added military HUD color palette.
- Added layout metrics.
- Added ThemeManager implementation.
'@

$files["packages/002_design_system/docs/visual-language.md"] = @'
# HYDRA visual language

The interface uses deep navy surfaces, cyan holographic highlights, restrained
gold accents and high-contrast operational states.
'@

$files["packages/002_design_system/scripts/hydra_palette.gd"] = @'
class_name HydraPalette
extends Resource
## Stores configurable HYDRA interface colors.


#region Colors

@export_group("Surfaces")
@export var background: Color = Color("#03080d")
@export var panel: Color = Color("#071722")
@export var panel_highlight: Color = Color("#0d2b3c")

@export_group("Holographic")
@export var hologram_blue: Color = Color("#32d8ff")
@export var hologram_blue_dim: Color = Color("#12647a")
@export var hologram_white: Color = Color("#d9f8ff")

@export_group("Accents")
@export var gold: Color = Color("#d6aa48")
@export var gold_dim: Color = Color("#6e5627")

@export_group("States")
@export var success: Color = Color("#55f2a3")
@export var warning: Color = Color("#ffbf47")
@export var danger: Color = Color("#ff4f62")
@export var disabled: Color = Color("#40515b")

#endregion
'@

$files["packages/002_design_system/scripts/hydra_layout.gd"] = @'
class_name HydraLayout
extends RefCounted
## Defines reusable layout measurements.


#region Spacing

const SPACE_XXS: float = 2.0
const SPACE_XS: float = 4.0
const SPACE_SM: float = 8.0
const SPACE_MD: float = 16.0
const SPACE_LG: float = 24.0
const SPACE_XL: float = 32.0
const SPACE_XXL: float = 48.0

#endregion


#region Borders

const BORDER_THIN: float = 1.0
const BORDER_STANDARD: float = 2.0
const BORDER_EMPHASIS: float = 3.0
const CORNER_RADIUS: float = 4.0

#endregion


#region Animation

const DURATION_FAST: float = 0.12
const DURATION_STANDARD: float = 0.24
const DURATION_SLOW: float = 0.48

#endregion
'@

$files["packages/002_design_system/scripts/hydra_theme_manager.gd"] = @'
class_name HydraThemeManager
extends Node
## Owns the active HYDRA design palette.


#region Signals

signal palette_changed(palette: HydraPalette)

#endregion


#region State

var _palette: HydraPalette

#endregion


#region Lifecycle

func _ready() -> void:
	if _palette == null:
		_palette = HydraPalette.new()

#endregion


#region Public API

func set_palette(palette: HydraPalette) -> void:
	assert(palette != null, "Theme palette cannot be null.")

	if _palette == palette:
		return

	_palette = palette
	palette_changed.emit(_palette)


func get_palette() -> HydraPalette:
	if _palette == null:
		_palette = HydraPalette.new()

	return _palette


func get_color(token: StringName) -> Color:
	var palette := get_palette()

	match token:
		&"background":
			return palette.background
		&"panel":
			return palette.panel
		&"panel_highlight":
			return palette.panel_highlight
		&"hologram_blue":
			return palette.hologram_blue
		&"hologram_blue_dim":
			return palette.hologram_blue_dim
		&"hologram_white":
			return palette.hologram_white
		&"gold":
			return palette.gold
		&"gold_dim":
			return palette.gold_dim
		&"success":
			return palette.success
		&"warning":
			return palette.warning
		&"danger":
			return palette.danger
		&"disabled":
			return palette.disabled
		_:
			push_warning("Unknown HYDRA color token: %s" % token)
			return Color.WHITE

#endregion
'@

$files["packages/002_design_system/resources/hydra_palette.tres"] = @'
[gd_resource type="Resource" script_class="HydraPalette" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/002_design_system/scripts/hydra_palette.gd" id="1"]

[resource]
script = ExtResource("1")
background = Color(0.0117647, 0.0313725, 0.0509804, 1)
panel = Color(0.027451, 0.0901961, 0.133333, 1)
panel_highlight = Color(0.0509804, 0.168627, 0.235294, 1)
hologram_blue = Color(0.196078, 0.847059, 1, 1)
hologram_blue_dim = Color(0.0705882, 0.392157, 0.478431, 1)
hologram_white = Color(0.85098, 0.972549, 1, 1)
gold = Color(0.839216, 0.666667, 0.282353, 1)
gold_dim = Color(0.431373, 0.337255, 0.152941, 1)
success = Color(0.333333, 0.94902, 0.639216, 1)
warning = Color(1, 0.74902, 0.278431, 1)
danger = Color(1, 0.309804, 0.384314, 1)
disabled = Color(0.25098, 0.317647, 0.356863, 1)
'@

$files["packages/002_design_system/demo/design_system_demo.gd"] = @'
class_name DesignSystemDemo
extends Control
## Displays the active HYDRA color palette.


#region Lifecycle

func _ready() -> void:
	var palette := HydraPalette.new()
	modulate = palette.hologram_white

#endregion
'@

$files["packages/002_design_system/demo/design_system_demo.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/002_design_system/demo/design_system_demo.gd" id="1"]

[node name="DesignSystemDemo" type="Control"]
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
color = Color(0.0117647, 0.0313725, 0.0509804, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 48.0
offset_top = 48.0
offset_right = 640.0
offset_bottom = 120.0
bbcode_enabled = true
text = "[color=#32d8ff][font_size=32]HYDRA DESIGN SYSTEM[/font_size][/color]"
fit_content = true
'@

$files["packages/002_design_system/tests/test_palette.gd"] = @'
class_name HydraPaletteTest
extends RefCounted
## Provides palette smoke tests.


#region Tests

static func run() -> void:
	var palette := HydraPalette.new()
	assert(palette.hologram_blue.a == 1.0)
	assert(palette.background != palette.panel)

#endregion
'@

# Package 003 — Widget Library -------------------------------------------------

$files["packages/003_widget_library/package.cfg"] = @'
[package]

id="003_widget_library"
name="Widget Library"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray("001_foundation", "002_design_system")
'@

$files["packages/003_widget_library/README.md"] = @'
# Package 003 — Widget Library

Contains reusable manual-layout HUD controls derived from WidgetBase.
'@

$files["packages/003_widget_library/CHANGELOG.md"] = @'
# Widget Library changelog

## [0.1.0] - 2026-07-17

### Added

- Added HUD button.
- Added status badge.
- Added data readout.
'@

$files["packages/003_widget_library/docs/widget-api.md"] = @'
# Widget API

Every widget derives from WidgetBase and exposes a stable widget identifier.
'@

$files["packages/003_widget_library/scripts/hydra_button.gd"] = @'
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
'@

$files["packages/003_widget_library/scripts/hydra_status_badge.gd"] = @'
class_name HydraStatusBadge
extends WidgetBase
## Displays a compact operational state.


#region State enumeration

enum Status {
	OFFLINE,
	STANDBY,
	ONLINE,
	WARNING,
	ERROR,
}

#endregion


#region Exported properties

@export var label: String = "SYSTEM"
@export var status: Status = Status.STANDBY

#endregion


#region Nodes

@onready var _indicator: ColorRect = %Indicator
@onready var _label: RichTextLabel = %Label

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	refresh()


func set_status(value: Status) -> void:
	status = value
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return

	_label.text = "%s  //  %s" % [
		label,
		Status.keys()[status],
	]
	_indicator.color = _get_status_color()

#endregion


#region Private methods

func _get_status_color() -> Color:
	match status:
		Status.OFFLINE:
			return Color("#40515b")
		Status.STANDBY:
			return Color("#d6aa48")
		Status.ONLINE:
			return Color("#55f2a3")
		Status.WARNING:
			return Color("#ffbf47")
		Status.ERROR:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion
'@

$files["packages/003_widget_library/scripts/hydra_data_readout.gd"] = @'
class_name HydraDataReadout
extends WidgetBase
## Displays a label, value and measurement unit.


#region Exported properties

@export var label: String = "VALUE"
@export var value: String = "000"
@export var unit: String = ""

#endregion


#region Nodes

@onready var _label_node: RichTextLabel = %Label
@onready var _value_node: RichTextLabel = %Value

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	refresh()


func set_value(next_value: String) -> void:
	value = next_value
	refresh()


func refresh() -> void:
	if not is_node_ready():
		return

	_label_node.text = label
	_value_node.text = "%s %s" % [value, unit]

#endregion
'@

$files["packages/003_widget_library/scenes/hydra_button.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/003_widget_library/scripts/hydra_button.gd" id="1"]

[sub_resource type="GradientTexture2D" id="GradientTexture_button"]
gradient = Gradient(0, 0.5, 0.5, 1, [0, 1], [Color(0.04, 0.17, 0.24, 1), Color(0.01, 0.05, 0.08, 1)])
width = 256
height = 64

[node name="HydraButton" type="Control"]
custom_minimum_size = Vector2(256, 64)
layout_mode = 3
anchors_preset = 0
offset_right = 256.0
offset_bottom = 64.0
mouse_filter = 0
script = ExtResource("1")
widget_id = &"hydra_button"
action_id = &"default_action"

[node name="Background" type="NinePatchRect" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = SubResource("GradientTexture_button")
patch_margin_left = 8
patch_margin_top = 8
patch_margin_right = 8
patch_margin_bottom = 8
mouse_filter = 2

[node name="Label" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
offset_left = 16.0
offset_top = 12.0
offset_right = -16.0
offset_bottom = -12.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
bbcode_enabled = true
text = "ACTION"
fit_content = true
scroll_active = false
'@

$files["packages/003_widget_library/scenes/hydra_status_badge.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/003_widget_library/scripts/hydra_status_badge.gd" id="1"]

[node name="HydraStatusBadge" type="Control"]
custom_minimum_size = Vector2(280, 40)
layout_mode = 3
anchors_preset = 0
offset_right = 280.0
offset_bottom = 40.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"hydra_status_badge"

[node name="Indicator" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 8.0
offset_top = 12.0
offset_right = 24.0
offset_bottom = 28.0
color = Color(0.33, 0.95, 0.64, 1)
mouse_filter = 2

[node name="Label" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 40.0
offset_top = 4.0
offset_right = 272.0
offset_bottom = 36.0
text = "SYSTEM  //  ONLINE"
fit_content = true
scroll_active = false
'@

$files["packages/003_widget_library/scenes/hydra_data_readout.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/003_widget_library/scripts/hydra_data_readout.gd" id="1"]

[node name="HydraDataReadout" type="Control"]
custom_minimum_size = Vector2(280, 96)
layout_mode = 3
anchors_preset = 0
offset_right = 280.0
offset_bottom = 96.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"hydra_data_readout"

[node name="Label" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 12.0
offset_top = 8.0
offset_right = 268.0
offset_bottom = 36.0
text = "VALUE"
fit_content = true
scroll_active = false

[node name="Value" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 12.0
offset_top = 38.0
offset_right = 268.0
offset_bottom = 88.0
bbcode_enabled = true
text = "[font_size=28][color=#32d8ff]000[/color][/font_size]"
fit_content = true
scroll_active = false
'@

$files["packages/003_widget_library/demo/widget_gallery.tscn"] = @'
[gd_scene load_steps=4 format=3]

[ext_resource type="PackedScene" path="res://packages/003_widget_library/scenes/hydra_button.tscn" id="1"]
[ext_resource type="PackedScene" path="res://packages/003_widget_library/scenes/hydra_status_badge.tscn" id="2"]
[ext_resource type="PackedScene" path="res://packages/003_widget_library/scenes/hydra_data_readout.tscn" id="3"]

[node name="WidgetGallery" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Button" parent="." instance=ExtResource("1")]
layout_mode = 0
offset_left = 80.0
offset_top = 80.0
offset_right = 336.0
offset_bottom = 144.0

[node name="Badge" parent="." instance=ExtResource("2")]
layout_mode = 0
offset_left = 80.0
offset_top = 180.0
offset_right = 360.0
offset_bottom = 220.0

[node name="Readout" parent="." instance=ExtResource("3")]
layout_mode = 0
offset_left = 80.0
offset_top = 260.0
offset_right = 360.0
offset_bottom = 356.0
'@

$files["packages/003_widget_library/tests/test_status_badge.gd"] = @'
class_name HydraStatusBadgeTest
extends RefCounted
## Provides status badge smoke tests.


#region Tests

static func run() -> void:
	var badge := HydraStatusBadge.new()
	badge.status = HydraStatusBadge.Status.ONLINE
	assert(badge.status == HydraStatusBadge.Status.ONLINE)

#endregion
'@

# Package 004 — Animation System ----------------------------------------------

$files["packages/004_animation_system/package.cfg"] = @'
[package]

id="004_animation_system"
name="Animation System"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray("001_foundation", "002_design_system")
'@

$files["packages/004_animation_system/README.md"] = @'
# Package 004 — Animation System

Centralizes interface animation creation, cancellation and reduced-motion
behavior.
'@

$files["packages/004_animation_system/CHANGELOG.md"] = @'
# Animation System changelog

## [0.1.0] - 2026-07-17

### Added

- Added animation profile.
- Added AnimationManager.
- Added fade, slide and pulse operations.
'@

$files["packages/004_animation_system/docs/animation-policy.md"] = @'
# Animation policy

Interface animation communicates state. It must never block user input or hide
critical operational information.
'@

$files["packages/004_animation_system/scripts/hydra_animation_profile.gd"] = @'
class_name HydraAnimationProfile
extends Resource
## Configures standard HYDRA animation durations.


#region Durations

@export var fast_duration: float = 0.12
@export var standard_duration: float = 0.24
@export var slow_duration: float = 0.48

#endregion


#region Motion

@export var slide_distance: float = 32.0
@export var reduced_motion: bool = false

#endregion
'@

$files["packages/004_animation_system/scripts/hydra_animation_manager.gd"] = @'
class_name HydraAnimationManager
extends Node
## Creates and tracks all HYDRA interface tweens.


#region Signals

signal animation_started(animation_id: StringName)
signal animation_completed(animation_id: StringName)
signal animation_cancelled(animation_id: StringName)

#endregion


#region State

var _profile: HydraAnimationProfile
var _active_tweens: Dictionary[StringName, Tween] = {}

#endregion


#region Lifecycle

func _ready() -> void:
	if _profile == null:
		_profile = HydraAnimationProfile.new()

#endregion


#region Public API

func set_profile(profile: HydraAnimationProfile) -> void:
	assert(profile != null, "Animation profile cannot be null.")
	_profile = profile


func fade_in(
	target: CanvasItem,
	animation_id: StringName
) -> Tween:
	assert(target != null, "Animation target cannot be null.")

	cancel(animation_id)
	target.modulate.a = 0.0
	target.visible = true

	var duration := _get_duration(_profile.standard_duration)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate:a", 1.0, duration)

	return _register_tween(animation_id, tween)


func fade_out(
	target: CanvasItem,
	animation_id: StringName
) -> Tween:
	assert(target != null, "Animation target cannot be null.")

	cancel(animation_id)

	var duration := _get_duration(_profile.standard_duration)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(target, "modulate:a", 0.0, duration)
	tween.tween_callback(target.hide)

	return _register_tween(animation_id, tween)


func slide_in(
	target: Control,
	animation_id: StringName,
	direction: Vector2 = Vector2.LEFT
) -> Tween:
	assert(target != null, "Animation target cannot be null.")

	cancel(animation_id)

	var destination := target.position
	target.position = destination + (
		direction.normalized() * _profile.slide_distance
	)
	target.modulate.a = 0.0
	target.visible = true

	var duration := _get_duration(_profile.standard_duration)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "position", destination, duration)
	tween.tween_property(target, "modulate:a", 1.0, duration)

	return _register_tween(animation_id, tween)


func pulse(
	target: CanvasItem,
	animation_id: StringName,
	minimum_alpha: float = 0.45
) -> Tween:
	assert(target != null, "Animation target cannot be null.")

	cancel(animation_id)

	var duration := _get_duration(_profile.slow_duration)
	var tween := create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		target,
		"modulate:a",
		minimum_alpha,
		duration
	)
	tween.tween_property(target, "modulate:a", 1.0, duration)

	return _register_tween(animation_id, tween)


func cancel(animation_id: StringName) -> void:
	if not _active_tweens.has(animation_id):
		return

	var tween := _active_tweens[animation_id]

	if tween != null and tween.is_valid():
		tween.kill()

	_active_tweens.erase(animation_id)
	animation_cancelled.emit(animation_id)


func cancel_all() -> void:
	var animation_ids := _active_tweens.keys()

	for animation_id: StringName in animation_ids:
		cancel(animation_id)

#endregion


#region Private methods

func _register_tween(
	animation_id: StringName,
	tween: Tween
) -> Tween:
	_active_tweens[animation_id] = tween
	animation_started.emit(animation_id)

	tween.finished.connect(
		_on_tween_finished.bind(animation_id),
		CONNECT_ONE_SHOT
	)

	return tween


func _on_tween_finished(animation_id: StringName) -> void:
	_active_tweens.erase(animation_id)
	animation_completed.emit(animation_id)


func _get_duration(configured_duration: float) -> float:
	if _profile.reduced_motion:
		return 0.0

	return configured_duration

#endregion
'@

$files["packages/004_animation_system/resources/default_animation_profile.tres"] = @'
[gd_resource type="Resource" script_class="HydraAnimationProfile" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/004_animation_system/scripts/hydra_animation_profile.gd" id="1"]

[resource]
script = ExtResource("1")
fast_duration = 0.12
standard_duration = 0.24
slow_duration = 0.48
slide_distance = 32.0
reduced_motion = false
'@

$files["packages/004_animation_system/demo/animation_demo.gd"] = @'
class_name AnimationDemo
extends Control
## Demonstrates AnimationManager operations.


#region Nodes

@onready var _target: Control = %Target

#endregion


#region Lifecycle

func _ready() -> void:
	var manager := HydraAnimationManager.new()
	add_child(manager)

	manager.slide_in(
		_target,
		&"animation_demo_slide",
		Vector2.LEFT
	)

#endregion
'@

$files["packages/004_animation_system/demo/animation_demo.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/004_animation_system/demo/animation_demo.gd" id="1"]

[node name="AnimationDemo" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")

[node name="Target" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 128.0
offset_top = 128.0
offset_right = 448.0
offset_bottom = 256.0
color = Color(0.05, 0.3, 0.4, 1)
'@

$files["packages/004_animation_system/tests/test_animation_profile.gd"] = @'
class_name HydraAnimationProfileTest
extends RefCounted
## Provides animation profile smoke tests.


#region Tests

static func run() -> void:
	var profile := HydraAnimationProfile.new()
	assert(profile.fast_duration > 0.0)
	assert(profile.standard_duration >= profile.fast_duration)

#endregion
'@

# Package 005 — FX System ------------------------------------------------------

$files["packages/005_fx_system/package.cfg"] = @'
[package]

id="005_fx_system"
name="FX System"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"004_animation_system"
)
'@

$files["packages/005_fx_system/README.md"] = @'
# Package 005 — FX System

Provides reusable CRT, scanline, hologram and glow effects for HYDRA.
'@

$files["packages/005_fx_system/CHANGELOG.md"] = @'
# FX System changelog

## [0.1.0] - 2026-07-17

### Added

- Added scanline shader.
- Added hologram shader.
- Added CRT overlay.
- Added FX profile and controller.
'@

$files["packages/005_fx_system/docs/performance.md"] = @'
# FX performance

Full-screen effects should use a single overlay whenever possible. Effects may
be disabled through the FX profile on lower-end hardware.
'@

$files["packages/005_fx_system/scripts/hydra_fx_profile.gd"] = @'
class_name HydraFxProfile
extends Resource
## Configures global HYDRA interface effects.


#region Feature switches

@export var crt_enabled: bool = true
@export var scanlines_enabled: bool = true
@export var noise_enabled: bool = true
@export var vignette_enabled: bool = true

#endregion


#region Intensities

@export_range(0.0, 1.0, 0.01) var scanline_intensity: float = 0.18
@export_range(0.0, 1.0, 0.01) var noise_intensity: float = 0.035
@export_range(0.0, 1.0, 0.01) var vignette_intensity: float = 0.35
@export_range(0.0, 4.0, 0.01) var glow_intensity: float = 1.25

#endregion
'@

$files["packages/005_fx_system/scripts/hydra_fx_controller.gd"] = @'
class_name HydraFxController
extends Node
## Applies an FX profile to registered materials.


#region Signals

signal profile_changed(profile: HydraFxProfile)

#endregion


#region State

var _profile: HydraFxProfile
var _materials: Array[ShaderMaterial] = []

#endregion


#region Lifecycle

func _ready() -> void:
	if _profile == null:
		_profile = HydraFxProfile.new()

#endregion


#region Public API

func set_profile(profile: HydraFxProfile) -> void:
	assert(profile != null, "FX profile cannot be null.")

	_profile = profile
	_apply_profile()
	profile_changed.emit(_profile)


func register_material(material: ShaderMaterial) -> void:
	if material == null or material in _materials:
		return

	_materials.append(material)
	_apply_to_material(material)


func unregister_material(material: ShaderMaterial) -> void:
	_materials.erase(material)


func get_profile() -> HydraFxProfile:
	if _profile == null:
		_profile = HydraFxProfile.new()

	return _profile

#endregion


#region Private methods

func _apply_profile() -> void:
	for material in _materials:
		_apply_to_material(material)


func _apply_to_material(material: ShaderMaterial) -> void:
	material.set_shader_parameter(
		"scanline_intensity",
		_profile.scanline_intensity if _profile.scanlines_enabled else 0.0
	)
	material.set_shader_parameter(
		"noise_intensity",
		_profile.noise_intensity if _profile.noise_enabled else 0.0
	)
	material.set_shader_parameter(
		"vignette_intensity",
		_profile.vignette_intensity if _profile.vignette_enabled else 0.0
	)

#endregion
'@

$files["packages/005_fx_system/scripts/crt_overlay.gd"] = @'
class_name CrtOverlay
extends ColorRect
## Full-screen CRT and scanline presentation overlay.


#region Exported properties

@export var profile: HydraFxProfile

#endregion


#region Lifecycle

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if profile == null:
		profile = HydraFxProfile.new()

	_apply_profile()

#endregion


#region Public API

func apply_profile(next_profile: HydraFxProfile) -> void:
	assert(next_profile != null, "FX profile cannot be null.")

	profile = next_profile
	_apply_profile()

#endregion


#region Private methods

func _apply_profile() -> void:
	var shader_material := material as ShaderMaterial

	if shader_material == null:
		return

	shader_material.set_shader_parameter(
		"scanline_intensity",
		profile.scanline_intensity
	)
	shader_material.set_shader_parameter(
		"noise_intensity",
		profile.noise_intensity
	)
	shader_material.set_shader_parameter(
		"vignette_intensity",
		profile.vignette_intensity
	)

#endregion
'@

$files["packages/005_fx_system/shaders/crt_composite.gdshader"] = @'
shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.18;
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.035;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_density : hint_range(100.0, 2000.0) = 900.0;
uniform float time_scale : hint_range(0.0, 10.0) = 1.0;

float random_value(vec2 coordinate) {
	return fract(
		sin(dot(coordinate, vec2(12.9898, 78.233))) * 43758.5453
	);
}

void fragment() {
	vec2 uv = UV;

	float scanline = sin(
		(uv.y * scanline_density) + (TIME * time_scale)
	);
	scanline = 0.5 + (0.5 * scanline);

	float noise = random_value(
		uv + vec2(TIME * 0.001, TIME * 0.002)
	);

	vec2 centered = uv - vec2(0.5);
	float vignette = smoothstep(
		0.25,
		0.75,
		length(centered)
	);

	float alpha =
		(scanline * scanline_intensity)
		+ (noise * noise_intensity)
		+ (vignette * vignette_intensity);

	COLOR = vec4(0.03, 0.18, 0.24, clamp(alpha, 0.0, 0.85));
}
'@

$files["packages/005_fx_system/shaders/hologram.gdshader"] = @'
shader_type canvas_item;

uniform vec4 hologram_color : source_color = vec4(
	0.196,
	0.847,
	1.0,
	1.0
);
uniform float scan_speed : hint_range(0.0, 10.0) = 1.5;
uniform float distortion : hint_range(0.0, 0.1) = 0.008;
uniform float glow_strength : hint_range(0.0, 4.0) = 1.25;

void fragment() {
	vec2 uv = UV;
	float wave = sin((uv.y * 70.0) + (TIME * scan_speed));
	uv.x += wave * distortion;

	vec4 source = texture(TEXTURE, uv);
	float scan = 0.75 + (0.25 * wave);

	vec3 color = source.rgb * hologram_color.rgb;
	color *= scan * glow_strength;

	COLOR = vec4(color, source.a * hologram_color.a);
}
'@

$files["packages/005_fx_system/resources/default_fx_profile.tres"] = @'
[gd_resource type="Resource" script_class="HydraFxProfile" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/005_fx_system/scripts/hydra_fx_profile.gd" id="1"]

[resource]
script = ExtResource("1")
crt_enabled = true
scanlines_enabled = true
noise_enabled = true
vignette_enabled = true
scanline_intensity = 0.18
noise_intensity = 0.035
vignette_intensity = 0.35
glow_intensity = 1.25
'@

$files["packages/005_fx_system/scenes/crt_overlay.tscn"] = @'
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://packages/005_fx_system/scripts/crt_overlay.gd" id="1"]
[ext_resource type="Shader" path="res://packages/005_fx_system/shaders/crt_composite.gdshader" id="2"]
[ext_resource type="Resource" path="res://packages/005_fx_system/resources/default_fx_profile.tres" id="3"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_crt"]
shader = ExtResource("2")
shader_parameter/scanline_intensity = 0.18
shader_parameter/noise_intensity = 0.035
shader_parameter/vignette_intensity = 0.35
shader_parameter/scanline_density = 900.0
shader_parameter/time_scale = 1.0

[node name="CrtOverlay" type="ColorRect"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
material = SubResource("ShaderMaterial_crt")
color = Color(1, 1, 1, 1)
script = ExtResource("1")
profile = ExtResource("3")
'@

$files["packages/005_fx_system/demo/fx_demo.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="res://packages/005_fx_system/scenes/crt_overlay.tscn" id="1"]

[node name="FxDemo" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.01, 0.03, 0.05, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 80.0
offset_top = 80.0
offset_right = 960.0
offset_bottom = 160.0
bbcode_enabled = true
text = "[font_size=36][color=#32d8ff]HYDRA CRT COMPOSITE[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="CrtOverlay" parent="." instance=ExtResource("1")]
layout_mode = 1
'@

$files["packages/005_fx_system/tests/test_fx_profile.gd"] = @'
class_name HydraFxProfileTest
extends RefCounted
## Provides FX profile smoke tests.


#region Tests

static func run() -> void:
	var profile := HydraFxProfile.new()
	assert(profile.scanline_intensity >= 0.0)
	assert(profile.scanline_intensity <= 1.0)
	assert(profile.glow_intensity > 0.0)

#endregion
'@

# Autoload bootstrap -----------------------------------------------------------

$files["autoload/event_bus.gd"] = @'
extends HydraEventBus
## Global HYDRA EventBus.
'@

$files["autoload/theme_manager.gd"] = @'
extends HydraThemeManager
## Global HYDRA ThemeManager.
'@

$files["autoload/animation_manager.gd"] = @'
extends HydraAnimationManager
## Global HYDRA AnimationManager.
'@

$files["autoload/fx_controller.gd"] = @'
extends HydraFxController
## Global HYDRA FX controller.
'@

# Documentation ---------------------------------------------------------------

$files["docs/package-dependencies-001-005.md"] = @'
# Package dependencies 001–005

```text
001_foundation
└── none

002_design_system
└── 001_foundation

003_widget_library
├── 001_foundation
└── 002_design_system

004_animation_system
├── 001_foundation
└── 002_design_system

005_fx_system
├── 001_foundation
├── 002_design_system
└── 004_animation_system
'@

# Write files -----------------------------------------------------------------

Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing packages 001-005..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
    Write-HydraFile `
        -RelativePath $entry.Key `
        -Content $entry.Value
}

Write-Host ""
Write-Host "Packages 001-005 installed." -ForegroundColor Green
Write-Host ""
Write-Host "Add these autoloads in Godot Project Settings:" -ForegroundColor Cyan
Write-Host "EventBus         res://autoload/event_bus.gd"
Write-Host "ThemeManager     res://autoload/theme_manager.gd"
Write-Host "AnimationManager res://autoload/animation_manager.gd"
Write-Host "FxController     res://autoload/fx_controller.gd"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host 'git add .'
Write-Host 'git commit -m "feat(core-ui): implement packages 001-005"'
Write-Host 'git push'