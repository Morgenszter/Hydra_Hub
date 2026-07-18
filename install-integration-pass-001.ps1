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

function Set-ProjectSetting {
    param(
        [Parameter(Mandatory)]
        [string]$Section,

        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Value
    )

    $projectPath = Join-Path $RepositoryRoot "project.godot"
    $content = [System.IO.File]::ReadAllText($projectPath)

    $sectionPattern = "(?ms)^\[$([regex]::Escape($Section))\]\s*$"
    $keyPattern = "(?m)^$([regex]::Escape($Key))=.*$"

    if ($content -notmatch $sectionPattern) {
        $content = $content.TrimEnd() + "`r`n`r`n[$Section]`r`n$Key=$Value`r`n"
    }
    else {
        $sectionStart = [regex]::Match(
            $content,
            $sectionPattern
        ).Index

        $nextSection = [regex]::Match(
            $content.Substring($sectionStart + 1),
            "(?m)^\[.+\]\s*$"
        )

        if ($nextSection.Success) {
            $sectionEnd = $sectionStart + 1 + $nextSection.Index
        }
        else {
            $sectionEnd = $content.Length
        }

        $beforeSection = $content.Substring(0, $sectionStart)
        $sectionContent = $content.Substring(
            $sectionStart,
            $sectionEnd - $sectionStart
        )
        $afterSection = $content.Substring($sectionEnd)

        if ($sectionContent -match $keyPattern) {
            $sectionContent = [regex]::Replace(
                $sectionContent,
                $keyPattern,
                "$Key=$Value"
            )
        }
        else {
            $sectionContent = $sectionContent.TrimEnd() +
                "`r`n$Key=$Value`r`n"
        }

        $content = $beforeSection + $sectionContent + $afterSection
    }

    [System.IO.File]::WriteAllText(
        $projectPath,
        $content,
        $utf8WithoutBom
    )
}

Assert-HydraRepository

$files = [ordered]@{}

$files["core/runtime/hydra_runtime.gd"] = @'
class_name HydraRuntime
extends Node
## Production composition root for HYDRA AI HOME OS.
##
## HydraRuntime configures application services, adapters and cross-module
## integrations. Feature modules remain isolated from infrastructure details.


#region Signals

signal runtime_initialization_started()
signal runtime_initialization_completed()
signal runtime_initialization_failed(error: DomainError)

#endregion


#region State

var _initialized: bool = false
var _initialization_error: DomainError

#endregion


#region Lifecycle

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var result := initialize_runtime()

	if result.is_failure():
		push_error(result.get_error().get_message())


#endregion


#region Public API

## Initializes all configured HYDRA services.
func initialize_runtime() -> Result:
	if _initialized:
		return Result.success()

	runtime_initialization_started.emit()

	var steps: Array[Callable] = [
		_configure_theme,
		_configure_diagnostics,
		_configure_notifications,
		_configure_device_hub,
		_configure_ai_system,
		_configure_automation,
		_configure_debug_tools,
		_configure_android_platform,
	]

	for step in steps:
		var result: Result = step.call()

		if result.is_failure():
			_initialization_error = result.get_error()
			runtime_initialization_failed.emit(
				_initialization_error
			)
			return result

	_initialized = true
	runtime_initialization_completed.emit()

	return Result.success()


## Returns whether runtime composition completed successfully.
func is_initialized() -> bool:
	return _initialized


## Returns the most recent initialization error.
func get_initialization_error() -> DomainError:
	return _initialization_error

#endregion


#region Composition

func _configure_theme() -> Result:
	var theme_manager := get_node_or_null(
		"/root/ThemeManager"
	)

	if theme_manager == null:
		return _missing_service(&"ThemeManager")

	return Result.success()


func _configure_diagnostics() -> Result:
	var diagnostics := get_node_or_null(
		"/root/Diagnostics"
	) as DiagnosticsService

	if diagnostics == null:
		return _missing_service(&"Diagnostics")

	var configuration := DiagnosticsConfiguration.new()
	var configure_result := diagnostics.configure(
		configuration
	)

	if configure_result.is_failure():
		return configure_result

	var probe_result := diagnostics.register_probe(
		RuntimeDiagnosticProbe.new()
	)

	if (
		probe_result.is_failure()
		and probe_result.get_error().get_code()
			!= HydraErrors.SERVICE_ALREADY_REGISTERED
	):
		return probe_result

	return diagnostics.start()


