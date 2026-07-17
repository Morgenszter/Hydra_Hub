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

function Assert-GeneratedFiles {
    param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$FileMap
    )

    $missingFiles = New-Object System.Collections.Generic.List[string]

    foreach ($relativePath in $FileMap.Keys) {
        $destination = Join-Path $RepositoryRoot $relativePath

        if (-not (Test-Path $destination)) {
            $missingFiles.Add($relativePath)
        }
    }

    if ($missingFiles.Count -gt 0) {
        throw "Nie utworzono plików:`n$($missingFiles -join "`n")"
    }
}

Assert-HydraRepository

$files = [ordered]@{}

# =============================================================================
# PACKAGE 016 — ANDROID
# =============================================================================

$files["packages/016_android/package.cfg"] = @'
[package]

id="016_android"
name="Android"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"013_diagnostics",
	"014_notification_center"
)
'@

$files["packages/016_android/README.md"] = @'
# Package 016 — Android

Android provides platform detection, capability discovery, lifecycle events and
safe Android integration boundaries for HYDRA AI HOME OS.

Platform-specific implementations remain isolated behind AndroidPlatformPort.

The desktop build uses a null adapter and does not attempt to access Android
runtime classes.
'@

$files["packages/016_android/CHANGELOG.md"] = @'
# Android changelog

## [0.1.0] - 2026-07-18

### Added

- Added Android capability definitions.
- Added Android platform information model.
- Added Android platform contract.
- Added desktop-safe null adapter.
- Added Android runtime adapter.
- Added Android platform service.
- Added Android status panel.
- Added demo scene and tests.
'@

$files["packages/016_android/docs/architecture.md"] = @'
# Android architecture

Package 016 is an infrastructure boundary.

Application and presentation code communicates with AndroidPlatformService.

AndroidPlatformService delegates native operations to AndroidPlatformPort.

The null adapter preserves desktop compatibility.

The runtime adapter may access Android APIs only after verifying that the
application is running on Android.
'@

$files["packages/016_android/docs/permissions.md"] = @'
# Android permissions

HYDRA does not request permissions automatically.

Every permission request must be initiated by an explicit application use case.

A capability must report unavailable when its required permission is absent.

Permission denial must return a structured Result failure.
'@

$files["packages/016_android/resources/android_configuration.gd"] = @'
class_name AndroidConfiguration
extends Resource
## Stores Android integration configuration.


#region Behavior

@export_group("Behavior")
@export var enabled: bool = true
@export var allow_runtime_permission_requests: bool = false
@export var allow_background_operation: bool = false
@export var keep_screen_awake: bool = false

#endregion


#region Notifications

@export_group("Notifications")
@export var notification_channel_id: StringName = &"hydra_system"
@export var notification_channel_name: String = "HYDRA System"
@export var notification_channel_description: String = \
	"HYDRA AI HOME OS operational notifications."

#endregion


#region Diagnostics

@export_group("Diagnostics")
@export var collect_platform_information: bool = true
@export var expose_device_model: bool = true

#endregion
'@

$files["packages/016_android/resources/default_android_configuration.tres"] = @'
[gd_resource type="Resource" script_class="AndroidConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/016_android/resources/android_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
enabled = true
allow_runtime_permission_requests = false
allow_background_operation = false
keep_screen_awake = false
notification_channel_id = &"hydra_system"
notification_channel_name = "HYDRA System"
notification_channel_description = "HYDRA AI HOME OS operational notifications."
collect_platform_information = true
expose_device_model = true
'@

$files["packages/016_android/scripts/domain/android_capability.gd"] = @'
class_name AndroidCapability
extends RefCounted
## Defines normalized Android platform capabilities.


#region Constants

const PLATFORM_RUNTIME: StringName = &"platform_runtime"
const JAVA_API: StringName = &"java_api"
const VIBRATION: StringName = &"vibration"
const NOTIFICATIONS: StringName = &"notifications"
const BACKGROUND_EXECUTION: StringName = &"background_execution"
const KEEP_SCREEN_AWAKE: StringName = &"keep_screen_awake"
const BATTERY_INFORMATION: StringName = &"battery_information"
const NETWORK_INFORMATION: StringName = &"network_information"

#endregion


#region Public API

## Returns all supported capability identifiers.
static func get_all() -> Array[StringName]:
	return [
		PLATFORM_RUNTIME,
		JAVA_API,
		VIBRATION,
		NOTIFICATIONS,
		BACKGROUND_EXECUTION,
		KEEP_SCREEN_AWAKE,
		BATTERY_INFORMATION,
		NETWORK_INFORMATION,
	]

#endregion
'@

$files["packages/016_android/scripts/domain/android_platform_info.gd"] = @'
class_name AndroidPlatformInfo
extends ValueObject
## Represents immutable Android platform information.


#region State

var _is_android: bool
var _operating_system_name: String
var _model_name: String
var _sdk_version: int
var _capabilities: Dictionary[StringName, bool]

#endregion


#region Construction

## Creates normalized platform information.
func _init(
	is_android: bool,
	operating_system_name: String,
	model_name: String,
	sdk_version: int,
	capabilities: Dictionary[StringName, bool]
) -> void:
	assert(
		sdk_version >= 0,
		"Android SDK version cannot be negative."
	)

	_is_android = is_android
	_operating_system_name = operating_system_name.strip_edges()
	_model_name = model_name.strip_edges()
	_sdk_version = sdk_version
	_capabilities = capabilities.duplicate(true)

#endregion


#region Public API

func is_android() -> bool:
	return _is_android


func get_operating_system_name() -> String:
	return _operating_system_name


func get_model_name() -> String:
	return _model_name


func get_sdk_version() -> int:
	return _sdk_version


func has_capability(
	capability: StringName
) -> bool:
	return _capabilities.get(capability, false)


func get_capabilities() -> Dictionary[StringName, bool]:
	return _capabilities.duplicate(true)

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_is_android,
		_operating_system_name,
		_model_name,
		_sdk_version,
		_capabilities,
	]

#endregion
'@

$files["packages/016_android/scripts/contracts/android_platform_port.gd"] = @'
@abstract
class_name AndroidPlatformPort
extends RefCounted
## Defines the Android platform integration boundary.


#region Public API

## Returns normalized platform information.
@abstract
func get_platform_info() -> Result


## Requests a short vibration.
@abstract
func vibrate(duration_milliseconds: int) -> Result


## Enables or disables screen wake locking.
@abstract
func set_keep_screen_awake(enabled: bool) -> Result


## Opens the application notification settings when supported.
@abstract
func open_notification_settings() -> Result


## Returns whether this adapter represents an Android runtime.
@abstract
func is_android_runtime() -> bool

#endregion
'@

$files["packages/016_android/scripts/infrastructure/null_android_platform_adapter.gd"] = @'
class_name NullAndroidPlatformAdapter
extends AndroidPlatformPort
## Desktop-safe Android adapter used outside Android exports.


#region AndroidPlatformPort

func get_platform_info() -> Result:
	var capabilities: Dictionary[StringName, bool] = {}

	for capability in AndroidCapability.get_all():
		capabilities[capability] = false

	return Result.success(
		AndroidPlatformInfo.new(
			false,
			OS.get_name(),
			"DESKTOP",
			0,
			capabilities
		)
	)


func vibrate(_duration_milliseconds: int) -> Result:
	return _unsupported("Vibration")


func set_keep_screen_awake(_enabled: bool) -> Result:
	return _unsupported("Screen wake lock")


func open_notification_settings() -> Result:
	return _unsupported("Notification settings")


func is_android_runtime() -> bool:
	return false

#endregion


#region Private methods

func _unsupported(operation_name: String) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"%s is unavailable outside Android." % operation_name
		)
	)

#endregion
'@

$files["packages/016_android/scripts/infrastructure/android_runtime_adapter.gd"] = @'
class_name AndroidRuntimeAdapter
extends AndroidPlatformPort
## Android runtime adapter using Godot platform singletons.
##
## Android-only calls are guarded by OS platform detection.


#region AndroidPlatformPort

func get_platform_info() -> Result:
	if not is_android_runtime():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Android runtime is unavailable."
			)
		)

	var capabilities: Dictionary[StringName, bool] = {
		AndroidCapability.PLATFORM_RUNTIME: true,
		AndroidCapability.JAVA_API:
			Engine.has_singleton("JavaClassWrapper"),
		AndroidCapability.VIBRATION: true,
		AndroidCapability.NOTIFICATIONS: true,
		AndroidCapability.BACKGROUND_EXECUTION: false,
		AndroidCapability.KEEP_SCREEN_AWAKE: true,
		AndroidCapability.BATTERY_INFORMATION: false,
		AndroidCapability.NETWORK_INFORMATION: false,
	}

	return Result.success(
		AndroidPlatformInfo.new(
			true,
			OS.get_name(),
			"ANDROID DEVICE",
			0,
			capabilities
		)
	)


func vibrate(duration_milliseconds: int) -> Result:
	if not is_android_runtime():
		return _runtime_unavailable()

	if duration_milliseconds <= 0:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Vibration duration must be positive."
			)
		)

	Input.vibrate_handheld(duration_milliseconds)

	return Result.success()


func set_keep_screen_awake(enabled: bool) -> Result:
	if not is_android_runtime():
		return _runtime_unavailable()

	DisplayServer.screen_set_keep_on(enabled)

	return Result.success()


func open_notification_settings() -> Result:
	if not is_android_runtime():
		return _runtime_unavailable()

	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Notification settings integration requires an Android plugin."
		)
	)


func is_android_runtime() -> bool:
	return OS.get_name() == "Android"

#endregion


#region Private methods

func _runtime_unavailable() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Android runtime is unavailable."
		)
	)

#endregion
'@

$files["packages/016_android/scripts/application/android_platform_service.gd"] = @'
class_name AndroidPlatformService
extends Node
## Coordinates Android platform capabilities.


#region Signals

signal platform_initialized(info: AndroidPlatformInfo)
signal keep_screen_awake_changed(enabled: bool)
signal platform_operation_failed(error: DomainError)

#endregion


#region State

var _configuration: AndroidConfiguration
var _adapter: AndroidPlatformPort
var _platform_info: AndroidPlatformInfo

#endregion


#region Public API

## Configures the Android platform service.
func configure(
	configuration: AndroidConfiguration,
	adapter: AndroidPlatformPort
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Android configuration cannot be null."
			)
		)

	if adapter == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Android platform adapter cannot be null."
			)
		)

	_configuration = configuration
	_adapter = adapter

	return Result.success()


## Initializes platform information and configured behavior.
func initialize_platform() -> Result:
	if _configuration == null or _adapter == null:
		return _not_configured()

	var info_result := _adapter.get_platform_info()

	if info_result.is_failure():
		platform_operation_failed.emit(info_result.get_error())
		return info_result

	_platform_info = info_result.get_value()

	if (
		_configuration.keep_screen_awake
		and _adapter.is_android_runtime()
	):
		var wake_result := _adapter.set_keep_screen_awake(true)

		if wake_result.is_failure():
			platform_operation_failed.emit(
				wake_result.get_error()
			)

	platform_initialized.emit(_platform_info)

	return Result.success(_platform_info)


## Requests vibration when available.
func vibrate(
	duration_milliseconds: int = 100
) -> Result:
	if _adapter == null:
		return _not_configured()

	var result := _adapter.vibrate(duration_milliseconds)

	if result.is_failure():
		platform_operation_failed.emit(result.get_error())

	return result


## Changes screen wake-lock state.
func set_keep_screen_awake(enabled: bool) -> Result:
	if _adapter == null:
		return _not_configured()

	var result := _adapter.set_keep_screen_awake(enabled)

	if result.is_failure():
		platform_operation_failed.emit(result.get_error())
		return result

	keep_screen_awake_changed.emit(enabled)

	return Result.success()


## Opens native notification settings.
func open_notification_settings() -> Result:
	if _adapter == null:
		return _not_configured()

	var result := _adapter.open_notification_settings()

	if result.is_failure():
		platform_operation_failed.emit(result.get_error())

	return result


## Returns current platform information.
func get_platform_info() -> AndroidPlatformInfo:
	return _platform_info

#endregion


#region Private methods

func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Android platform service is not configured."
		)
	)

#endregion
'@

$files["packages/016_android/scripts/presentation/android_status_panel.gd"] = @'
class_name AndroidStatusPanel
extends PanelBase
## Displays Android platform availability and capabilities.


#region Constants

const CAPABILITY_START_Y: float = 250.0
const CAPABILITY_ROW_HEIGHT: float = 38.0

#endregion


#region Nodes

@onready var _platform_label: RichTextLabel = %PlatformLabel
@onready var _model_label: RichTextLabel = %ModelLabel
@onready var _sdk_label: RichTextLabel = %SdkLabel
@onready var _capability_output: RichTextLabel = %CapabilityOutput
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: AndroidPlatformService

#endregion


#region Public API

## Binds the panel to AndroidPlatformService.
func bind_service(
	service: AndroidPlatformService
) -> void:
	assert(
		service != null,
		"Android platform service cannot be null."
	)

	_disconnect_service()
	_service = service

	_service.platform_initialized.connect(
		_on_platform_initialized
	)
	_service.platform_operation_failed.connect(
		_on_platform_operation_failed
	)

	var info := _service.get_platform_info()

	if info != null:
		_render_info(info)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.platform_initialized.is_connected(
		_on_platform_initialized
	):
		_service.platform_initialized.disconnect(
			_on_platform_initialized
		)

	if _service.platform_operation_failed.is_connected(
		_on_platform_operation_failed
	):
		_service.platform_operation_failed.disconnect(
			_on_platform_operation_failed
		)


func _on_platform_initialized(
	info: AndroidPlatformInfo
) -> void:
	_error_label.visible = false
	_render_info(info)


func _render_info(info: AndroidPlatformInfo) -> void:
	_platform_label.text = (
		"PLATFORM  //  %s"
		% info.get_operating_system_name().to_upper()
	)
	_model_label.text = (
		"MODEL  //  %s"
		% info.get_model_name().to_upper()
	)
	_sdk_label.text = (
		"ANDROID SDK  //  %d"
		% info.get_sdk_version()
	)

	_capability_output.text = ""

	for capability in AndroidCapability.get_all():
		var available := info.has_capability(capability)
		var color := "#55f2a3" if available else "#40515b"
		var state := "AVAILABLE" if available else "UNAVAILABLE"

		_capability_output.append_text(
			"[color=%s]%s  //  %s[/color]\n"
			% [
				color,
				String(capability).to_upper(),
				state,
			]
		)


func _on_platform_operation_failed(
	error: DomainError
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]ANDROID OPERATION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

#endregion
'@

$files["packages/016_android/scenes/android_status_panel.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/016_android/scripts/presentation/android_status_panel.gd" id="1"]

[node name="AndroidStatusPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 840.0
offset_bottom = 760.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"android_status_panel"
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
color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 20.0
offset_right = 720.0
offset_bottom = 60.0
bbcode_enabled = true
text = "[font_size=30][color=#32d8ff]ANDROID PLATFORM[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 780.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]MOBILE RUNTIME BRIDGE  //  CHANNEL 016[/color]"
fit_content = true
scroll_active = false

[node name="PlatformLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 126.0
offset_right = 780.0
offset_bottom = 158.0
text = "PLATFORM  //  UNKNOWN"
fit_content = true
scroll_active = false

[node name="ModelLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 168.0
offset_right = 780.0
offset_bottom = 200.0
text = "MODEL  //  UNKNOWN"
fit_content = true
scroll_active = false

[node name="SdkLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 210.0
offset_right = 780.0
offset_bottom = 242.0
text = "ANDROID SDK  //  0"
fit_content = true
scroll_active = false

[node name="CapabilityOutput" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 270.0
offset_right = 780.0
offset_bottom = 650.0
bbcode_enabled = true
text = "[color=#40515b]NO PLATFORM DATA[/color]"
scroll_active = false

[node name="ErrorLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 54.0
offset_top = 674.0
offset_right = 780.0
offset_bottom = 742.0
bbcode_enabled = true
text = "[color=#ff4f62]ANDROID OPERATION FAILURE[/color]"
scroll_active = false
'@

$files["packages/016_android/demo/android_demo.gd"] = @'
class_name AndroidDemo
extends Control
## Demonstrates platform-safe Android composition.


#region Nodes

@onready var _panel: AndroidStatusPanel = %AndroidStatusPanel

#endregion


#region State

var _service: AndroidPlatformService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = AndroidPlatformService.new()
	_service.name = "AndroidPlatformService"
	add_child(_service)

	var configuration := AndroidConfiguration.new()
	var adapter: AndroidPlatformPort

	if OS.get_name() == "Android":
		adapter = AndroidRuntimeAdapter.new()
	else:
		adapter = NullAndroidPlatformAdapter.new()

	var result := _service.configure(
		configuration,
		adapter
	)

	if result.is_failure():
		push_error(result.get_error().get_message())
		return

	_panel.bind_service(_service)
	_service.initialize_platform()

#endregion
'@

$files["packages/016_android/demo/android_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/016_android/demo/android_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/016_android/scenes/android_status_panel.tscn" id="2"]

[node name="AndroidDemo" type="Control"]
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

[node name="AndroidStatusPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 540.0
offset_top = 160.0
offset_right = 1380.0
offset_bottom = 920.0
'@

$files["packages/016_android/tests/unit/test_android_platform_info.gd"] = @'
class_name AndroidPlatformInfoTest
extends RefCounted
## Provides AndroidPlatformInfo tests.


#region Tests

static func run() -> void:
	var info := AndroidPlatformInfo.new(
		false,
		"Windows",
		"DESKTOP",
		0,
		{
			AndroidCapability.PLATFORM_RUNTIME: false,
		}
	)

	assert(not info.is_android())
	assert(info.get_operating_system_name() == "Windows")
	assert(
		not info.has_capability(
			AndroidCapability.PLATFORM_RUNTIME
		)
	)

#endregion
'@

$files["packages/016_android/tests/integration/test_null_android_adapter.gd"] = @'
class_name NullAndroidAdapterTest
extends RefCounted
## Provides desktop-safe Android adapter tests.


#region Tests

static func run() -> void:
	var adapter := NullAndroidPlatformAdapter.new()
	var result := adapter.get_platform_info()

	assert(result.is_success())
	assert(not adapter.is_android_runtime())
	assert(adapter.vibrate(100).is_failure())

#endregion
'@

# =============================================================================
# PACKAGE 017 — INSTALLER
# =============================================================================

$files["packages/017_installer/package.cfg"] = @'
[package]

id="017_installer"
name="Installer"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"013_diagnostics",
	"014_notification_center"
)
'@

$files["packages/017_installer/README.md"] = @'
# Package 017 — Installer

Installer owns installation plans, file deployment, validation, rollback
metadata and the desktop installation interface.

Installation operations are restricted to explicitly configured writable
directories.

The runtime installer never modifies res:// resources.
'@

$files["packages/017_installer/CHANGELOG.md"] = @'
# Installer changelog

## [0.1.0] - 2026-07-18

### Added

- Added installation package manifest.
- Added installation operation model.
- Added installation plan aggregate.
- Added file-system installer contract.
- Added user-directory file-system adapter.
- Added installer service.
- Added installer progress panel.
- Added demo scene and tests.
'@

$files["packages/017_installer/docs/architecture.md"] = @'
# Installer architecture

Installer separates installation planning from file-system operations.

InstallationPlan owns validation and lifecycle state.

InstallerService executes operations through InstallerFileSystemPort.

The default adapter permits writes only under user://.

Rollback metadata records files created during the active installation.
'@

$files["packages/017_installer/docs/security.md"] = @'
# Installer security

Paths containing traversal segments are rejected.

Absolute operating-system paths are rejected by the default adapter.

Installer packages may write only to approved user:// locations.

Existing files are not overwritten unless the installation plan explicitly
allows replacement.

Executable files are not launched by Installer.
'@

$files["packages/017_installer/resources/installer_configuration.gd"] = @'
class_name InstallerConfiguration
extends Resource
## Stores Installer runtime configuration.


#region Paths

@export_group("Paths")
@export var installation_root: String = "user://hydra"
@export var backup_root: String = "user://hydra_backups"

#endregion


#region Behavior

@export_group("Behavior")
@export var allow_overwrite: bool = false
@export var create_backups: bool = true
@export var validate_after_installation: bool = true
@export var rollback_on_failure: bool = true

#endregion


#region Limits

@export_group("Limits")
@export_range(1, 100000, 1) var maximum_operations: int = 10000
@export_range(1, 1073741824, 1024) var maximum_file_size_bytes: int = 67108864

#endregion
'@

$files["packages/017_installer/resources/default_installer_configuration.tres"] = @'
[gd_resource type="Resource" script_class="InstallerConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/017_installer/resources/installer_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
installation_root = "user://hydra"
backup_root = "user://hydra_backups"
allow_overwrite = false
create_backups = true
validate_after_installation = true
rollback_on_failure = true
maximum_operations = 10000
maximum_file_size_bytes = 67108864
'@

$files["packages/017_installer/scripts/domain/installation_state.gd"] = @'
class_name InstallationState
extends RefCounted
## Defines installation lifecycle states.


#region Values

enum Value {
	DRAFT,
	VALIDATED,
	INSTALLING,
	COMPLETED,
	FAILED,
	ROLLING_BACK,
	ROLLED_BACK,
	CANCELLED,
}

#endregion


#region Public API

## Returns a stable state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.DRAFT:
			return &"draft"
		Value.VALIDATED:
			return &"validated"
		Value.INSTALLING:
			return &"installing"
		Value.COMPLETED:
			return &"completed"
		Value.FAILED:
			return &"failed"
		Value.ROLLING_BACK:
			return &"rolling_back"
		Value.ROLLED_BACK:
			return &"rolled_back"
		Value.CANCELLED:
			return &"cancelled"
		_:
			return &"unknown"

#endregion
'@

$files["packages/017_installer/scripts/domain/installation_operation.gd"] = @'
class_name InstallationOperation
extends ValueObject
## Represents one immutable installation file operation.


#region Operation types

enum Type {
	CREATE_DIRECTORY,
	WRITE_TEXT_FILE,
	REMOVE_FILE,
}

#endregion


#region State

var _operation_id: StringName
var _type: Type
var _relative_path: String
var _content: String
var _replace_existing: bool

#endregion


#region Construction

## Creates an installation operation.
func _init(
	type: Type,
	relative_path: String,
	content: String = "",
	replace_existing: bool = false
) -> void:
	assert(
		not relative_path.strip_edges().is_empty(),
		"InstallationOperation requires relative_path."
	)

	_operation_id = StringName(
		"install-%s-%s"
		% [
			Time.get_ticks_usec(),
			randi(),
		]
	)
	_type = type
	_relative_path = relative_path.strip_edges()
	_content = content
	_replace_existing = replace_existing

#endregion


#region Public API

func get_operation_id() -> StringName:
	return _operation_id


func get_type() -> Type:
	return _type


func get_relative_path() -> String:
	return _relative_path


func get_content() -> String:
	return _content


func can_replace_existing() -> bool:
	return _replace_existing


func validate() -> Result:
	if _relative_path.is_absolute_path():
		return _invalid_path()

	if _relative_path.contains(".."):
		return _invalid_path()

	if _relative_path.begins_with("/"):
		return _invalid_path()

	return Result.success()

#endregion


#region Private methods

func _invalid_path() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_ARGUMENT,
			"Installation operation contains an unsafe path.",
			{
				&"relative_path": _relative_path,
			}
		)
	)

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_operation_id,
		_type,
		_relative_path,
		_content,
		_replace_existing,
	]

#endregion
'@

$files["packages/017_installer/scripts/domain/installation_manifest.gd"] = @'
class_name InstallationManifest
extends Resource
## Describes one installable HYDRA package.


#region Identity

@export_group("Identity")
@export var package_id: StringName = &""
@export var display_name: String = ""
@export var version: String = "0.1.0"

#endregion


#region Compatibility

@export_group("Compatibility")
@export var minimum_hydra_version: String = "0.1.0"
@export var required_packages: PackedStringArray = PackedStringArray()

#endregion


#region Metadata

@export_group("Metadata")
@export_multiline var description: String = ""
@export var checksum: String = ""

#endregion


#region Validation

## Validates required manifest fields.
func validate() -> Result:
	if package_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installation manifest requires package_id."
			)
		)

	if display_name.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installation manifest requires display_name."
			)
		)

	if version.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installation manifest requires version."
			)
		)

	return Result.success()

#endregion
'@

$files["packages/017_installer/scripts/domain/installation_plan.gd"] = @'
class_name InstallationPlan
extends AggregateRoot
## Owns one installation plan and lifecycle.


#region Events

const EVENT_STATE_CHANGED: StringName = \
	&"hydra.installer.state_changed"
const EVENT_OPERATION_COMPLETED: StringName = \
	&"hydra.installer.operation_completed"
const EVENT_FAILED: StringName = \
	&"hydra.installer.failed"

#endregion


#region State

var _manifest: InstallationManifest
var _operations: Array[InstallationOperation] = []
var _state: InstallationState.Value = InstallationState.Value.DRAFT
var _completed_operations: int = 0
var _error: DomainError

#endregion


#region Construction

## Creates an installation plan.
func _init(
	id: EntityId,
	manifest: InstallationManifest,
	operations: Array[InstallationOperation]
) -> void:
	super(id)

	assert(
		manifest != null,
		"InstallationPlan requires manifest."
	)

	_manifest = manifest
	_operations = operations.duplicate()

#endregion


#region Public API

func get_manifest() -> InstallationManifest:
	return _manifest


func get_operations() -> Array[InstallationOperation]:
	return _operations.duplicate()


func get_state() -> InstallationState.Value:
	return _state


func get_completed_operations() -> int:
	return _completed_operations


func get_operation_count() -> int:
	return _operations.size()


func get_progress() -> float:
	if _operations.is_empty():
		return 1.0

	return float(_completed_operations) / float(_operations.size())


func get_error() -> DomainError:
	return _error


func validate_plan(
	maximum_operations: int
) -> Result:
	var manifest_result := _manifest.validate()

	if manifest_result.is_failure():
		return manifest_result

	if _operations.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Installation plan contains no operations."
			)
		)

	if _operations.size() > maximum_operations:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installation operation limit exceeded."
			)
		)

	for operation in _operations:
		var operation_result := operation.validate()

		if operation_result.is_failure():
			return operation_result

	_state = InstallationState.Value.VALIDATED
	_record_state_event()

	return Result.success()


func start_installation() -> Result:
	if _state != InstallationState.Value.VALIDATED:
		return _invalid_state("start")

	_state = InstallationState.Value.INSTALLING
	_record_state_event()

	return Result.success()


func record_operation_completed(
	operation: InstallationOperation
) -> void:
	_completed_operations += 1
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_OPERATION_COMPLETED,
			{
				&"package_id": _manifest.package_id,
				&"operation_id": operation.get_operation_id(),
				&"completed": _completed_operations,
				&"total": _operations.size(),
			}
		)
	)


func complete_installation() -> Result:
	if _state != InstallationState.Value.INSTALLING:
		return _invalid_state("complete")

	_state = InstallationState.Value.COMPLETED
	increment_version()
	_record_state_event()

	return Result.success()


func fail_installation(
	error: DomainError
) -> Result:
	_error = error
	_state = InstallationState.Value.FAILED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_FAILED,
			{
				&"package_id": _manifest.package_id,
				&"error": error.to_dictionary(),
			}
		)
	)

	_record_state_event()

	return Result.success()


func start_rollback() -> Result:
	_state = InstallationState.Value.ROLLING_BACK
	_record_state_event()

	return Result.success()


func complete_rollback() -> Result:
	_state = InstallationState.Value.ROLLED_BACK
	_record_state_event()

	return Result.success()

#endregion


#region Private methods

func _invalid_state(operation: String) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Installation state transition is invalid.",
			{
				&"operation": operation,
				&"state":
					InstallationState.to_string_name(_state),
			}
		)
	)


func _record_state_event() -> void:
	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_CHANGED,
			{
				&"package_id": _manifest.package_id,
				&"state":
					InstallationState.to_string_name(_state),
			}
		)
	)

#endregion
'@

$files["packages/017_installer/scripts/contracts/installer_file_system_port.gd"] = @'
@abstract
class_name InstallerFileSystemPort
extends RefCounted
## Defines restricted installer file-system operations.


#region Public API

@abstract
func create_directory(relative_path: String) -> Result


@abstract
func write_text_file(
	relative_path: String,
	content: String,
	replace_existing: bool
) -> Result


@abstract
func remove_file(relative_path: String) -> Result


@abstract
func file_exists(relative_path: String) -> bool


@abstract
func rollback() -> Result

#endregion
'@

$files["packages/017_installer/scripts/infrastructure/user_directory_installer_adapter.gd"] = @'
class_name UserDirectoryInstallerAdapter
extends InstallerFileSystemPort
## Restricts installation operations to one user:// root.


#region State

var _root_path: String
var _created_paths: PackedStringArray = PackedStringArray()

#endregion


#region Construction

func _init(root_path: String) -> void:
	assert(
		root_path.begins_with("user://"),
		"Installer root must use user://."
	)

	_root_path = root_path.trim_suffix("/")

#endregion


#region InstallerFileSystemPort

func create_directory(relative_path: String) -> Result:
	var path_result := _resolve(relative_path)

	if path_result.is_failure():
		return path_result

	var absolute_path: String = path_result.get_value()
	var error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(absolute_path)
	)

	if error != OK and error != ERR_ALREADY_EXISTS:
		return _file_error(
			"Failed to create installation directory.",
			relative_path,
			error
		)

	_created_paths.append(absolute_path)

	return Result.success()


func write_text_file(
	relative_path: String,
	content: String,
	replace_existing: bool
) -> Result:
	var path_result := _resolve(relative_path)

	if path_result.is_failure():
		return path_result

	var path: String = path_result.get_value()

	if FileAccess.file_exists(path) and not replace_existing:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Installation file already exists.",
				{&"path": relative_path}
			)
		)

	var parent_path := path.get_base_dir()
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(parent_path)
	)

	if directory_error != OK and directory_error != ERR_ALREADY_EXISTS:
		return _file_error(
			"Failed to create parent directory.",
			relative_path,
			directory_error
		)

	var file := FileAccess.open(path, FileAccess.WRITE)

	if file == null:
		return _file_error(
			"Failed to open installation file.",
			relative_path,
			FileAccess.get_open_error()
		)

	file.store_string(content)
	file.close()
	_created_paths.append(path)

	return Result.success()


func remove_file(relative_path: String) -> Result:
	var path_result := _resolve(relative_path)

	if path_result.is_failure():
		return path_result

	var path: String = path_result.get_value()

	if not FileAccess.file_exists(path):
		return Result.success()

	var error := DirAccess.remove_absolute(
		ProjectSettings.globalize_path(path)
	)

	if error != OK:
		return _file_error(
			"Failed to remove installation file.",
			relative_path,
			error
		)

	return Result.success()


func file_exists(relative_path: String) -> bool:
	var path_result := _resolve(relative_path)

	if path_result.is_failure():
		return false

	return FileAccess.file_exists(path_result.get_value())


func rollback() -> Result:
	for index in range(
		_created_paths.size() - 1,
		-1,
		-1
	):
		var path := _created_paths[index]

		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(
				ProjectSettings.globalize_path(path)
			)

	_created_paths.clear()

	return Result.success()

#endregion


#region Private methods

func _resolve(relative_path: String) -> Result:
	var normalized := relative_path.strip_edges()

	if (
		normalized.is_empty()
		or normalized.is_absolute_path()
		or normalized.contains("..")
		or normalized.begins_with("/")
	):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Installer path is unsafe.",
				{&"path": relative_path}
			)
		)

	return Result.success(
		"%s/%s" % [_root_path, normalized]
	)


func _file_error(
	message: String,
	path: String,
	error: Error
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.UNKNOWN,
			message,
			{
				&"path": path,
				&"error": error,
			}
		)
	)

#endregion
'@

$files["packages/017_installer/scripts/application/installer_service.gd"] = @'
class_name InstallerService
extends Node
## Validates and executes installation plans.


#region Signals

signal installation_started(plan: InstallationPlan)
signal operation_completed(
	plan: InstallationPlan,
	operation: InstallationOperation
)
signal installation_progress_changed(
	plan: InstallationPlan,
	progress: float
)
signal installation_completed(plan: InstallationPlan)
signal installation_failed(
	plan: InstallationPlan,
	error: DomainError
)
signal rollback_completed(plan: InstallationPlan)

#endregion


#region State

var _configuration: InstallerConfiguration
var _file_system: InstallerFileSystemPort
var _active_plan: InstallationPlan

#endregion


#region Public API

## Configures Installer.
func configure(
	configuration: InstallerConfiguration,
	file_system: InstallerFileSystemPort
) -> Result:
	if configuration == null or file_system == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Installer configuration and file system are required."
			)
		)

	_configuration = configuration
	_file_system = file_system

	return Result.success()


## Executes a complete installation plan.
func install(
	plan: InstallationPlan
) -> Result:
	if _configuration == null or _file_system == null:
		return _not_configured()

	if plan == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Installation plan cannot be null."
			)
		)

	var validation_result := plan.validate_plan(
		_configuration.maximum_operations
	)

	if validation_result.is_failure():
		return validation_result

	var start_result := plan.start_installation()

	if start_result.is_failure():
		return start_result

	_active_plan = plan
	installation_started.emit(plan)
	_publish_events(plan)

	for operation in plan.get_operations():
		var operation_result := _execute_operation(operation)

		if operation_result.is_failure():
			return _handle_failure(
				plan,
				operation_result.get_error()
			)

		plan.record_operation_completed(operation)
		_publish_events(plan)
		operation_completed.emit(plan, operation)
		installation_progress_changed.emit(
			plan,
			plan.get_progress()
		)

	var completion_result := plan.complete_installation()

	if completion_result.is_failure():
		return _handle_failure(
			plan,
			completion_result.get_error()
		)

	_publish_events(plan)
	installation_completed.emit(plan)
	_active_plan = null

	return Result.success(plan)


## Returns the active plan.
func get_active_plan() -> InstallationPlan:
	return _active_plan

#endregion


#region Private methods

func _execute_operation(
	operation: InstallationOperation
) -> Result:
	match operation.get_type():
		InstallationOperation.Type.CREATE_DIRECTORY:
			return _file_system.create_directory(
				operation.get_relative_path()
			)

		InstallationOperation.Type.WRITE_TEXT_FILE:
			if (
				operation.get_content().to_utf8_buffer().size()
				> _configuration.maximum_file_size_bytes
			):
				return Result.failure(
					DomainError.new(
						HydraErrors.INVALID_ARGUMENT,
						"Installation file exceeds size limit.",
						{
							&"path":
								operation.get_relative_path(),
						}
					)
				)

			return _file_system.write_text_file(
				operation.get_relative_path(),
				operation.get_content(),
				(
					_configuration.allow_overwrite
					or operation.can_replace_existing()
				)
			)

		InstallationOperation.Type.REMOVE_FILE:
			return _file_system.remove_file(
				operation.get_relative_path()
			)

		_:
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_ARGUMENT,
					"Unsupported installation operation."
				)
			)


func _handle_failure(
	plan: InstallationPlan,
	error: DomainError
) -> Result:
	plan.fail_installation(error)
	_publish_events(plan)
	installation_failed.emit(plan, error)

	if _configuration.rollback_on_failure:
		plan.start_rollback()
		_file_system.rollback()
		plan.complete_rollback()
		_publish_events(plan)
		rollback_completed.emit(plan)

	_active_plan = null

	return Result.failure(error)


func _publish_events(plan: InstallationPlan) -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	var events := plan.pull_domain_events()

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Installer is not configured."
		)
	)

#endregion
'@

$files["packages/017_installer/scripts/presentation/installer_panel.gd"] = @'
class_name InstallerPanel
extends PanelBase
## Displays installation progress and state.


#region Nodes

@onready var _package_label: RichTextLabel = %PackageLabel
@onready var _state_label: RichTextLabel = %StateLabel
@onready var _progress_fill: ColorRect = %ProgressFill
@onready var _progress_label: RichTextLabel = %ProgressLabel
@onready var _operation_label: RichTextLabel = %OperationLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: InstallerService

#endregion


#region Public API

## Binds the panel to InstallerService.
func bind_service(service: InstallerService) -> void:
	assert(service != null, "Installer service cannot be null.")

	_disconnect_service()
	_service = service

	_service.installation_started.connect(
		_on_installation_started
	)
	_service.operation_completed.connect(
		_on_operation_completed
	)
	_service.installation_progress_changed.connect(
		_on_progress_changed
	)
	_service.installation_completed.connect(
		_on_installation_completed
	)
	_service.installation_failed.connect(
		_on_installation_failed
	)
	_service.rollback_completed.connect(
		_on_rollback_completed
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.installation_started.is_connected(
		_on_installation_started
	):
		_service.installation_started.disconnect(
			_on_installation_started
		)

	if _service.operation_completed.is_connected(
		_on_operation_completed
	):
		_service.operation_completed.disconnect(
			_on_operation_completed
		)

	if _service.installation_progress_changed.is_connected(
		_on_progress_changed
	):
		_service.installation_progress_changed.disconnect(
			_on_progress_changed
		)

	if _service.installation_completed.is_connected(
		_on_installation_completed
	):
		_service.installation_completed.disconnect(
			_on_installation_completed
		)

	if _service.installation_failed.is_connected(
		_on_installation_failed
	):
		_service.installation_failed.disconnect(
			_on_installation_failed
		)

	if _service.rollback_completed.is_connected(
		_on_rollback_completed
	):
		_service.rollback_completed.disconnect(
			_on_rollback_completed
		)


func _on_installation_started(
	plan: InstallationPlan
) -> void:
	_error_label.visible = false
	_package_label.text = (
		"PACKAGE  //  %s    VERSION  //  %s"
		% [
			plan.get_manifest().display_name,
			plan.get_manifest().version,
		]
	)
	_set_state(plan)
	_set_progress(0.0)


func _on_operation_completed(
	_plan: InstallationPlan,
	operation: InstallationOperation
) -> void:
	_operation_label.text = (
		"OPERATION  //  %s"
		% operation.get_relative_path()
	)


func _on_progress_changed(
	plan: InstallationPlan,
	progress: float
) -> void:
	_set_state(plan)
	_set_progress(progress)


func _on_installation_completed(
	plan: InstallationPlan
) -> void:
	_set_state(plan)
	_set_progress(1.0)
	_operation_label.text = "INSTALLATION COMPLETED"


func _on_installation_failed(
	plan: InstallationPlan,
	error: DomainError
) -> void:
	_set_state(plan)
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]INSTALLATION FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()


func _on_rollback_completed(
	plan: InstallationPlan
) -> void:
	_set_state(plan)
	_operation_label.text = "ROLLBACK COMPLETED"


func _set_state(plan: InstallationPlan) -> void:
	_state_label.text = (
		"STATE  //  %s"
		% String(
			InstallationState.to_string_name(
				plan.get_state()
			)
		).to_upper()
	)


func _set_progress(progress: float) -> void:
	var normalized := clampf(progress, 0.0, 1.0)
	_progress_fill.scale.x = normalized
	_progress_label.text = "%d%%" % int(normalized * 100.0)

#endregion
'@

$files["packages/017_installer/scenes/installer_panel.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/017_installer/scripts/presentation/installer_panel.gd" id="1"]

[node name="InstallerPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 880.0
offset_bottom = 620.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"installer_panel"
starts_open = true

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.0117647, 0.0313725, 0.0509804, 0.97)

[node name="HeaderAccent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 28.0
offset_top = 24.0
offset_right = 34.0
offset_bottom = 94.0
color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 20.0
offset_right = 700.0
offset_bottom = 60.0
bbcode_enabled = true
text = "[font_size=30][color=#32d8ff]INSTALLER[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 820.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]DEPLOYMENT CONTROL  //  CHANNEL 017[/color]"
fit_content = true
scroll_active = false

[node name="PackageLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 140.0
offset_right = 820.0
offset_bottom = 176.0
text = "PACKAGE  //  NONE"
fit_content = true
scroll_active = false

[node name="StateLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 196.0
offset_right = 820.0
offset_bottom = 230.0
bbcode_enabled = true
text = "[color=#d6aa48]STATE  //  IDLE[/color]"
fit_content = true
scroll_active = false

[node name="ProgressTrack" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 270.0
offset_right = 826.0
offset_bottom = 296.0
color = Color(0.0705882, 0.145098, 0.180392, 1)

[node name="ProgressFill" type="ColorRect" parent="ProgressTrack"]
unique_name_in_owner = true
layout_mode = 0
offset_right = 772.0
offset_bottom = 26.0
scale = Vector2(0, 1)
color = Color(0.196078, 0.847059, 1, 1)

[node name="ProgressLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 316.0
offset_right = 826.0
offset_bottom = 352.0
text = "0%"
fit_content = true
scroll_active = false

[node name="OperationLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 378.0
offset_right = 826.0
offset_bottom = 438.0
text = "WAITING FOR INSTALLATION PLAN"
scroll_active = false

[node name="ErrorLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 54.0
offset_top = 474.0
offset_right = 826.0
offset_bottom = 590.0
bbcode_enabled = true
text = "[color=#ff4f62]INSTALLATION FAILURE[/color]"
scroll_active = false
'@

$files["packages/017_installer/demo/installer_demo.gd"] = @'
class_name InstallerDemo
extends Control
## Demonstrates installation into user://hydra_demo.


#region Nodes

@onready var _panel: InstallerPanel = %InstallerPanel

#endregion


#region State

var _service: InstallerService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = InstallerService.new()
	_service.name = "InstallerService"
	add_child(_service)

	var configuration := InstallerConfiguration.new()
	configuration.installation_root = "user://hydra_demo"
	configuration.allow_overwrite = true

	var adapter := UserDirectoryInstallerAdapter.new(
		configuration.installation_root
	)

	_service.configure(configuration, adapter)
	_panel.bind_service(_service)

	var manifest := InstallationManifest.new()
	manifest.package_id = &"demo_package"
	manifest.display_name = "DEMO PACKAGE"
	manifest.version = "0.1.0"

	var operations: Array[InstallationOperation] = [
		InstallationOperation.new(
			InstallationOperation.Type.CREATE_DIRECTORY,
			"config"
		),
		InstallationOperation.new(
			InstallationOperation.Type.WRITE_TEXT_FILE,
			"config/demo.cfg",
			"[demo]\ninstalled=true\n",
			true
		),
	]

	var plan := InstallationPlan.new(
		EntityId.generate(),
		manifest,
		operations
	)

	_service.install(plan)

#endregion
'@

$files["packages/017_installer/demo/installer_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/017_installer/demo/installer_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/017_installer/scenes/installer_panel.tscn" id="2"]

[node name="InstallerDemo" type="Control"]
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

[node name="InstallerPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 520.0
offset_top = 230.0
offset_right = 1400.0
offset_bottom = 850.0
'@

$files["packages/017_installer/tests/unit/test_installation_operation.gd"] = @'
class_name InstallationOperationTest
extends RefCounted
## Provides installation operation validation tests.


#region Tests

static func run() -> void:
	var valid_operation := InstallationOperation.new(
		InstallationOperation.Type.WRITE_TEXT_FILE,
		"config/settings.cfg",
		"enabled=true"
	)

	assert(valid_operation.validate().is_success())

	var invalid_operation := InstallationOperation.new(
		InstallationOperation.Type.WRITE_TEXT_FILE,
		"../unsafe.txt",
		"unsafe"
	)

	assert(invalid_operation.validate().is_failure())

#endregion
'@

$files["packages/017_installer/tests/integration/test_user_directory_installer_adapter.gd"] = @'
class_name UserDirectoryInstallerAdapterTest
extends RefCounted
## Provides installer file-system adapter tests.


#region Tests

static func run() -> void:
	var adapter := UserDirectoryInstallerAdapter.new(
		"user://hydra_installer_test"
	)

	assert(
		adapter.create_directory("config").is_success()
	)
	assert(
		adapter.write_text_file(
			"config/test.txt",
			"HYDRA",
			true
		).is_success()
	)
	assert(adapter.file_exists("config/test.txt"))
	assert(adapter.rollback().is_success())

#endregion
'@

# =============================================================================
# PACKAGE 018 — BOOT LOADER
# =============================================================================

$files["packages/018_boot_loader/package.cfg"] = @'
[package]

id="018_boot_loader"
name="Boot Loader"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system",
	"005_fx_system",
	"013_diagnostics",
	"014_notification_center",
	"017_installer"
)
'@

$files["packages/018_boot_loader/README.md"] = @'
# Package 018 — Boot Loader

Boot Loader owns deterministic application startup, ordered boot steps,
progress reporting, failure handling and transition to the main HYDRA scene.

Boot Loader does not own feature-module business logic.

Each module contributes a BootStep implementation through the composition root.
'@

$files["packages/018_boot_loader/CHANGELOG.md"] = @'
# Boot Loader changelog

## [0.1.0] - 2026-07-18

### Added

- Added boot state definitions.
- Added boot-step contract.
- Added callable boot-step implementation.
- Added boot sequence aggregate.
- Added boot-loader service.
- Added boot progress panel.
- Added boot-loader scene.
- Added demo steps and tests.
'@

$files["packages/018_boot_loader/docs/architecture.md"] = @'
# Boot Loader architecture

Boot Loader executes registered steps in ascending order.

Every step returns Result.

A failed critical step stops startup.

A failed optional step is recorded and startup continues.

The final scene transition is performed only after all critical steps succeed.
'@

$files["packages/018_boot_loader/docs/boot-sequence.md"] = @'
# Boot sequence

Recommended startup order:

1. Validate configuration.
2. Initialize EventBus.
3. Initialize design and animation systems.
4. Initialize diagnostics.
5. Initialize feature services.
6. Validate installation state.
7. Load the main HUD scene.

Boot steps must remain deterministic and safe to retry.
'@

$files["packages/018_boot_loader/resources/boot_loader_configuration.gd"] = @'
class_name BootLoaderConfiguration
extends Resource
## Stores Boot Loader runtime configuration.


#region Scene transition

@export_group("Scene Transition")
@export_file("*.tscn") var target_scene_path: String = \
	"res://hud_scene.tscn"
@export_range(0.0, 10.0, 0.05) var completion_delay_seconds: float = 0.35

#endregion


#region Behavior

@export_group("Behavior")
@export var start_automatically: bool = true
@export var stop_on_critical_failure: bool = true
@export var allow_retry: bool = true
@export var change_scene_after_completion: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export var minimum_step_display_seconds: float = 0.05
@export var show_completed_steps: bool = true

#endregion
'@

$files["packages/018_boot_loader/resources/default_boot_loader_configuration.tres"] = @'
[gd_resource type="Resource" script_class="BootLoaderConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/018_boot_loader/resources/boot_loader_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
target_scene_path = "res://hud_scene.tscn"
completion_delay_seconds = 0.35
start_automatically = true
stop_on_critical_failure = true
allow_retry = true
change_scene_after_completion = true
minimum_step_display_seconds = 0.05
show_completed_steps = true
'@

$files["packages/018_boot_loader/scripts/domain/boot_state.gd"] = @'
class_name BootState
extends RefCounted
## Defines Boot Loader lifecycle states.


#region Values

enum Value {
	IDLE,
	VALIDATING,
	BOOTING,
	COMPLETED,
	FAILED,
	CANCELLED,
	TRANSITIONING,
}

#endregion


#region Public API

## Returns a stable boot-state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.IDLE:
			return &"idle"
		Value.VALIDATING:
			return &"validating"
		Value.BOOTING:
			return &"booting"
		Value.COMPLETED:
			return &"completed"
		Value.FAILED:
			return &"failed"
		Value.CANCELLED:
			return &"cancelled"
		Value.TRANSITIONING:
			return &"transitioning"
		_:
			return &"unknown"

#endregion
'@

$files["packages/018_boot_loader/scripts/contracts/boot_step.gd"] = @'
@abstract
class_name BootStep
extends RefCounted
## Defines one ordered Boot Loader operation.


#region Public API

## Returns a stable step identifier.
@abstract
func get_step_id() -> StringName


## Returns a human-readable step name.
@abstract
func get_display_name() -> String


## Returns the ascending execution order.
@abstract
func get_order() -> int


## Returns whether failure stops startup.
@abstract
func is_critical() -> bool


## Validates this step before startup.
func validate() -> Result:
	if get_step_id().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot step requires step_id."
			)
		)

	if get_display_name().strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot step requires display_name."
			)
		)

	return Result.success()


## Executes the boot step.
@abstract
func execute() -> Result

#endregion
'@

$files["packages/018_boot_loader/scripts/infrastructure/callable_boot_step.gd"] = @'
class_name CallableBootStep
extends BootStep
## Executes one Callable as a Boot Loader step.


#region State

var _step_id: StringName
var _display_name: String
var _order: int
var _critical: bool
var _operation: Callable

#endregion


#region Construction

func _init(
	step_id: StringName,
	display_name: String,
	order: int,
	critical: bool,
	operation: Callable
) -> void:
	_step_id = step_id
	_display_name = display_name.strip_edges()
	_order = order
	_critical = critical
	_operation = operation

#endregion


#region BootStep

func get_step_id() -> StringName:
	return _step_id


func get_display_name() -> String:
	return _display_name


func get_order() -> int:
	return _order


func is_critical() -> bool:
	return _critical


func validate() -> Result:
	var base_result := super()

	if base_result.is_failure():
		return base_result

	if not _operation.is_valid():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot step operation is invalid.",
				{&"step_id": _step_id}
			)
		)

	return Result.success()


func execute() -> Result:
	var response: Variant = _operation.call()

	if response is Result:
		return response as Result

	if response == null:
		return Result.success()

	return Result.success(response)

#endregion
'@

$files["packages/018_boot_loader/scripts/domain/boot_sequence.gd"] = @'
class_name BootSequence
extends AggregateRoot
## Owns ordered boot-step execution state.


#region Events

const EVENT_STATE_CHANGED: StringName = \
	&"hydra.boot.state_changed"
const EVENT_STEP_STARTED: StringName = \
	&"hydra.boot.step_started"
const EVENT_STEP_COMPLETED: StringName = \
	&"hydra.boot.step_completed"
const EVENT_STEP_FAILED: StringName = \
	&"hydra.boot.step_failed"

#endregion


#region State

var _steps: Array[BootStep] = []
var _state: BootState.Value = BootState.Value.IDLE
var _current_step_index: int = -1
var _completed_step_count: int = 0
var _failure: DomainError

#endregion


#region Construction

func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

func get_state() -> BootState.Value:
	return _state


func get_steps() -> Array[BootStep]:
	return _steps.duplicate()


func get_current_step_index() -> int:
	return _current_step_index


func get_completed_step_count() -> int:
	return _completed_step_count


func get_failure() -> DomainError:
	return _failure


func get_progress() -> float:
	if _steps.is_empty():
		return 1.0

	return float(_completed_step_count) / float(_steps.size())


func register_step(step: BootStep) -> Result:
	if _state != BootState.Value.IDLE:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Boot steps cannot be registered after startup."
			)
		)

	if step == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Boot step cannot be null."
			)
		)

	for existing_step in _steps:
		if existing_step.get_step_id() == step.get_step_id():
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_STATE,
					"Boot step is already registered.",
					{&"step_id": step.get_step_id()}
				)
			)

	_steps.append(step)
	_steps.sort_custom(
		func(left: BootStep, right: BootStep) -> bool:
			return left.get_order() < right.get_order()
	)

	return Result.success()


func validate_sequence() -> Result:
	_state = BootState.Value.VALIDATING
	_record_state_event()

	if _steps.is_empty():
		return fail(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Boot sequence contains no steps."
			)
		)

	for step in _steps:
		var result := step.validate()

		if result.is_failure():
			return fail(result.get_error())

	_state = BootState.Value.IDLE
	_record_state_event()

	return Result.success()


func start() -> Result:
	if _state != BootState.Value.IDLE:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Boot sequence cannot start from current state."
			)
		)

	_state = BootState.Value.BOOTING
	_current_step_index = -1
	_completed_step_count = 0
	_failure = null
	_record_state_event()

	return Result.success()


func start_step(index: int) -> Result:
	if index < 0 or index >= _steps.size():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot step index is invalid."
			)
		)

	_current_step_index = index

	var step := _steps[index]

	_record_domain_event(
		DomainEvent.new(
			EVENT_STEP_STARTED,
			{
				&"step_id": step.get_step_id(),
				&"index": index,
			}
		)
	)

	return Result.success(step)


func complete_step(step: BootStep) -> void:
	_completed_step_count += 1
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_STEP_COMPLETED,
			{
				&"step_id": step.get_step_id(),
				&"completed": _completed_step_count,
				&"total": _steps.size(),
			}
		)
	)


func record_optional_failure(
	step: BootStep,
	error: DomainError
) -> void:
	_completed_step_count += 1

	_record_domain_event(
		DomainEvent.new(
			EVENT_STEP_FAILED,
			{
				&"step_id": step.get_step_id(),
				&"critical": false,
				&"error": error.to_dictionary(),
			}
		)
	)


func complete() -> Result:
	_state = BootState.Value.COMPLETED
	_record_state_event()

	return Result.success()


func transition() -> Result:
	if _state != BootState.Value.COMPLETED:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Boot sequence is not complete."
			)
		)

	_state = BootState.Value.TRANSITIONING
	_record_state_event()

	return Result.success()


func fail(error: DomainError) -> Result:
	_failure = error
	_state = BootState.Value.FAILED
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_STEP_FAILED,
			{
				&"critical": true,
				&"error": error.to_dictionary(),
			}
		)
	)

	_record_state_event()

	return Result.failure(error)

#endregion


#region Private methods

func _record_state_event() -> void:
	_record_domain_event(
		DomainEvent.new(
			EVENT_STATE_CHANGED,
			{
				&"state": BootState.to_string_name(_state),
				&"progress": get_progress(),
			}
		)
	)

#endregion
'@

$files["packages/018_boot_loader/scripts/application/boot_loader_service.gd"] = @'
class_name BootLoaderService
extends Node
## Executes BootSequence and transitions to the target scene.


#region Signals

signal boot_started(sequence: BootSequence)
signal step_started(
	step: BootStep,
	index: int,
	total: int
)
signal step_completed(
	step: BootStep,
	progress: float
)
signal step_failed(
	step: BootStep,
	error: DomainError,
	critical: bool
)
signal boot_completed(sequence: BootSequence)
signal boot_failed(
	sequence: BootSequence,
	error: DomainError
)
signal scene_transition_started(scene_path: String)

#endregion


#region State

var _configuration: BootLoaderConfiguration
var _sequence: BootSequence
var _running: bool = false

#endregion


#region Public API

## Configures Boot Loader.
func configure(
	configuration: BootLoaderConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Boot Loader configuration cannot be null."
			)
		)

	if configuration.target_scene_path.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Boot Loader target scene path cannot be empty."
			)
		)

	_configuration = configuration
	_sequence = BootSequence.new(EntityId.generate())

	return Result.success()


## Registers a boot step.
func register_step(step: BootStep) -> Result:
	if _sequence == null:
		return _not_configured()

	return _sequence.register_step(step)


## Starts the complete boot sequence.
func start_boot() -> Result:
	if _configuration == null or _sequence == null:
		return _not_configured()

	if _running:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Boot sequence is already running."
			)
		)

	var validation_result := _sequence.validate_sequence()

	if validation_result.is_failure():
		boot_failed.emit(
			_sequence,
			validation_result.get_error()
		)
		return validation_result

	var start_result := _sequence.start()

	if start_result.is_failure():
		return start_result

	_running = true
	boot_started.emit(_sequence)
	_publish_events()

	var steps := _sequence.get_steps()

	for index in steps.size():
		var step := steps[index]

		_sequence.start_step(index)
		_publish_events()
		step_started.emit(step, index, steps.size())

		var step_result := step.execute()

		if step_result.is_failure():
			step_failed.emit(
				step,
				step_result.get_error(),
				step.is_critical()
			)

			if (
				step.is_critical()
				and _configuration.stop_on_critical_failure
			):
				_sequence.fail(step_result.get_error())
				_publish_events()
				_running = false
				boot_failed.emit(
					_sequence,
					step_result.get_error()
				)

				return step_result

			_sequence.record_optional_failure(
				step,
				step_result.get_error()
			)
		else:
			_sequence.complete_step(step)

		_publish_events()
		step_completed.emit(
			step,
			_sequence.get_progress()
		)

		if _configuration.minimum_step_display_seconds > 0.0:
			await get_tree().create_timer(
				_configuration.minimum_step_display_seconds
			).timeout

	_sequence.complete()
	_publish_events()
	_running = false
	boot_completed.emit(_sequence)

	if _configuration.change_scene_after_completion:
		await get_tree().create_timer(
			_configuration.completion_delay_seconds
		).timeout

		return _transition_to_target_scene()

	return Result.success(_sequence)


## Returns current boot sequence.
func get_sequence() -> BootSequence:
	return _sequence

#endregion


#region Private methods

func _transition_to_target_scene() -> Result:
	var scene_path := _configuration.target_scene_path

	if not ResourceLoader.exists(scene_path):
		var error := DomainError.new(
			HydraErrors.INVALID_ARGUMENT,
			"Boot target scene does not exist.",
			{&"scene_path": scene_path}
		)

		boot_failed.emit(_sequence, error)

		return Result.failure(error)

	var transition_result := _sequence.transition()

	if transition_result.is_failure():
		return transition_result

	_publish_events()
	scene_transition_started.emit(scene_path)

	var error := get_tree().change_scene_to_file(scene_path)

	if error != OK:
		var scene_error := DomainError.new(
			HydraErrors.UNKNOWN,
			"Boot Loader failed to change scene.",
			{
				&"scene_path": scene_path,
				&"error": error,
			}
		)

		boot_failed.emit(_sequence, scene_error)

		return Result.failure(scene_error)

	return Result.success()


func _publish_events() -> void:
	var event_bus := get_node_or_null("/root/EventBus")
	var events := _sequence.pull_domain_events()

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Boot Loader is not configured."
		)
	)

#endregion
'@

$files["packages/018_boot_loader/scripts/presentation/boot_progress_panel.gd"] = @'
class_name BootProgressPanel
extends PanelBase
## Displays HYDRA startup progress.


#region Nodes

@onready var _state_label: RichTextLabel = %StateLabel
@onready var _step_label: RichTextLabel = %StepLabel
@onready var _progress_fill: ColorRect = %ProgressFill
@onready var _progress_label: RichTextLabel = %ProgressLabel
@onready var _log_output: RichTextLabel = %LogOutput
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: BootLoaderService

#endregion


#region Public API

## Binds this panel to BootLoaderService.
func bind_service(service: BootLoaderService) -> void:
	assert(service != null, "Boot Loader service cannot be null.")

	_disconnect_service()
	_service = service

	_service.boot_started.connect(_on_boot_started)
	_service.step_started.connect(_on_step_started)
	_service.step_completed.connect(_on_step_completed)
	_service.step_failed.connect(_on_step_failed)
	_service.boot_completed.connect(_on_boot_completed)
	_service.boot_failed.connect(_on_boot_failed)
	_service.scene_transition_started.connect(
		_on_scene_transition_started
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.boot_started.is_connected(_on_boot_started):
		_service.boot_started.disconnect(_on_boot_started)

	if _service.step_started.is_connected(_on_step_started):
		_service.step_started.disconnect(_on_step_started)

	if _service.step_completed.is_connected(_on_step_completed):
		_service.step_completed.disconnect(_on_step_completed)

	if _service.step_failed.is_connected(_on_step_failed):
		_service.step_failed.disconnect(_on_step_failed)

	if _service.boot_completed.is_connected(_on_boot_completed):
		_service.boot_completed.disconnect(_on_boot_completed)

	if _service.boot_failed.is_connected(_on_boot_failed):
		_service.boot_failed.disconnect(_on_boot_failed)

	if _service.scene_transition_started.is_connected(
		_on_scene_transition_started
	):
		_service.scene_transition_started.disconnect(
			_on_scene_transition_started
		)


func _on_boot_started(
	_sequence: BootSequence
) -> void:
	_error_label.visible = false
	_log_output.text = ""
	_state_label.text = "STATE  //  BOOTING"
	_set_progress(0.0)
	_append_log("BOOT SEQUENCE INITIALIZED", "#32d8ff")


func _on_step_started(
	step: BootStep,
	index: int,
	total: int
) -> void:
	_step_label.text = (
		"STEP %d / %d  //  %s"
		% [
			index + 1,
			total,
			step.get_display_name(),
		]
	)
	_append_log(
		"START  //  %s" % step.get_display_name(),
		"#d6aa48"
	)


func _on_step_completed(
	step: BootStep,
	progress: float
) -> void:
	_set_progress(progress)
	_append_log(
		"OK     //  %s" % step.get_display_name(),
		"#55f2a3"
	)


func _on_step_failed(
	step: BootStep,
	error: DomainError,
	critical: bool
) -> void:
	var severity := "CRITICAL" if critical else "OPTIONAL"
	_append_log(
		"%s  //  %s  //  %s"
		% [
			severity,
			step.get_display_name(),
			error.get_message(),
		],
		"#ff4f62"
	)


func _on_boot_completed(
	_sequence: BootSequence
) -> void:
	_state_label.text = "STATE  //  COMPLETED"
	_step_label.text = "ALL CRITICAL SYSTEMS OPERATIONAL"
	_set_progress(1.0)
	_append_log("BOOT SEQUENCE COMPLETED", "#55f2a3")


func _on_boot_failed(
	_sequence: BootSequence,
	error: DomainError
) -> void:
	_state_label.text = "STATE  //  FAILED"
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]BOOT FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()


func _on_scene_transition_started(
	scene_path: String
) -> void:
	_state_label.text = "STATE  //  TRANSITIONING"
	_append_log(
		"LOADING  //  %s" % scene_path,
		"#32d8ff"
	)


func _set_progress(progress: float) -> void:
	var normalized := clampf(progress, 0.0, 1.0)
	_progress_fill.scale.x = normalized
	_progress_label.text = "%d%%" % int(normalized * 100.0)


func _append_log(
	message: String,
	color: String
) -> void:
	_log_output.append_text(
		"[color=%s]%s[/color]\n"
		% [
			color,
			message,
		]
	)
	_log_output.scroll_to_line(
		_log_output.get_line_count()
	)

#endregion
'@

$files["packages/018_boot_loader/scripts/presentation/boot_loader_screen.gd"] = @'
class_name BootLoaderScreen
extends Control
## Composition root for the HYDRA boot screen.


#region Resources

@export var configuration: BootLoaderConfiguration

#endregion


#region Nodes

@onready var _panel: BootProgressPanel = %BootProgressPanel

#endregion


#region State

var _service: BootLoaderService

#endregion


#region Lifecycle

func _ready() -> void:
	if configuration == null:
		configuration = BootLoaderConfiguration.new()

	_service = BootLoaderService.new()
	_service.name = "BootLoaderService"
	add_child(_service)

	var result := _service.configure(configuration)

	if result.is_failure():
		push_error(result.get_error().get_message())
		return

	_register_default_steps()
	_panel.bind_service(_service)

	if configuration.start_automatically:
		_service.start_boot()


#region Private methods

func _register_default_steps() -> void:
	_service.register_step(
		CallableBootStep.new(
			&"validate_runtime",
			"VALIDATE RUNTIME",
			10,
			true,
			_validate_runtime
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"validate_project",
			"VALIDATE PROJECT CONFIGURATION",
			20,
			true,
			_validate_project
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"initialize_services",
			"INITIALIZE CORE SERVICES",
			30,
			true,
			_initialize_services
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"run_diagnostics",
			"RUN STARTUP DIAGNOSTICS",
			40,
			false,
			_run_diagnostics
		)
	)


func _validate_runtime() -> Result:
	if Engine.get_version_info().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Godot runtime information is unavailable."
			)
		)

	return Result.success()


func _validate_project() -> Result:
	if not ResourceLoader.exists(
		configuration.target_scene_path
	):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Configured target scene does not exist.",
				{
					&"scene_path":
						configuration.target_scene_path,
				}
			)
		)

	return Result.success()


func _initialize_services() -> Result:
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"EventBus autoload is unavailable."
			)
		)

	return Result.success()


func _run_diagnostics() -> Result:
	var diagnostics := get_node_or_null("/root/Diagnostics")

	if diagnostics == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Diagnostics autoload is unavailable."
			)
		)

	return diagnostics.run_all()

#endregion
'@

$files["packages/018_boot_loader/scenes/boot_progress_panel.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/018_boot_loader/scripts/presentation/boot_progress_panel.gd" id="1"]

[node name="BootProgressPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 1040.0
offset_bottom = 620.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"boot_progress_panel"
starts_open = true

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00392157, 0.0156863, 0.027451, 0.98)

[node name="HeaderAccent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 28.0
offset_top = 24.0
offset_right = 34.0
offset_bottom = 94.0
color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 18.0
offset_right = 900.0
offset_bottom = 64.0
bbcode_enabled = true
text = "[font_size=32][color=#32d8ff]HYDRA AI HOME OS[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 66.0
offset_right = 900.0
offset_bottom = 100.0
bbcode_enabled = true
text = "[color=#6e8794]SECURE BOOT SEQUENCE  //  CHANNEL 018[/color]"
fit_content = true
scroll_active = false

[node name="StateLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 132.0
offset_right = 480.0
offset_bottom = 166.0
bbcode_enabled = true
text = "[color=#d6aa48]STATE  //  IDLE[/color]"
fit_content = true
scroll_active = false

[node name="StepLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 180.0
offset_right = 986.0
offset_bottom = 218.0
text = "AWAITING BOOT SEQUENCE"
fit_content = true
scroll_active = false

[node name="ProgressTrack" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 242.0
offset_right = 986.0
offset_bottom = 270.0
color = Color(0.0705882, 0.145098, 0.180392, 1)

[node name="ProgressFill" type="ColorRect" parent="ProgressTrack"]
unique_name_in_owner = true
layout_mode = 0
offset_right = 932.0
offset_bottom = 28.0
scale = Vector2(0, 1)
color = Color(0.196078, 0.847059, 1, 1)

[node name="ProgressLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 286.0
offset_right = 986.0
offset_bottom = 320.0
text = "0%"
fit_content = true
scroll_active = false

[node name="LogFrame" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 340.0
offset_right = 986.0
offset_bottom = 530.0
color = Color(0.027451, 0.0901961, 0.133333, 0.72)

[node name="LogOutput" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 72.0
offset_top = 354.0
offset_right = 968.0
offset_bottom = 516.0
bbcode_enabled = true
text = "[color=#40515b]BOOT LOG INITIALIZED[/color]"
scroll_active = true

[node name="ErrorLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 54.0
offset_top = 548.0
offset_right = 986.0
offset_bottom = 608.0
bbcode_enabled = true
text = "[color=#ff4f62]BOOT FAILURE[/color]"
scroll_active = false
'@

$files["packages/018_boot_loader/scenes/boot_loader.tscn"] = @'
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://packages/018_boot_loader/scripts/presentation/boot_loader_screen.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/018_boot_loader/scenes/boot_progress_panel.tscn" id="2"]
[ext_resource type="Resource" path="res://packages/018_boot_loader/resources/default_boot_loader_configuration.tres" id="3"]

[node name="BootLoader" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
configuration = ExtResource("3")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00196078, 0.00784314, 0.0117647, 1)

[node name="BootProgressPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 440.0
offset_top = 230.0
offset_right = 1480.0
offset_bottom = 850.0
'@

$files["packages/018_boot_loader/demo/boot_loader_demo.gd"] = @'
class_name BootLoaderDemo
extends Control
## Demonstrates Boot Loader without changing the current scene.


#region Nodes

@onready var _panel: BootProgressPanel = %BootProgressPanel

#endregion


#region State

var _service: BootLoaderService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = BootLoaderService.new()
	_service.name = "BootLoaderService"
	add_child(_service)

	var configuration := BootLoaderConfiguration.new()
	configuration.change_scene_after_completion = false
	configuration.minimum_step_display_seconds = 0.25

	_service.configure(configuration)
	_panel.bind_service(_service)

	_service.register_step(
		CallableBootStep.new(
			&"demo_core",
			"INITIALIZE CORE",
			10,
			true,
			func() -> Result:
				return Result.success()
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"demo_services",
			"INITIALIZE SERVICES",
			20,
			true,
			func() -> Result:
				return Result.success()
		)
	)
	_service.register_step(
		CallableBootStep.new(
			&"demo_optional",
			"CHECK OPTIONAL LINK",
			30,
			false,
			func() -> Result:
				return Result.failure(
					DomainError.new(
						HydraErrors.SERVICE_NOT_FOUND,
						"Optional demo service is offline."
					)
				)
		)
	)

	_service.start_boot()

#endregion
'@

$files["packages/018_boot_loader/demo/boot_loader_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/018_boot_loader/demo/boot_loader_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/018_boot_loader/scenes/boot_progress_panel.tscn" id="2"]

[node name="BootLoaderDemo" type="Control"]
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
color = Color(0.00196078, 0.00784314, 0.0117647, 1)

[node name="BootProgressPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 440.0
offset_top = 230.0
offset_right = 1480.0
offset_bottom = 850.0
'@

$files["packages/018_boot_loader/tests/unit/test_boot_sequence.gd"] = @'
class_name BootSequenceTest
extends RefCounted
## Provides BootSequence domain tests.


#region Tests

static func run() -> void:
	var sequence := BootSequence.new(
		EntityId.generate()
	)
	var step := CallableBootStep.new(
		&"test_step",
		"TEST STEP",
		10,
		true,
		func() -> Result:
			return Result.success()
	)

	assert(sequence.register_step(step).is_success())
	assert(sequence.validate_sequence().is_success())
	assert(sequence.start().is_success())
	assert(sequence.start_step(0).is_success())

	sequence.complete_step(step)

	assert(sequence.get_completed_step_count() == 1)
	assert(is_equal_approx(sequence.get_progress(), 1.0))
	assert(sequence.complete().is_success())

#endregion
'@

$files["packages/018_boot_loader/tests/integration/test_boot_loader_service.gd"] = @'
class_name BootLoaderServiceTest
extends RefCounted
## Provides Boot Loader service composition tests.


#region Tests

static func run() -> void:
	var service := BootLoaderService.new()
	var configuration := BootLoaderConfiguration.new()
	configuration.change_scene_after_completion = false

	assert(service.configure(configuration).is_success())

	var step := CallableBootStep.new(
		&"test",
		"TEST",
		10,
		true,
		func() -> Result:
			return Result.success()
	)

	assert(service.register_step(step).is_success())

#endregion
'@

# =============================================================================
# AUTOLOADS AND DOCUMENTATION
# =============================================================================

$files["autoload/android_platform.gd"] = @'
extends AndroidPlatformService
## Global Android platform service.
##
## Runtime composition must configure a platform adapter.
'@

$files["autoload/installer.gd"] = @'
extends InstallerService
## Global Installer application service.
##
## Runtime composition must configure a restricted file-system adapter.
'@

$files["autoload/boot_loader.gd"] = @'
extends BootLoaderService
## Global Boot Loader application service.
##
## Runtime composition must configure boot steps before startup.
'@

$files["docs/package-dependencies-016-018.md"] = @'
# Package dependencies 016–018

```text
016_android
├── 001_foundation
├── 002_design_system
├── 003_widget_library
├── 013_diagnostics
└── 014_notification_center

017_installer
├── 001_foundation
├── 002_design_system
├── 003_widget_library
├── 013_diagnostics
└── 014_notification_center

018_boot_loader
├── 001_foundation
├── 002_design_system
├── 003_widget_library
├── 004_animation_system
├── 005_fx_system
├── 013_diagnostics
├── 014_notification_center
└── 017_installer
'@
Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing packages 016-018..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

Assert-GeneratedFiles -FileMap $files

Write-Host ""
Write-Host "Packages 016-018 installed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Optional autoloads:" -ForegroundColor Cyan
Write-Host "AndroidPlatform res://autoload/android_platform.gd"
Write-Host "Installer res://autoload/installer.gd"
Write-Host "BootLoader res://autoload/boot_loader.gd"
Write-Host ""
Write-Host "Boot scene:" -ForegroundColor Cyan
Write-Host "res://packages/018_boot_loader/scenes/boot_loader.tscn"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(platform): implement packages 016-018"'
Write-Host "git push"