func _configure_notifications() -> Result:
	var notification_center := get_node_or_null(
		"/root/NotificationCenter"
	) as NotificationCenterService

	if notification_center == null:
		return _missing_service(&"NotificationCenter")

	var configuration := NotificationConfiguration.new()
	var repository := InMemoryNotificationRepository.new()

	return notification_center.configure(
		configuration,
		repository
	)


func _configure_device_hub() -> Result:
	var device_hub := get_node_or_null(
		"/root/DeviceHub"
	) as DeviceHubService

	if device_hub == null:
		return _missing_service(&"DeviceHub")

	var configuration := DeviceHubConfiguration.new()
	var configure_result := device_hub.configure(
		configuration
	)

	if configure_result.is_failure():
		return configure_result

	var provider_result := device_hub.register_provider(
		DemoDeviceProvider.new()
	)

	if (
		provider_result.is_failure()
		and provider_result.get_error().get_code()
			!= HydraErrors.SERVICE_ALREADY_REGISTERED
	):
		return provider_result

	return device_hub.start()


func _configure_ai_system() -> Result:
	var ai_system := get_node_or_null(
		"/root/AiSystem"
	) as AiSystemService

	if ai_system == null:
		return _missing_service(&"AiSystem")

	var configuration := AiSystemConfiguration.new()
	var configure_result := ai_system.configure(
		configuration
	)

	if configure_result.is_failure():
		return configure_result

	var provider_result := ai_system.register_provider(
		LocalDemoAiProvider.new()
	)

	if (
		provider_result.is_failure()
		and provider_result.get_error().get_code()
			!= HydraErrors.SERVICE_ALREADY_REGISTERED
	):
		return provider_result

	if ai_system.get_active_conversation() == null:
		return ai_system.create_conversation(
			"HYDRA PRIMARY SESSION"
		)

	return Result.success()


func _configure_automation() -> Result:
	var automation := get_node_or_null(
		"/root/Automation"
	) as AutomationService

	if automation == null:
		return _missing_service(&"Automation")

	var configuration := AutomationConfiguration.new()
	var repository := InMemoryAutomationRuleRepository.new()

	var configure_result := automation.configure(
		configuration,
		repository
	)

	if configure_result.is_failure():
		return configure_result

	var executor_result := automation.register_executor(
		DemoAutomationActionExecutor.new()
	)

	if (
		executor_result.is_failure()
		and executor_result.get_error().get_code()
			!= HydraErrors.SERVICE_ALREADY_REGISTERED
	):
		return executor_result

	return automation.start()


func _configure_debug_tools() -> Result:
	var debug_tools := get_node_or_null(
		"/root/DebugTools"
	) as DebugToolsService

	if debug_tools == null:
		return _missing_service(&"DebugTools")

	var configuration := DebugToolsConfiguration.new()
	var registry := DebugCommandRegistry.new()

	registry.register_command(
		HelpDebugCommand.new(registry)
	)
	registry.register_command(
		RuntimeDebugCommand.new()
	)
	registry.register_command(
		ClearDebugCommand.new()
	)

	var configure_result := debug_tools.configure(
		configuration,
		registry
	)

	if configure_result.is_failure():
		return configure_result

	if configuration.enabled:
		return debug_tools.start()

	return Result.success()


func _configure_android_platform() -> Result:
	var android_platform := get_node_or_null(
		"/root/AndroidPlatform"
	) as AndroidPlatformService

	if android_platform == null:
		return _missing_service(&"AndroidPlatform")

	var configuration := AndroidConfiguration.new()
	var adapter: AndroidPlatformPort

	if OS.get_name() == "Android":
		adapter = AndroidRuntimeAdapter.new()
	else:
		adapter = NullAndroidPlatformAdapter.new()

	var configure_result := android_platform.configure(
		configuration,
		adapter
	)

	if configure_result.is_failure():
		return configure_result

	return android_platform.initialize_platform()

#endregion


#region Private methods

func _missing_service(
	service_id: StringName
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.SERVICE_NOT_FOUND,
			"Required runtime service is unavailable.",
			{
				&"service_id": service_id,
			}
		)
	)

#endregion
'@

$files["autoload/hydra_runtime.gd"] = @'
extends HydraRuntime
## Global production composition root for HYDRA AI HOME OS.
'@

$files["core/runtime/runtime_notification_bridge.gd"] = @'
class_name RuntimeNotificationBridge
extends Node
## Converts selected domain events into user-facing notifications.


#region State

var _event_bus: Node
var _notification_center: NotificationCenterService

#endregion


#region Lifecycle

func _ready() -> void:
	_event_bus = get_node_or_null("/root/EventBus")
	_notification_center = get_node_or_null(
		"/root/NotificationCenter"
	) as NotificationCenterService

	if _event_bus == null or _notification_center == null:
		return

	if _event_bus.has_signal("event_published"):
		_event_bus.event_published.connect(
			_on_event_published
		)

#endregion


#region Event handling

func _on_event_published(event: DomainEvent) -> void:
	if event == null:
		return

	match event.get_event_name():
		&"hydra.device.connection_changed":
			_notify_device_connection(event)

		&"hydra.automation.execution.failed":
			_notify_automation_failure(event)

		&"hydra.ai.conversation.execution_failed":
			_notify_ai_failure(event)

		&"hydra.boot.step_failed":
			_notify_boot_failure(event)

#endregion


#region Notification mapping

func _notify_device_connection(event: DomainEvent) -> void:
	var current_state := String(
		event.get_payload_value(
			&"current_state",
			&"unknown"
		)
	)

	if current_state != "offline" and current_state != "error":
		return

	_submit(
		&"device_hub",
		&"device",
		"DEVICE LINK DEGRADED",
		"Device %s entered state %s."
		% [
			event.get_payload_value(
				&"device_id",
				&"unknown"
			),
			current_state.to_upper(),
		],
		NotificationPriority.Value.HIGH
	)


func _notify_automation_failure(event: DomainEvent) -> void:
	_submit(
		&"automation",
		&"automation",
		"AUTOMATION FAILURE",
		"Rule %s failed during execution."
		% event.get_payload_value(
			&"rule_id",
			&"unknown"
		),
		NotificationPriority.Value.URGENT
	)


func _notify_ai_failure(_event: DomainEvent) -> void:
	_submit(
		&"ai_system",
		&"ai",
		"AI LINK FAILURE",
		"The active AI request failed.",
		NotificationPriority.Value.HIGH
	)


func _notify_boot_failure(_event: DomainEvent) -> void:
	_submit(
		&"boot_loader",
		&"system",
		"BOOT SEQUENCE FAILURE",
		"A startup component reported a failure.",
		NotificationPriority.Value.CRITICAL
	)


func _submit(
	source_id: StringName,
	category: StringName,
	title: String,
	message: String,
	priority: NotificationPriority.Value
) -> void:
	if _notification_center == null:
		return

	_notification_center.notify(
		NotificationRequest.new(
			source_id,
			category,
			title,
			message,
			priority,
			10.0
		)
	)

#endregion
'@

$files["autoload/runtime_notification_bridge.gd"] = @'
extends RuntimeNotificationBridge
## Global bridge between EventBus and Notification Center.
'@

$files["core/runtime/runtime_health_bridge.gd"] = @'
class_name RuntimeHealthBridge
extends Node
## Propagates diagnostics state to Final HUD after shell startup.


#region State

var _diagnostics: DiagnosticsService
var _final_hud_service: FinalHudService

#endregion


#region Lifecycle

func _ready() -> void:
	_diagnostics = get_node_or_null(
		"/root/Diagnostics"
	) as DiagnosticsService

	if _diagnostics == null:
		return

	_diagnostics.health_state_changed.connect(
		_on_health_state_changed
	)

#endregion


#region Public API

## Attaches the active Final HUD service.
func attach_final_hud_service(
	service: FinalHudService
) -> void:
	_final_hud_service = service

#endregion


#region Event handling

func _on_health_state_changed(
	_previous_state: SystemHealthState.Value,
	current_state: SystemHealthState.Value
) -> void:
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	event_bus.publish(
		DomainEvent.new(
			&"hydra.runtime.health_changed",
			{
				&"state":
					SystemHealthState.to_string_name(
						current_state
					),
			}
		)
	)

#endregion
'@

$files["autoload/runtime_health_bridge.gd"] = @'
extends RuntimeHealthBridge
## Global diagnostics integration bridge.
'@

$files["core/runtime/runtime_smoke_test.gd"] = @'
class_name RuntimeSmokeTest
extends RefCounted
## Executes lightweight runtime composition checks.


#region Public API

## Returns Result containing all verified service identifiers.
static func run(tree: SceneTree) -> Result:
	if tree == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Runtime smoke test requires SceneTree."
			)
		)

	var required_services: PackedStringArray = [
		"EventBus",
		"ThemeManager",
		"AnimationManager",
		"FxController",
		"Diagnostics",
		"NotificationCenter",
		"DeviceHub",
		"AiSystem",
		"Automation",
		"DebugTools",
		"AndroidPlatform",
		"HydraRuntime",
	]

	var verified := PackedStringArray()

	for service_name in required_services:
		var node := tree.root.get_node_or_null(
			NodePath(service_name)
		)

		if node == null:
			return Result.failure(
				DomainError.new(
					HydraErrors.SERVICE_NOT_FOUND,
					"Runtime smoke test failed.",
					{
						&"service_id": service_name,
					}
				)
			)

		verified.append(service_name)

	return Result.success(verified)

#endregion
'@

$files["core/runtime/runtime_bootstrap_report.gd"] = @'
class_name RuntimeBootstrapReport
extends RefCounted
## Creates a structured runtime bootstrap report.


#region Public API

## Creates a bootstrap report dictionary.
static func create(tree: SceneTree) -> Dictionary:
	var report: Dictionary[StringName, Variant] = {
		&"timestamp_unix_ms": int(
			Time.get_unix_time_from_system() * 1000.0
		),
		&"godot_version": Engine.get_version_info(),
		&"platform": OS.get_name(),
		&"debug_build": OS.is_debug_build(),
		&"services": {},
	}

	var service_names: PackedStringArray = [
		"EventBus",
		"ThemeManager",
		"AnimationManager",
		"FxController",
		"Diagnostics",
		"NotificationCenter",
		"DeviceHub",
		"AiSystem",
		"Automation",
		"DebugTools",
		"AndroidPlatform",
		"HydraRuntime",
	]

	var services: Dictionary[StringName, bool] = {}

	for service_name in service_names:
		services[StringName(service_name)] = (
			tree.root.get_node_or_null(
				NodePath(service_name)
			) != null
		)

	report[&"services"] = services

	return report

#endregion
'@

$files["core/runtime/tests/test_runtime_smoke_test.gd"] = @'
class_name RuntimeSmokeTestTest
extends RefCounted
## Provides RuntimeSmokeTest contract tests.


#region Tests

static func run(tree: SceneTree) -> void:
	var result := RuntimeSmokeTest.run(tree)

	assert(result.is_success())
	assert(
		not (result.get_value() as PackedStringArray).is_empty()
	)

#endregion
'@

$files["docs/runtime-composition.md"] = @'
# Runtime composition

HydraRuntime is the production composition root.

Configured services:

```text
EventBus
ThemeManager
AnimationManager
FxController
Diagnostics
NotificationCenter
DeviceHub
AiSystem
Automation
DebugTools
AndroidPlatform
RuntimeNotificationBridge
RuntimeHealthBridge
'@

foreach ($entry in $files.GetEnumerator()) {
    Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

$autoloads = [ordered]@{
"EventBus" = '"*res://autoload/event_bus.gd"'
"ThemeManager" = '"*res://autoload/theme_manager.gd"'
"AnimationManager" = '"*res://autoload/animation_manager.gd"'
"FxController" = '"*res://autoload/fx_controller.gd"'
"Diagnostics" = '"*res://autoload/diagnostics.gd"'
"NotificationCenter" = '"*res://autoload/notification_center.gd"'
"DeviceHub" = '"*res://autoload/device_hub.gd"'
"AiSystem" = '"*res://autoload/ai_system.gd"'
"Automation" = '"*res://autoload/automation.gd"'
"DebugTools" = '"*res://autoload/debug_tools.gd"'
"AndroidPlatform" = '"*res://autoload/android_platform.gd"'
"RuntimeNotificationBridge" = '"*res://autoload/runtime_notification_bridge.gd"'
"RuntimeHealthBridge" = '"*res://autoload/runtime_health_bridge.gd"'
"HydraRuntime" = '"*res://autoload/hydra_runtime.gd"'
}

foreach ($autoload in $autoloads.GetEnumerator()) {
Set-ProjectSetting -Section "autoload"
-Key $autoload.Key `
-Value $autoload.Value
}

Set-ProjectSetting -Section "application"
-Key "run/main_scene" `
-Value '"res://packages/020_final_hud/scenes/final_hud.tscn"'

Set-ProjectSetting -Section "display"
-Key "window/size/viewport_width" `
-Value "1920"

Set-ProjectSetting -Section "display"
-Key "window/size/viewport_height" `
-Value "1080"

Set-ProjectSetting -Section "display"
-Key "window/size/window_width_override" `
-Value "1920"

Set-ProjectSetting -Section "display"
-Key "window/size/window_height_override" `
-Value "1080"

Write-Host ""
Write-Host "INTEGRATION PASS 001 INSTALLED" -ForegroundColor Green
Write-Host ""
Write-Host "Main scene:" -ForegroundColor Cyan
Write-Host "res://packages/020_final_hud/scenes/final_hud.tscn"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(runtime): add production composition root"'
Write-Host "git push"