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
        $messages = $errors | ForEach-Object {
            "Line $($_.Extent.StartLineNumber): $($_.Message)"
        }

        throw "Błąd składni instalatora:`n$($messages -join "`n")"
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
Assert-PowerShellSyntax -ScriptPath $PSCommandPath

$files = [ordered]@{}

# =============================================================================
# PACKAGE 019 — DEBUG TOOLS
# =============================================================================

$files["packages/019_debug_tools/package.cfg"] = @'
[package]

id="019_debug_tools"
name="Debug Tools"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system",
	"013_diagnostics",
	"014_notification_center"
)
'@

$files["packages/019_debug_tools/README.md"] = @'
# Package 019 — Debug Tools

Debug Tools provides runtime inspection, command execution, event tracing,
performance monitoring and developer overlays.

The package is disabled in production configuration unless explicitly enabled.

Debug commands must be registered through DebugCommandRegistry.
'@

$files["packages/019_debug_tools/CHANGELOG.md"] = @'
# Debug Tools changelog

## [0.1.0] - 2026-07-18

### Added

- Added debug configuration.
- Added debug log levels.
- Added immutable debug log entries.
- Added debug command contract.
- Added command registry.
- Added debug service.
- Added built-in runtime commands.
- Added debug console and performance overlay.
- Added demo scene and tests.
'@

$files["packages/019_debug_tools/docs/architecture.md"] = @'
# Debug Tools architecture

Debug Tools is isolated from feature-domain code.

Feature modules may register safe diagnostic commands.

Debug Tools does not execute operating-system shell commands.

The command registry receives structured arguments and returns Result.
'@

$files["packages/019_debug_tools/docs/security.md"] = @'
# Debug Tools security

Debug Tools must remain disabled in production builds by default.

Commands must not expose secrets, authentication tokens or private user data.

Arbitrary script evaluation and shell execution are prohibited.

Destructive commands require explicit registration and confirmation policy.
'@

$files["packages/019_debug_tools/resources/debug_tools_configuration.gd"] = @'
class_name DebugToolsConfiguration
extends Resource
## Stores Debug Tools runtime configuration.


#region Runtime

@export_group("Runtime")
@export var enabled: bool = OS.is_debug_build()
@export var console_enabled: bool = true
@export var performance_overlay_enabled: bool = true
@export var event_trace_enabled: bool = false

#endregion


#region Retention

@export_group("Retention")
@export_range(10, 100000, 10) var maximum_log_entries: int = 2000
@export_range(10, 100000, 10) var maximum_event_entries: int = 1000

#endregion


#region Performance

@export_group("Performance")
@export_range(0.05, 10.0, 0.05) var performance_refresh_seconds: float = 0.25
@export var show_fps: bool = true
@export var show_memory: bool = true
@export var show_object_count: bool = true
@export var show_draw_calls: bool = true

#endregion
'@

$files["packages/019_debug_tools/resources/default_debug_tools_configuration.tres"] = @'
[gd_resource type="Resource" script_class="DebugToolsConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/019_debug_tools/resources/debug_tools_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
enabled = true
console_enabled = true
performance_overlay_enabled = true
event_trace_enabled = false
maximum_log_entries = 2000
maximum_event_entries = 1000
performance_refresh_seconds = 0.25
show_fps = true
show_memory = true
show_object_count = true
show_draw_calls = true
'@

$files["packages/019_debug_tools/scripts/domain/debug_log_level.gd"] = @'
class_name DebugLogLevel
extends RefCounted
## Defines Debug Tools log levels.


#region Values

enum Value {
	TRACE,
	DEBUG,
	INFO,
	WARNING,
	ERROR,
	CRITICAL,
}

#endregion


#region Public API

## Returns a stable lowercase identifier.
static func to_string_name(level: Value) -> StringName:
	match level:
		Value.TRACE:
			return &"trace"
		Value.DEBUG:
			return &"debug"
		Value.INFO:
			return &"info"
		Value.WARNING:
			return &"warning"
		Value.ERROR:
			return &"error"
		Value.CRITICAL:
			return &"critical"
		_:
			return &"unknown"


## Returns a presentation color.
static func to_color(level: Value) -> Color:
	match level:
		Value.TRACE:
			return Color("#40515b")
		Value.DEBUG:
			return Color("#6e8794")
		Value.INFO:
			return Color("#32d8ff")
		Value.WARNING:
			return Color("#ffbf47")
		Value.ERROR:
			return Color("#ff7a4d")
		Value.CRITICAL:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion
'@

$files["packages/019_debug_tools/scripts/domain/debug_log_entry.gd"] = @'
class_name DebugLogEntry
extends ValueObject
## Represents one immutable runtime debug log entry.


#region State

var _entry_id: StringName
var _level: DebugLogLevel.Value
var _source: StringName
var _message: String
var _metadata: Dictionary[StringName, Variant]
var _recorded_at_unix_ms: int

#endregion


#region Construction

## Creates an immutable debug log entry.
func _init(
	level: DebugLogLevel.Value,
	source: StringName,
	message: String,
	metadata: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not source.is_empty(),
		"DebugLogEntry requires source."
	)
	assert(
		not message.strip_edges().is_empty(),
		"DebugLogEntry requires message."
	)

	_entry_id = StringName(
		"debug-%s-%s"
		% [
			Time.get_ticks_usec(),
			randi(),
		]
	)
	_level = level
	_source = source
	_message = message.strip_edges()
	_metadata = metadata.duplicate(true)
	_recorded_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)

#endregion


#region Public API

func get_entry_id() -> StringName:
	return _entry_id


func get_level() -> DebugLogLevel.Value:
	return _level


func get_source() -> StringName:
	return _source


func get_message() -> String:
	return _message


func get_metadata() -> Dictionary[StringName, Variant]:
	return _metadata.duplicate(true)


func get_recorded_at_unix_ms() -> int:
	return _recorded_at_unix_ms

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_entry_id,
		_level,
		_source,
		_message,
		_metadata,
		_recorded_at_unix_ms,
	]

#endregion
'@

$files["packages/019_debug_tools/scripts/contracts/debug_command.gd"] = @'
@abstract
class_name DebugCommand
extends RefCounted
## Defines a safe structured debug command.


#region Public API

## Returns the stable command identifier.
@abstract
func get_command_id() -> StringName


## Returns a human-readable description.
@abstract
func get_description() -> String


## Returns a usage string.
@abstract
func get_usage() -> String


## Executes the command.
@abstract
func execute(arguments: PackedStringArray) -> Result

#endregion
'@

$files["packages/019_debug_tools/scripts/application/debug_command_registry.gd"] = @'
class_name DebugCommandRegistry
extends RefCounted
## Stores and executes safe debug commands.


#region State

var _commands: Dictionary[StringName, DebugCommand] = {}

#endregion


#region Public API

## Registers one debug command.
func register_command(command: DebugCommand) -> Result:
	if command == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Debug command cannot be null."
			)
		)

	var command_id := command.get_command_id()

	if command_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Debug command requires command_id."
			)
		)

	if _commands.has(command_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_ALREADY_REGISTERED,
				"Debug command is already registered.",
				{&"command_id": command_id}
			)
		)

	_commands[command_id] = command

	return Result.success(command)


## Executes a command line.
func execute_line(command_line: String) -> Result:
	var normalized := command_line.strip_edges()

	if normalized.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Debug command line cannot be empty."
			)
		)

	var parts := normalized.split(
		" ",
		false
	)

	if parts.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Debug command line is invalid."
			)
		)

	var command_id := StringName(parts[0].to_lower())
	var command := _commands.get(command_id) as DebugCommand

	if command == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_NOT_FOUND,
				"Debug command was not found.",
				{&"command_id": command_id}
			)
		)

	var arguments := PackedStringArray()

	for index in range(1, parts.size()):
		arguments.append(parts[index])

	return command.execute(arguments)


## Returns registered commands.
func get_commands() -> Array[DebugCommand]:
	var result: Array[DebugCommand] = []

	for command: DebugCommand in _commands.values():
		result.append(command)

	result.sort_custom(
		func(left: DebugCommand, right: DebugCommand) -> bool:
			return (
				String(left.get_command_id())
				< String(right.get_command_id())
			)
	)

	return result

#endregion
'@

$files["packages/019_debug_tools/scripts/infrastructure/help_debug_command.gd"] = @'
class_name HelpDebugCommand
extends DebugCommand
## Prints all registered debug commands.


#region State

var _registry: DebugCommandRegistry

#endregion


#region Construction

func _init(registry: DebugCommandRegistry) -> void:
	assert(
		registry != null,
		"HelpDebugCommand requires registry."
	)

	_registry = registry

#endregion


#region DebugCommand

func get_command_id() -> StringName:
	return &"help"


func get_description() -> String:
	return "Lists registered debug commands."


func get_usage() -> String:
	return "help"


func execute(_arguments: PackedStringArray) -> Result:
	var lines := PackedStringArray()

	for command in _registry.get_commands():
		lines.append(
			"%s - %s"
			% [
				command.get_usage(),
				command.get_description(),
			]
		)

	return Result.success(
		"\n".join(lines)
	)

#endregion
'@

$files["packages/019_debug_tools/scripts/infrastructure/runtime_debug_command.gd"] = @'
class_name RuntimeDebugCommand
extends DebugCommand
## Returns current Godot runtime metrics.


#region DebugCommand

func get_command_id() -> StringName:
	return &"runtime"


func get_description() -> String:
	return "Displays runtime performance information."


func get_usage() -> String:
	return "runtime"


func execute(_arguments: PackedStringArray) -> Result:
	var fps := Performance.get_monitor(
		Performance.TIME_FPS
	)
	var memory_bytes := Performance.get_monitor(
		Performance.MEMORY_STATIC
	)
	var object_count := Performance.get_monitor(
		Performance.OBJECT_COUNT
	)
	var node_count := Performance.get_monitor(
		Performance.OBJECT_NODE_COUNT
	)

	var output := (
		"FPS: %d\n"
		+ "STATIC MEMORY: %.2f MiB\n"
		+ "OBJECTS: %d\n"
		+ "NODES: %d"
	) % [
		int(fps),
		memory_bytes / 1048576.0,
		int(object_count),
		int(node_count),
	]

	return Result.success(output)

#endregion
'@

$files["packages/019_debug_tools/scripts/infrastructure/clear_debug_command.gd"] = @'
class_name ClearDebugCommand
extends DebugCommand
## Requests Debug Tools output clearing.


#region DebugCommand

func get_command_id() -> StringName:
	return &"clear"


func get_description() -> String:
	return "Clears debug console output."


func get_usage() -> String:
	return "clear"


func execute(_arguments: PackedStringArray) -> Result:
	return Result.success(
		{
			&"clear_output": true,
		}
	)

#endregion
'@

$files["packages/019_debug_tools/scripts/application/debug_tools_service.gd"] = @'
class_name DebugToolsService
extends Node
## Coordinates debug logging, commands and runtime telemetry.


#region Signals

signal log_entry_added(entry: DebugLogEntry)
signal logs_cleared()
signal command_executed(
	command_line: String,
	result: Result
)
signal performance_updated(metrics: Dictionary)

#endregion


#region State

var _configuration: DebugToolsConfiguration
var _registry: DebugCommandRegistry
var _entries: Array[DebugLogEntry] = []
var _performance_timer: Timer

#endregion


#region Lifecycle

func _ready() -> void:
	_performance_timer = Timer.new()
	_performance_timer.name = "DebugPerformanceTimer"
	_performance_timer.one_shot = false
	_performance_timer.timeout.connect(
		_on_performance_timer_timeout
	)
	add_child(_performance_timer)

#endregion


#region Public API

## Configures Debug Tools.
func configure(
	configuration: DebugToolsConfiguration,
	registry: DebugCommandRegistry
) -> Result:
	if configuration == null or registry == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Debug Tools configuration and registry are required."
			)
		)

	_configuration = configuration
	_registry = registry
	_performance_timer.wait_time = (
		configuration.performance_refresh_seconds
	)

	return Result.success()


## Starts configured debug services.
func start() -> Result:
	if _configuration == null or _registry == null:
		return _not_configured()

	if not _configuration.enabled:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Debug Tools is disabled."
			)
		)

	if _configuration.performance_overlay_enabled:
		_performance_timer.start()

	return Result.success()


## Stops debug telemetry.
func stop() -> void:
	_performance_timer.stop()


## Adds one debug log entry.
func log(
	level: DebugLogLevel.Value,
	source: StringName,
	message: String,
	metadata: Dictionary[StringName, Variant] = {}
) -> Result:
	if _configuration == null:
		return _not_configured()

	var entry := DebugLogEntry.new(
		level,
		source,
		message,
		metadata
	)

	_entries.append(entry)

	while _entries.size() > _configuration.maximum_log_entries:
		_entries.pop_front()

	log_entry_added.emit(entry)

	return Result.success(entry)


## Clears all debug logs.
func clear_logs() -> void:
	_entries.clear()
	logs_cleared.emit()


## Executes a structured debug command.
func execute_command(
	command_line: String
) -> Result:
	if _registry == null:
		return _not_configured()

	var result := _registry.execute_line(command_line)
	command_executed.emit(command_line, result)

	return result


## Returns current debug log entries.
func get_entries() -> Array[DebugLogEntry]:
	return _entries.duplicate()


## Returns current performance metrics.
func get_performance_metrics() -> Dictionary:
	return {
		&"fps": Performance.get_monitor(
			Performance.TIME_FPS
		),
		&"static_memory_bytes": Performance.get_monitor(
			Performance.MEMORY_STATIC
		),
		&"object_count": Performance.get_monitor(
			Performance.OBJECT_COUNT
		),
		&"node_count": Performance.get_monitor(
			Performance.OBJECT_NODE_COUNT
		),
		&"draw_calls": Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
		),
		&"process_time": Performance.get_monitor(
			Performance.TIME_PROCESS
		),
		&"physics_process_time": Performance.get_monitor(
			Performance.TIME_PHYSICS_PROCESS
		),
	}

#endregion


#region Private methods

func _on_performance_timer_timeout() -> void:
	performance_updated.emit(
		get_performance_metrics()
	)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Debug Tools is not configured."
		)
	)

#endregion
'@

$files["packages/019_debug_tools/scripts/presentation/performance_overlay.gd"] = @'
class_name PerformanceOverlay
extends WidgetBase
## Displays live Godot performance metrics.


#region Nodes

@onready var _fps_label: RichTextLabel = %FpsLabel
@onready var _memory_label: RichTextLabel = %MemoryLabel
@onready var _objects_label: RichTextLabel = %ObjectsLabel
@onready var _draw_calls_label: RichTextLabel = %DrawCallsLabel

#endregion


#region State

var _service: DebugToolsService

#endregion


#region Public API

## Binds the overlay to DebugToolsService.
func bind_service(service: DebugToolsService) -> void:
	assert(service != null, "Debug Tools service cannot be null.")

	_disconnect_service()
	_service = service
	_service.performance_updated.connect(
		_on_performance_updated
	)

	_on_performance_updated(
		_service.get_performance_metrics()
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.performance_updated.is_connected(
		_on_performance_updated
	):
		_service.performance_updated.disconnect(
			_on_performance_updated
		)


func _on_performance_updated(metrics: Dictionary) -> void:
	_fps_label.text = "FPS  //  %d" % int(
		metrics.get(&"fps", 0.0)
	)
	_memory_label.text = "MEMORY  //  %.2f MiB" % (
		float(metrics.get(&"static_memory_bytes", 0.0))
		/ 1048576.0
	)
	_objects_label.text = (
		"OBJECTS  //  %d    NODES  //  %d"
		% [
			int(metrics.get(&"object_count", 0.0)),
			int(metrics.get(&"node_count", 0.0)),
		]
	)
	_draw_calls_label.text = "DRAW CALLS  //  %d" % int(
		metrics.get(&"draw_calls", 0.0)
	)

#endregion
'@

$files["packages/019_debug_tools/scripts/presentation/debug_console_panel.gd"] = @'
class_name DebugConsolePanel
extends PanelBase
## Displays logs and executes registered debug commands.


#region Nodes

@onready var _output: RichTextLabel = %Output
@onready var _command_input: LineEdit = %CommandInput
@onready var _execute_button: HydraButton = %ExecuteButton
@onready var _clear_button: HydraButton = %ClearButton
@onready var _status_label: RichTextLabel = %StatusLabel

#endregion


#region State

var _service: DebugToolsService

#endregion


#region Lifecycle

func _ready() -> void:
	super()

	_execute_button.pressed.connect(
		_on_execute_button_pressed
	)
	_clear_button.pressed.connect(
		_on_clear_button_pressed
	)
	_command_input.text_submitted.connect(
		_on_command_submitted
	)

#endregion


#region Public API

## Binds the console to DebugToolsService.
func bind_service(service: DebugToolsService) -> void:
	assert(service != null, "Debug Tools service cannot be null.")

	_disconnect_service()
	_service = service

	_service.log_entry_added.connect(
		_on_log_entry_added
	)
	_service.logs_cleared.connect(
		_on_logs_cleared
	)
	_service.command_executed.connect(
		_on_command_executed
	)

	_render_existing_logs()

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.log_entry_added.is_connected(
		_on_log_entry_added
	):
		_service.log_entry_added.disconnect(
			_on_log_entry_added
		)

	if _service.logs_cleared.is_connected(
		_on_logs_cleared
	):
		_service.logs_cleared.disconnect(
			_on_logs_cleared
		)

	if _service.command_executed.is_connected(
		_on_command_executed
	):
		_service.command_executed.disconnect(
			_on_command_executed
		)


func _render_existing_logs() -> void:
	_output.text = ""

	if _service == null:
		return

	for entry in _service.get_entries():
		_append_entry(entry)


func _submit_command(command_line: String) -> void:
	if _service == null:
		return

	var normalized := command_line.strip_edges()

	if normalized.is_empty():
		return

	_output.append_text(
		"[color=#d6aa48]> %s[/color]\n"
		% _escape_bbcode(normalized)
	)

	_command_input.clear()
	_service.execute_command(normalized)


func _append_entry(entry: DebugLogEntry) -> void:
	var color := DebugLogLevel.to_color(
		entry.get_level()
	).to_html(false)

	_output.append_text(
		"[color=#6e8794][%s][/color] "
		+ "[color=%s]%s[/color] "
		+ "[color=#32d8ff]%s[/color]\n"
	) % [
		DebugLogLevel.to_string_name(
			entry.get_level()
		),
		color,
		String(entry.get_source()).to_upper(),
		_escape_bbcode(entry.get_message()),
	]

	_output.scroll_to_line(
		_output.get_line_count()
	)


func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")


func _on_execute_button_pressed(
	_action_id: StringName
) -> void:
	_submit_command(_command_input.text)


func _on_clear_button_pressed(
	_action_id: StringName
) -> void:
	if _service != null:
		_service.clear_logs()

	_output.text = ""


func _on_command_submitted(command_line: String) -> void:
	_submit_command(command_line)


func _on_log_entry_added(entry: DebugLogEntry) -> void:
	_append_entry(entry)


func _on_logs_cleared() -> void:
	_output.text = ""


func _on_command_executed(
	_command_line: String,
	result: Result
) -> void:
	if result.is_failure():
		_status_label.text = (
			"[color=#ff4f62]COMMAND FAILED  //  %s[/color]"
			% _escape_bbcode(
				result.get_error().get_message()
			)
		)
		return

	var value: Variant = result.get_value()

	if value is Dictionary and value.get(&"clear_output", false):
		_output.text = ""
		_status_label.text = (
			"[color=#55f2a3]OUTPUT CLEARED[/color]"
		)
		return

	if value != null:
		_output.append_text(
			"[color=#55f2a3]%s[/color]\n"
			% _escape_bbcode(str(value))
		)

	_status_label.text = (
		"[color=#55f2a3]COMMAND COMPLETED[/color]"
	)

#endregion
'@

$files["packages/019_debug_tools/scenes/performance_overlay.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/019_debug_tools/scripts/presentation/performance_overlay.gd" id="1"]

[node name="PerformanceOverlay" type="Control"]
custom_minimum_size = Vector2(420, 138)
layout_mode = 3
anchors_preset = 0
offset_right = 420.0
offset_bottom = 138.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"performance_overlay"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.00392157, 0.0156863, 0.027451, 0.92)

[node name="Accent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 10.0
offset_top = 10.0
offset_right = 15.0
offset_bottom = 128.0
color = Color(0.196078, 0.847059, 1, 1)

[node name="FpsLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 30.0
offset_top = 10.0
offset_right = 400.0
offset_bottom = 36.0
bbcode_enabled = true
text = "[color=#55f2a3]FPS  //  0[/color]"
fit_content = true
scroll_active = false

[node name="MemoryLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 30.0
offset_top = 40.0
offset_right = 400.0
offset_bottom = 66.0
text = "MEMORY  //  0.00 MiB"
fit_content = true
scroll_active = false

[node name="ObjectsLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 30.0
offset_top = 70.0
offset_right = 400.0
offset_bottom = 96.0
text = "OBJECTS  //  0    NODES  //  0"
fit_content = true
scroll_active = false

[node name="DrawCallsLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 30.0
offset_top = 100.0
offset_right = 400.0
offset_bottom = 126.0
text = "DRAW CALLS  //  0"
fit_content = true
scroll_active = false
'@

$files["packages/019_debug_tools/scenes/debug_console_panel.tscn"] = @'
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://packages/019_debug_tools/scripts/presentation/debug_console_panel.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/003_widget_library/scenes/hydra_button.tscn" id="2"]

[node name="DebugConsolePanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 1080.0
offset_bottom = 820.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"debug_console_panel"
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
offset_top = 20.0
offset_right = 700.0
offset_bottom = 60.0
bbcode_enabled = true
text = "[font_size=30][color=#32d8ff]DEBUG TOOLS[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 920.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]RUNTIME INSPECTION CONSOLE  //  CHANNEL 019[/color]"
fit_content = true
scroll_active = false

[node name="OutputFrame" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 120.0
offset_right = 1026.0
offset_bottom = 620.0
color = Color(0.027451, 0.0901961, 0.133333, 0.76)

[node name="Output" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 74.0
offset_top = 140.0
offset_right = 1006.0
offset_bottom = 600.0
bbcode_enabled = true
text = "[color=#40515b]DEBUG CONSOLE READY[/color]"
scroll_active = true
selection_enabled = true

[node name="CommandInput" type="LineEdit" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 650.0
offset_right = 1026.0
offset_bottom = 704.0
placeholder_text = "ENTER SAFE DEBUG COMMAND..."
clear_button_enabled = true

[node name="ExecuteButton" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 730.0
offset_right = 294.0
offset_bottom = 790.0
action_id = &"debug_execute"
text = "EXECUTE"

[node name="ClearButton" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 320.0
offset_top = 730.0
offset_right = 560.0
offset_bottom = 790.0
action_id = &"debug_clear"
text = "CLEAR"
accent_color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="StatusLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 592.0
offset_top = 742.0
offset_right = 1026.0
offset_bottom = 782.0
bbcode_enabled = true
text = "[color=#55f2a3]CONSOLE ONLINE[/color]"
fit_content = true
scroll_active = false
'@

$files["packages/019_debug_tools/demo/debug_tools_demo.gd"] = @'
class_name DebugToolsDemo
extends Control
## Demonstrates Debug Tools runtime inspection.


#region Nodes

@onready var _console: DebugConsolePanel = %DebugConsolePanel
@onready var _overlay: PerformanceOverlay = %PerformanceOverlay

#endregion


#region State

var _service: DebugToolsService

#endregion


#region Lifecycle

func _ready() -> void:
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

	_service = DebugToolsService.new()
	_service.name = "DebugToolsService"
	add_child(_service)

	_service.configure(
		configuration,
		registry
	)
	_service.start()

	_console.bind_service(_service)
	_overlay.bind_service(_service)

	_service.log(
		DebugLogLevel.Value.INFO,
		&"debug_tools",
		"Debug Tools initialized."
	)

#endregion
'@

$files["packages/019_debug_tools/demo/debug_tools_demo.tscn"] = @'
[gd_scene load_steps=4 format=3]

[ext_resource type="Script" path="res://packages/019_debug_tools/demo/debug_tools_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/019_debug_tools/scenes/debug_console_panel.tscn" id="2"]
[ext_resource type="PackedScene" path="res://packages/019_debug_tools/scenes/performance_overlay.tscn" id="3"]

[node name="DebugToolsDemo" type="Control"]
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

[node name="DebugConsolePanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 420.0
offset_top = 130.0
offset_right = 1500.0
offset_bottom = 950.0

[node name="PerformanceOverlay" parent="." instance=ExtResource("3")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 1470.0
offset_top = 30.0
offset_right = 1890.0
offset_bottom = 168.0
'@

$files["packages/019_debug_tools/tests/unit/test_debug_command_registry.gd"] = @'
class_name DebugCommandRegistryTest
extends RefCounted
## Provides DebugCommandRegistry tests.


#region Tests

static func run() -> void:
	var registry := DebugCommandRegistry.new()
	var runtime_command := RuntimeDebugCommand.new()

	assert(
		registry.register_command(
			runtime_command
		).is_success()
	)
	assert(
		registry.execute_line("runtime").is_success()
	)
	assert(
		registry.execute_line("unknown").is_failure()
	)

#endregion
'@

$files["packages/019_debug_tools/tests/unit/test_debug_log_entry.gd"] = @'
class_name DebugLogEntryTest
extends RefCounted
## Provides DebugLogEntry tests.


#region Tests

static func run() -> void:
	var entry := DebugLogEntry.new(
		DebugLogLevel.Value.INFO,
		&"test",
		"Test message."
	)

	assert(entry.get_source() == &"test")
	assert(entry.get_message() == "Test message.")
	assert(
		entry.get_level()
		== DebugLogLevel.Value.INFO
	)

#endregion
'@

$files["packages/019_debug_tools/tests/integration/test_debug_tools_service.gd"] = @'
class_name DebugToolsServiceTest
extends RefCounted
## Provides Debug Tools service composition tests.


#region Tests

static func run() -> void:
	var service := DebugToolsService.new()
	var configuration := DebugToolsConfiguration.new()
	var registry := DebugCommandRegistry.new()

	assert(
		service.configure(
			configuration,
			registry
		).is_success()
	)

#endregion
'@

# =============================================================================
# PACKAGE 020 — FINAL HUD
# =============================================================================

$files["packages/020_final_hud/package.cfg"] = @'
[package]

id="020_final_hud"
name="Final HUD"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system",
	"005_fx_system",
	"006_voice_hub",
	"007_home_hub",
	"008_central_hub",
	"009_environment_hub",
	"010_device_hub",
	"011_ai_system",
	"012_automation",
	"013_diagnostics",
	"014_notification_center",
	"015_plugin_sdk",
	"016_android",
	"017_installer",
	"018_boot_loader",
	"019_debug_tools"
)
'@

$files["packages/020_final_hud/README.md"] = @'
# Package 020 — Final HUD

Final HUD is the production composition layer for HYDRA AI HOME OS.

It owns the 1920x1080 desktop shell, module routing, tactical navigation,
notification surface, status bar and global visual effects.

Feature logic remains inside feature packages.
'@

$files["packages/020_final_hud/CHANGELOG.md"] = @'
# Final HUD changelog

## [0.1.0] - 2026-07-18

### Added

- Added final HUD configuration.
- Added HUD module definitions.
- Added shell state service.
- Added tactical navigation rail.
- Added system status bar.
- Added module viewport.
- Added notification overlay.
- Added scanline and vignette shaders.
- Added final HUD scene.
- Added demo composition and tests.
'@

$files["packages/020_final_hud/docs/architecture.md"] = @'
# Final HUD architecture

Final HUD is a composition package.

It mounts feature panels into a dedicated module viewport.

Navigation emits stable route identifiers.

Feature services remain autoloads or composition-root children.

The shell never communicates directly with infrastructure adapters.
'@

$files["packages/020_final_hud/docs/layout.md"] = @'
# Final HUD layout

Target viewport: 1920x1080.

Top status bar: 72 pixels.

Left navigation rail: 260 pixels.

Main module viewport: 1540x900.

Right telemetry rail: 120 pixels.

Bottom command bar: 108 pixels.

All layout values are centralized in FinalHudLayoutConstants.
'@

$files["packages/020_final_hud/resources/final_hud_configuration.gd"] = @'
class_name FinalHudConfiguration
extends Resource
## Stores production HUD composition configuration.


#region Startup

@export_group("Startup")
@export var default_route_id: StringName = &"home"
@export var restore_last_route: bool = true
@export var show_boot_transition: bool = true

#endregion


#region Effects

@export_group("Effects")
@export var scanlines_enabled: bool = true
@export var vignette_enabled: bool = true
@export var glow_enabled: bool = true
@export_range(0.0, 1.0, 0.01) var scanline_opacity: float = 0.14
@export_range(0.0, 1.0, 0.01) var vignette_strength: float = 0.42

#endregion


#region Debug

@export_group("Debug")
@export var debug_overlay_enabled: bool = OS.is_debug_build()

#endregion
'@

$files["packages/020_final_hud/resources/default_final_hud_configuration.tres"] = @'
[gd_resource type="Resource" script_class="FinalHudConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/020_final_hud/resources/final_hud_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
default_route_id = &"home"
restore_last_route = true
show_boot_transition = true
scanlines_enabled = true
vignette_enabled = true
glow_enabled = true
scanline_opacity = 0.14
vignette_strength = 0.42
debug_overlay_enabled = true
'@

$files["packages/020_final_hud/resources/hud_module_definition.gd"] = @'
class_name HudModuleDefinition
extends Resource
## Defines one module available in the Final HUD shell.


#region Identity

@export_group("Identity")
@export var route_id: StringName = &""
@export var display_name: String = ""
@export var short_label: String = ""
@export var package_id: StringName = &""

#endregion


#region Scene

@export_group("Scene")
@export_file("*.tscn") var scene_path: String = ""
@export var sort_order: int = 0
@export var enabled: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export var accent_color: Color = Color("#32d8ff")
@export_multiline var description: String = ""

#endregion


#region Validation

## Validates the HUD module definition.
func validate() -> Result:
	if route_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD module requires route_id."
			)
		)

	if display_name.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD module requires display_name."
			)
		)

	if scene_path.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD module requires scene_path."
			)
		)

	if not scene_path.begins_with("res://"):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD module scene path must use res://."
			)
		)

	return Result.success()

#endregion
'@

$files["packages/020_final_hud/scripts/final_hud_layout_constants.gd"] = @'
class_name FinalHudLayoutConstants
extends RefCounted
## Centralizes Final HUD layout dimensions.


#region Viewport

const VIEWPORT_SIZE: Vector2 = Vector2(1920.0, 1080.0)

#endregion


#region Primary regions

const TOP_BAR_HEIGHT: float = 72.0
const BOTTOM_BAR_HEIGHT: float = 108.0
const LEFT_RAIL_WIDTH: float = 260.0
const RIGHT_RAIL_WIDTH: float = 120.0

#endregion


#region Module viewport

const MODULE_VIEWPORT_POSITION: Vector2 = Vector2(
	LEFT_RAIL_WIDTH,
	TOP_BAR_HEIGHT
)

const MODULE_VIEWPORT_SIZE: Vector2 = Vector2(
	VIEWPORT_SIZE.x - LEFT_RAIL_WIDTH - RIGHT_RAIL_WIDTH,
	VIEWPORT_SIZE.y - TOP_BAR_HEIGHT - BOTTOM_BAR_HEIGHT
)

#endregion


#region Spacing

const LARGE_GAP: float = 24.0
const MEDIUM_GAP: float = 16.0
const SMALL_GAP: float = 8.0

#endregion
'@

$files["packages/020_final_hud/scripts/domain/hud_shell_state.gd"] = @'
class_name HudShellState
extends AggregateRoot
## Owns active Final HUD route and shell state.


#region Events

const EVENT_ROUTE_CHANGED: StringName = \
	&"hydra.hud.route_changed"
const EVENT_SHELL_LOCK_CHANGED: StringName = \
	&"hydra.hud.shell_lock_changed"

#endregion


#region State

var _active_route_id: StringName = &""
var _previous_route_id: StringName = &""
var _shell_locked: bool = false

#endregion


#region Construction

func _init(id: EntityId) -> void:
	super(id)

#endregion


#region Public API

func get_active_route_id() -> StringName:
	return _active_route_id


func get_previous_route_id() -> StringName:
	return _previous_route_id


func is_shell_locked() -> bool:
	return _shell_locked


## Changes the active route.
func activate_route(route_id: StringName) -> Result:
	if route_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"HUD route identifier cannot be empty."
			)
		)

	if _shell_locked:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"HUD shell is locked."
			)
		)

	if _active_route_id == route_id:
		return Result.success()

	_previous_route_id = _active_route_id
	_active_route_id = route_id
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_ROUTE_CHANGED,
			{
				&"route_id": _active_route_id,
				&"previous_route_id": _previous_route_id,
			}
		)
	)

	return Result.success()


## Locks or unlocks route changes.
func set_shell_locked(locked: bool) -> void:
	if _shell_locked == locked:
		return

	_shell_locked = locked
	increment_version()

	_record_domain_event(
		DomainEvent.new(
			EVENT_SHELL_LOCK_CHANGED,
			{
				&"locked": _shell_locked,
			}
		)
	)

#endregion
'@

$files["packages/020_final_hud/scripts/application/final_hud_service.gd"] = @'
class_name FinalHudService
extends Node
## Coordinates Final HUD module registration and routing.


#region Signals

signal module_registered(module: HudModuleDefinition)
signal route_changed(
	module: HudModuleDefinition,
	previous_route_id: StringName
)
signal route_failed(
	route_id: StringName,
	error: DomainError
)
signal shell_lock_changed(locked: bool)

#endregion


#region State

var _configuration: FinalHudConfiguration
var _state: HudShellState
var _modules: Dictionary[StringName, HudModuleDefinition] = {}

#endregion


#region Public API

## Configures Final HUD.
func configure(
	configuration: FinalHudConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Final HUD configuration cannot be null."
			)
		)

	_configuration = configuration
	_state = HudShellState.new(EntityId.generate())

	return Result.success()


## Registers one HUD module.
func register_module(
	module: HudModuleDefinition
) -> Result:
	if _state == null:
		return _not_configured()

	if module == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"HUD module cannot be null."
			)
		)

	var validation_result := module.validate()

	if validation_result.is_failure():
		return validation_result

	if _modules.has(module.route_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_ALREADY_REGISTERED,
				"HUD module is already registered.",
				{&"route_id": module.route_id}
			)
		)

	_modules[module.route_id] = module
	module_registered.emit(module)

	return Result.success(module)


## Registers multiple HUD modules.
func register_modules(
	modules: Array[HudModuleDefinition]
) -> Result:
	for module in modules:
		var result := register_module(module)

		if result.is_failure():
			return result

	return Result.success()


## Activates a registered module.
func activate_route(route_id: StringName) -> Result:
	if _state == null:
		return _not_configured()

	var module := _modules.get(
		route_id
	) as HudModuleDefinition

	if module == null:
		var missing_error := DomainError.new(
			HydraErrors.SERVICE_NOT_FOUND,
			"HUD route is not registered.",
			{&"route_id": route_id}
		)

		route_failed.emit(route_id, missing_error)

		return Result.failure(missing_error)

	if not module.enabled:
		var disabled_error := DomainError.new(
			HydraErrors.INVALID_STATE,
			"HUD module is disabled.",
			{&"route_id": route_id}
		)

		route_failed.emit(route_id, disabled_error)

		return Result.failure(disabled_error)

	if not ResourceLoader.exists(module.scene_path):
		var scene_error := DomainError.new(
			HydraErrors.INVALID_ARGUMENT,
			"HUD module scene does not exist.",
			{
				&"route_id": route_id,
				&"scene_path": module.scene_path,
			}
		)

		route_failed.emit(route_id, scene_error)

		return Result.failure(scene_error)

	var previous_route_id := _state.get_active_route_id()
	var state_result := _state.activate_route(route_id)

	if state_result.is_failure():
		route_failed.emit(
			route_id,
			state_result.get_error()
		)
		return state_result

	_publish_events()
	route_changed.emit(module, previous_route_id)

	return Result.success(module)


## Activates the configured default route.
func activate_default_route() -> Result:
	if _configuration == null:
		return _not_configured()

	return activate_route(
		_configuration.default_route_id
	)


## Locks or unlocks shell navigation.
func set_shell_locked(locked: bool) -> void:
	if _state == null:
		return

	_state.set_shell_locked(locked)
	_publish_events()
	shell_lock_changed.emit(locked)


## Returns sorted HUD modules.
func get_modules() -> Array[HudModuleDefinition]:
	var result: Array[HudModuleDefinition] = []

	for module: HudModuleDefinition in _modules.values():
		result.append(module)

	result.sort_custom(
		func(
			left: HudModuleDefinition,
			right: HudModuleDefinition
		) -> bool:
			return left.sort_order < right.sort_order
	)

	return result


## Returns the active route identifier.
func get_active_route_id() -> StringName:
	if _state == null:
		return &""

	return _state.get_active_route_id()

#endregion


#region Private methods

func _publish_events() -> void:
	if _state == null:
		return

	var events := _state.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Final HUD service is not configured."
		)
	)

#endregion
'@

$files["packages/020_final_hud/scripts/presentation/tactical_navigation_rail.gd"] = @'
class_name TacticalNavigationRail
extends WidgetBase
## Displays Final HUD module navigation buttons.


#region Signals

signal route_requested(route_id: StringName)

#endregion


#region Constants

const BUTTON_HEIGHT: float = 62.0
const BUTTON_GAP: float = 12.0
const BUTTON_START_Y: float = 110.0
const BUTTON_LEFT: float = 18.0
const BUTTON_RIGHT: float = 242.0

#endregion


#region Nodes

@onready var _button_layer: Control = %ButtonLayer
@onready var _active_label: RichTextLabel = %ActiveLabel

#endregion


#region State

var _service: FinalHudService
var _buttons: Dictionary[StringName, Button] = {}

#endregion


#region Public API

## Binds this navigation rail to FinalHudService.
func bind_service(service: FinalHudService) -> void:
	assert(service != null, "Final HUD service cannot be null.")

	_disconnect_service()
	_service = service
	_service.module_registered.connect(
		_on_module_registered
	)
	_service.route_changed.connect(
		_on_route_changed
	)

	rebuild_modules()


## Rebuilds navigation buttons.
func rebuild_modules() -> void:
	for child in _button_layer.get_children():
		child.queue_free()

	_buttons.clear()

	if _service == null:
		return

	var modules := _service.get_modules()

	for index in modules.size():
		var module := modules[index]
		var button := Button.new()

		button.name = "Route_%s" % module.route_id
		button.text = (
			module.short_label
			if not module.short_label.is_empty()
			else module.display_name
		)
		button.position = Vector2(
			BUTTON_LEFT,
			BUTTON_START_Y + (
				index * (BUTTON_HEIGHT + BUTTON_GAP)
			)
		)
		button.size = Vector2(
			BUTTON_RIGHT - BUTTON_LEFT,
			BUTTON_HEIGHT
		)
		button.disabled = not module.enabled
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = (
			Control.CURSOR_POINTING_HAND
		)

		button.pressed.connect(
			_on_route_button_pressed.bind(
				module.route_id
			)
		)

		_button_layer.add_child(button)
		_buttons[module.route_id] = button

	_refresh_active_state(
		_service.get_active_route_id()
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.module_registered.is_connected(
		_on_module_registered
	):
		_service.module_registered.disconnect(
			_on_module_registered
		)

	if _service.route_changed.is_connected(
		_on_route_changed
	):
		_service.route_changed.disconnect(
			_on_route_changed
		)


func _refresh_active_state(
	route_id: StringName
) -> void:
	for current_route_id in _buttons:
		var button := _buttons[current_route_id]
		button.modulate = (
			Color("#d6aa48")
			if current_route_id == route_id
			else Color.WHITE
		)

	var module_name := "NONE"

	if _service != null:
		for module in _service.get_modules():
			if module.route_id == route_id:
				module_name = module.display_name
				break

	_active_label.text = (
		"ACTIVE  //  %s"
		% module_name
	)


func _on_route_button_pressed(
	route_id: StringName
) -> void:
	route_requested.emit(route_id)

	if _service != null:
		_service.activate_route(route_id)


func _on_module_registered(
	_module: HudModuleDefinition
) -> void:
	rebuild_modules()


func _on_route_changed(
	module: HudModuleDefinition,
	_previous_route_id: StringName
) -> void:
	_refresh_active_state(module.route_id)

#endregion
'@

$files["packages/020_final_hud/scripts/presentation/system_status_bar.gd"] = @'
class_name SystemStatusBar
extends WidgetBase
## Displays global HYDRA status information.


#region Nodes

@onready var _clock_label: RichTextLabel = %ClockLabel
@onready var _health_label: RichTextLabel = %HealthLabel
@onready var _route_label: RichTextLabel = %RouteLabel
@onready var _connection_label: RichTextLabel = %ConnectionLabel

#endregion


#region State

var _service: FinalHudService
var _clock_timer: Timer

#endregion


#region Lifecycle

func _on_widget_ready() -> void:
	_clock_timer = Timer.new()
	_clock_timer.name = "HudClockTimer"
	_clock_timer.wait_time = 1.0
	_clock_timer.one_shot = false
	_clock_timer.timeout.connect(_update_clock)
	add_child(_clock_timer)
	_clock_timer.start()

	_update_clock()


#region Public API

## Binds the status bar to FinalHudService.
func bind_service(service: FinalHudService) -> void:
	assert(service != null, "Final HUD service cannot be null.")

	_disconnect_service()
	_service = service
	_service.route_changed.connect(
		_on_route_changed
	)

#endregion


## Updates the system health display.
func set_health_state(
	state: SystemHealthState.Value
) -> void:
	_health_label.text = (
		"SYSTEM  //  %s"
		% String(
			SystemHealthState.to_string_name(state)
		).to_upper()
	)
	_health_label.modulate = SystemHealthState.to_color(state)


## Updates connection display.
func set_connection_state(
	label: String,
	online: bool
) -> void:
	_connection_label.text = (
		"LINK  //  %s"
		% label.to_upper()
	)
	_connection_label.modulate = (
		Color("#55f2a3")
		if online
		else Color("#ff4f62")
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.route_changed.is_connected(
		_on_route_changed
	):
		_service.route_changed.disconnect(
			_on_route_changed
		)


func _update_clock() -> void:
	var datetime := Time.get_datetime_dict_from_system()

	_clock_label.text = (
		"%04d-%02d-%02d  //  %02d:%02d:%02d"
		% [
			datetime.year,
			datetime.month,
			datetime.day,
			datetime.hour,
			datetime.minute,
			datetime.second,
		]
	)


func _on_route_changed(
	module: HudModuleDefinition,
	_previous_route_id: StringName
) -> void:
	_route_label.text = (
		"MODULE  //  %s"
		% module.display_name
	)

#endregion
'@

$files["packages/020_final_hud/scripts/presentation/module_viewport.gd"] = @'
class_name ModuleViewport
extends Control
## Mounts active feature panels inside the Final HUD shell.


#region Signals

signal module_mounted(
	route_id: StringName,
	instance: Node
)
signal module_mount_failed(
	route_id: StringName,
	error: DomainError
)

#endregion


#region Nodes

@onready var _mount_point: Control = %MountPoint
@onready var _loading_label: RichTextLabel = %LoadingLabel
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: FinalHudService
var _active_instance: Node
var _active_route_id: StringName = &""

#endregion


#region Public API

## Binds this viewport to FinalHudService.
func bind_service(service: FinalHudService) -> void:
	assert(service != null, "Final HUD service cannot be null.")

	_disconnect_service()
	_service = service
	_service.route_changed.connect(
		_on_route_changed
	)


## Unmounts the current feature panel.
func clear_module() -> void:
	if _active_instance != null:
		_active_instance.queue_free()

	_active_instance = null
	_active_route_id = &""
	_loading_label.visible = true
	_error_label.visible = false

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.route_changed.is_connected(
		_on_route_changed
	):
		_service.route_changed.disconnect(
			_on_route_changed
		)


func _on_route_changed(
	module: HudModuleDefinition,
	_previous_route_id: StringName
) -> void:
	_mount_module(module)


func _mount_module(
	module: HudModuleDefinition
) -> void:
	clear_module()

	var resource := load(module.scene_path)

	if not resource is PackedScene:
		var error := DomainError.new(
			HydraErrors.INVALID_ARGUMENT,
			"HUD module resource is not a PackedScene.",
			{
				&"route_id": module.route_id,
				&"scene_path": module.scene_path,
			}
		)

		_show_error(module.route_id, error)
		return

	var scene := resource as PackedScene
	var instance := scene.instantiate()

	if instance == null:
		var instance_error := DomainError.new(
			HydraErrors.UNKNOWN,
			"HUD module scene could not be instantiated.",
			{&"route_id": module.route_id}
		)

		_show_error(module.route_id, instance_error)
		return

	_mount_point.add_child(instance)

	if instance is Control:
		var control := instance as Control
		control.position = Vector2.ZERO
		control.size = _mount_point.size
		control.set_anchors_preset(
			Control.PRESET_FULL_RECT
		)
		control.offset_left = 0.0
		control.offset_top = 0.0
		control.offset_right = 0.0
		control.offset_bottom = 0.0

	_active_instance = instance
	_active_route_id = module.route_id
	_loading_label.visible = false
	_error_label.visible = false

	module_mounted.emit(
		module.route_id,
		instance
	)


func _show_error(
	route_id: StringName,
	error: DomainError
) -> void:
	_loading_label.visible = false
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]MODULE MOUNT FAILURE[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % error.get_message()

	module_mount_failed.emit(route_id, error)

#endregion
'@

$files["packages/020_final_hud/scripts/presentation/final_hud_shell.gd"] = @'
class_name FinalHudShell
extends Control
## Production composition root for the HYDRA Final HUD.


#region Resources

@export var configuration: FinalHudConfiguration

#endregion


#region Nodes

@onready var _status_bar: SystemStatusBar = %SystemStatusBar
@onready var _navigation_rail: TacticalNavigationRail = %NavigationRail
@onready var _module_viewport: ModuleViewport = %ModuleViewport
@onready var _scanlines: ColorRect = %Scanlines
@onready var _vignette: ColorRect = %Vignette
@onready var _debug_overlay: Control = %DebugOverlay
@onready var _notification_output: RichTextLabel = %NotificationOutput

#endregion


#region State

var _service: FinalHudService

#endregion


#region Lifecycle

func _ready() -> void:
	if configuration == null:
		configuration = FinalHudConfiguration.new()

	_service = FinalHudService.new()
	_service.name = "FinalHudService"
	add_child(_service)

	var configuration_result := _service.configure(
		configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_status_bar.bind_service(_service)
	_navigation_rail.bind_service(_service)
	_module_viewport.bind_service(_service)

	_apply_effect_configuration()
	_register_default_modules()
	_bind_optional_services()

	var route_result := _service.activate_default_route()

	if route_result.is_failure():
		push_warning(
			route_result.get_error().get_message()
		)

#endregion


#region Private methods

func _register_default_modules() -> void:
	var modules: Array[HudModuleDefinition] = [
		_create_module(
			&"home",
			"HOME HUB",
			"HOME",
			&"007_home_hub",
			"res://packages/007_home_hub/scenes/home_hub_panel.tscn",
			10,
			Color("#32d8ff")
		),
		_create_module(
			&"voice",
			"VOICE HUB",
			"VOICE",
			&"006_voice_hub",
			"res://packages/006_voice_hub/scenes/voice_hub_panel.tscn",
			20,
			Color("#d6aa48")
		),
		_create_module(
			&"environment",
			"ENVIRONMENT",
			"ENV",
			&"009_environment_hub",
			"res://packages/009_environment_hub/scenes/environment_hub_panel.tscn",
			30,
			Color("#55f2a3")
		),
		_create_module(
			&"devices",
			"DEVICE HUB",
			"DEVICES",
			&"010_device_hub",
			"res://packages/010_device_hub/scenes/device_hub_panel.tscn",
			40,
			Color("#32d8ff")
		),
		_create_module(
			&"ai",
			"AI SYSTEM",
			"AI",
			&"011_ai_system",
			"res://packages/011_ai_system/scenes/ai_console_panel.tscn",
			50,
			Color("#d6aa48")
		),
		_create_module(
			&"automation",
			"AUTOMATION",
			"AUTO",
			&"012_automation",
			"res://packages/012_automation/scenes/automation_panel.tscn",
			60,
			Color("#55f2a3")
		),
		_create_module(
			&"diagnostics",
			"DIAGNOSTICS",
			"DIAG",
			&"013_diagnostics",
			"res://packages/013_diagnostics/scenes/diagnostics_panel.tscn",
			70,
			Color("#ffbf47")
		),
		_create_module(
			&"notifications",
			"NOTIFICATIONS",
			"NOTIFY",
			&"014_notification_center",
			"res://packages/014_notification_center/scenes/notification_center_panel.tscn",
			80,
			Color("#ff8b3d")
		),
	]

	for module in modules:
		if ResourceLoader.exists(module.scene_path):
			_service.register_module(module)


func _create_module(
	route_id: StringName,
	display_name: String,
	short_label: String,
	package_id: StringName,
	scene_path: String,
	sort_order: int,
	accent_color: Color
) -> HudModuleDefinition:
	var module := HudModuleDefinition.new()

	module.route_id = route_id
	module.display_name = display_name
	module.short_label = short_label
	module.package_id = package_id
	module.scene_path = scene_path
	module.sort_order = sort_order
	module.accent_color = accent_color
	module.enabled = true

	return module


func _apply_effect_configuration() -> void:
	_scanlines.visible = configuration.scanlines_enabled
	_vignette.visible = configuration.vignette_enabled
	_debug_overlay.visible = (
		configuration.debug_overlay_enabled
		and OS.is_debug_build()
	)

	var scanline_material := _scanlines.material as ShaderMaterial

	if scanline_material != null:
		scanline_material.set_shader_parameter(
			"opacity",
			configuration.scanline_opacity
		)

	var vignette_material := _vignette.material as ShaderMaterial

	if vignette_material != null:
		vignette_material.set_shader_parameter(
			"strength",
			configuration.vignette_strength
		)


func _bind_optional_services() -> void:
	var diagnostics := get_node_or_null("/root/Diagnostics")

	if diagnostics != null:
		diagnostics.health_state_changed.connect(
			_on_health_state_changed
		)

		_status_bar.set_health_state(
			diagnostics.get_health_state()
		)

	var notifications := get_node_or_null(
		"/root/NotificationCenter"
	)

	if notifications != null:
		notifications.notification_delivered.connect(
			_on_notification_delivered
		)


func _on_health_state_changed(
	_previous_state: SystemHealthState.Value,
	current_state: SystemHealthState.Value
) -> void:
	_status_bar.set_health_state(current_state)


func _on_notification_delivered(
	notification: HydraNotification
) -> void:
	var request := notification.get_request()

	_notification_output.text = (
		"[color=#d6aa48]%s[/color]\n"
		+ "[color=#32d8ff]%s[/color]"
	) % [
		request.get_title(),
		request.get_message(),
	]

	_notification_output.visible = true

	var tween := create_tween()
	tween.tween_interval(4.0)
	tween.tween_property(
		_notification_output,
		"modulate:a",
		0.0,
		0.4
	)
	tween.tween_callback(
		func() -> void:
			_notification_output.visible = false
			_notification_output.modulate.a = 1.0
	)

#endregion
'@

$files["packages/020_final_hud/shaders/scanlines.gdshader"] = @'
shader_type canvas_item;

uniform float opacity : hint_range(0.0, 1.0) = 0.14;
uniform float density : hint_range(100.0, 2000.0) = 1080.0;
uniform float speed : hint_range(-10.0, 10.0) = 0.35;

void fragment() {
	float scanline = sin(
		(UV.y * density) + (TIME * speed)
	);

	float line_strength = smoothstep(
		0.15,
		1.0,
		scanline
	);

	COLOR = vec4(
		0.05,
		0.40,
		0.58,
		line_strength * opacity
	);
}
'@

$files["packages/020_final_hud/shaders/vignette.gdshader"] = @'
shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.42;
uniform float softness : hint_range(0.01, 1.0) = 0.45;

void fragment() {
	vec2 centered_uv = UV - vec2(0.5);
	float distance_from_center = length(centered_uv);
	float vignette = smoothstep(
		softness,
		1.0,
		distance_from_center * 1.7
	);

	COLOR = vec4(
		0.0,
		0.01,
		0.02,
		vignette * strength
	);
}
'@

$files["packages/020_final_hud/scenes/tactical_navigation_rail.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/020_final_hud/scripts/presentation/tactical_navigation_rail.gd" id="1"]

[node name="TacticalNavigationRail" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 260.0
offset_bottom = 900.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"tactical_navigation_rail"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00392157, 0.0156863, 0.027451, 0.96)

[node name="Accent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 0.0
offset_top = 0.0
offset_right = 5.0
offset_bottom = 900.0
color = Color(0.839216, 0.666667, 0.282353, 1)

[node name="Header" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 18.0
offset_top = 20.0
offset_right = 242.0
offset_bottom = 58.0
bbcode_enabled = true
text = "[color=#32d8ff]MODULE MATRIX[/color]"
fit_content = true
scroll_active = false

[node name="ActiveLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 18.0
offset_top = 66.0
offset_right = 242.0
offset_bottom = 94.0
bbcode_enabled = true
text = "[color=#d6aa48]ACTIVE  //  NONE[/color]"
fit_content = true
scroll_active = false

[node name="ButtonLayer" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 1
'@

$files["packages/020_final_hud/scenes/system_status_bar.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/020_final_hud/scripts/presentation/system_status_bar.gd" id="1"]

[node name="SystemStatusBar" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 1920.0
offset_bottom = 72.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"system_status_bar"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00392157, 0.0156863, 0.027451, 0.98)

[node name="BottomAccent" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 0.0
offset_top = 68.0
offset_right = 1920.0
offset_bottom = 72.0
color = Color(0.196078, 0.847059, 1, 0.7)

[node name="BrandLabel" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 24.0
offset_top = 16.0
offset_right = 410.0
offset_bottom = 54.0
bbcode_enabled = true
text = "[font_size=24][color=#32d8ff]HYDRA AI HOME OS[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="RouteLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 450.0
offset_top = 22.0
offset_right = 850.0
offset_bottom = 52.0
text = "MODULE  //  NONE"
fit_content = true
scroll_active = false

[node name="HealthLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 900.0
offset_top = 22.0
offset_right = 1210.0
offset_bottom = 52.0
text = "SYSTEM  //  UNKNOWN"
fit_content = true
scroll_active = false

[node name="ConnectionLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 1250.0
offset_top = 22.0
offset_right = 1510.0
offset_bottom = 52.0
bbcode_enabled = true
text = "[color=#55f2a3]LINK  //  LOCAL[/color]"
fit_content = true
scroll_active = false

[node name="ClockLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 1570.0
offset_top = 22.0
offset_right = 1896.0
offset_bottom = 52.0
text = "0000-00-00  //  00:00:00"
fit_content = true
scroll_active = false
'@

$files["packages/020_final_hud/scenes/module_viewport.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/020_final_hud/scripts/presentation/module_viewport.gd" id="1"]

[node name="ModuleViewport" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 1540.0
offset_bottom = 900.0
mouse_filter = 1
clip_contents = true
script = ExtResource("1")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00196078, 0.00784314, 0.0117647, 1)

[node name="GridA" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 20.0
offset_top = 20.0
offset_right = 1520.0
offset_bottom = 22.0
color = Color(0.196078, 0.847059, 1, 0.18)

[node name="GridB" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 20.0
offset_top = 878.0
offset_right = 1520.0
offset_bottom = 880.0
color = Color(0.839216, 0.666667, 0.282353, 0.18)

[node name="MountPoint" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 20.0
offset_top = 24.0
offset_right = 1520.0
offset_bottom = 876.0
mouse_filter = 1
clip_contents = true

[node name="LoadingLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 520.0
offset_top = 410.0
offset_right = 1020.0
offset_bottom = 462.0
bbcode_enabled = true
text = "[font_size=24][color=#32d8ff]AWAITING MODULE LINK[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="ErrorLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 420.0
offset_top = 390.0
offset_right = 1120.0
offset_bottom = 500.0
bbcode_enabled = true
text = "[color=#ff4f62]MODULE MOUNT FAILURE[/color]"
scroll_active = false
'@

$files["packages/020_final_hud/scenes/final_hud.tscn"] = @'
[gd_scene load_steps=9 format=3]

[ext_resource type="Script" path="res://packages/020_final_hud/scripts/presentation/final_hud_shell.gd" id="1"]
[ext_resource type="Resource" path="res://packages/020_final_hud/resources/default_final_hud_configuration.tres" id="2"]
[ext_resource type="PackedScene" path="res://packages/020_final_hud/scenes/system_status_bar.tscn" id="3"]
[ext_resource type="PackedScene" path="res://packages/020_final_hud/scenes/tactical_navigation_rail.tscn" id="4"]
[ext_resource type="PackedScene" path="res://packages/020_final_hud/scenes/module_viewport.tscn" id="5"]
[ext_resource type="Shader" path="res://packages/020_final_hud/shaders/scanlines.gdshader" id="6"]
[ext_resource type="Shader" path="res://packages/020_final_hud/shaders/vignette.gdshader" id="7"]
[ext_resource type="PackedScene" path="res://packages/019_debug_tools/scenes/performance_overlay.tscn" id="8"]

[sub_resource type="ShaderMaterial" id="ShaderMaterial_scanlines"]
shader = ExtResource("6")
shader_parameter/opacity = 0.14
shader_parameter/density = 1080.0
shader_parameter/speed = 0.35

[sub_resource type="ShaderMaterial" id="ShaderMaterial_vignette"]
shader = ExtResource("7")
shader_parameter/strength = 0.42
shader_parameter/softness = 0.45

[node name="FinalHud" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1")
configuration = ExtResource("2")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.00196078, 0.00784314, 0.0117647, 1)

[node name="SystemStatusBar" parent="." instance=ExtResource("3")]
unique_name_in_owner = true
layout_mode = 0
offset_right = 1920.0
offset_bottom = 72.0

[node name="NavigationRail" parent="." instance=ExtResource("4")]
unique_name_in_owner = true
layout_mode = 0
offset_top = 72.0
offset_right = 260.0
offset_bottom = 972.0

[node name="ModuleViewport" parent="." instance=ExtResource("5")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 260.0
offset_top = 72.0
offset_right = 1800.0
offset_bottom = 972.0

[node name="RightTelemetryRail" type="ColorRect" parent="."]
layout_mode = 0
offset_left = 1800.0
offset_top = 72.0
offset_right = 1920.0
offset_bottom = 972.0
color = Color(0.00392157, 0.0156863, 0.027451, 0.96)

[node name="TelemetryAccent" type="ColorRect" parent="RightTelemetryRail"]
layout_mode = 0
offset_left = 0.0
offset_right = 4.0
offset_bottom = 900.0
color = Color(0.839216, 0.666667, 0.282353, 0.7)

[node name="BottomCommandBar" type="ColorRect" parent="."]
layout_mode = 0
offset_top = 972.0
offset_right = 1920.0
offset_bottom = 1080.0
color = Color(0.00392157, 0.0156863, 0.027451, 0.98)

[node name="BottomAccent" type="ColorRect" parent="BottomCommandBar"]
layout_mode = 0
offset_right = 1920.0
offset_bottom = 4.0
color = Color(0.196078, 0.847059, 1, 0.65)

[node name="CommandHint" type="RichTextLabel" parent="BottomCommandBar"]
layout_mode = 0
offset_left = 280.0
offset_top = 34.0
offset_right = 1500.0
offset_bottom = 72.0
bbcode_enabled = true
text = "[color=#6e8794]HYDRA COMMAND CHANNEL READY  //  SELECT MODULE FROM LEFT MATRIX[/color]"
fit_content = true
scroll_active = false

[node name="NotificationOutput" type="RichTextLabel" parent="."]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 1320.0
offset_top = 790.0
offset_right = 1770.0
offset_bottom = 940.0
bbcode_enabled = true
text = "[color=#d6aa48]NOTIFICATION[/color]"
scroll_active = false

[node name="DebugOverlay" parent="." instance=ExtResource("8")]
unique_name_in_owner = true
visible = false
layout_mode = 0
offset_left = 1370.0
offset_top = 88.0
offset_right = 1790.0
offset_bottom = 226.0

[node name="Scanlines" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
material = SubResource("ShaderMaterial_scanlines")
color = Color(1, 1, 1, 1)

[node name="Vignette" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
material = SubResource("ShaderMaterial_vignette")
color = Color(1, 1, 1, 1)
'@

$files["packages/020_final_hud/demo/final_hud_demo.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="PackedScene" path="res://packages/020_final_hud/scenes/final_hud.tscn" id="1"]

[node name="FinalHudDemo" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="FinalHud" parent="." instance=ExtResource("1")]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
'@

$files["packages/020_final_hud/tests/unit/test_hud_shell_state.gd"] = @'
class_name HudShellStateTest
extends RefCounted
## Provides HudShellState tests.


#region Tests

static func run() -> void:
	var state := HudShellState.new(
		EntityId.generate()
	)

	assert(state.activate_route(&"home").is_success())
	assert(state.get_active_route_id() == &"home")

	state.set_shell_locked(true)

	assert(state.is_shell_locked())
	assert(state.activate_route(&"ai").is_failure())

#endregion
'@

$files["packages/020_final_hud/tests/unit/test_hud_module_definition.gd"] = @'
class_name HudModuleDefinitionTest
extends RefCounted
## Provides HUD module validation tests.


#region Tests

static func run() -> void:
	var module := HudModuleDefinition.new()

	assert(module.validate().is_failure())

	module.route_id = &"test"
	module.display_name = "TEST"
	module.package_id = &"test_package"
	module.scene_path = "res://test_scene.tscn"

	assert(module.validate().is_success())

#endregion
'@

$files["packages/020_final_hud/tests/integration/test_final_hud_service.gd"] = @'
class_name FinalHudServiceTest
extends RefCounted
## Provides Final HUD service composition tests.


#region Tests

static func run() -> void:
	var service := FinalHudService.new()
	var configuration := FinalHudConfiguration.new()

	assert(service.configure(configuration).is_success())

	var module := HudModuleDefinition.new()
	module.route_id = &"test"
	module.display_name = "TEST"
	module.package_id = &"test_package"
	module.scene_path = (
		"res://packages/020_final_hud/demo/final_hud_demo.tscn"
	)

	assert(service.register_module(module).is_success())

#endregion
'@

# =============================================================================
# AUTOLOADS, ROOT SCENE AND DOCUMENTATION
# =============================================================================

$files["autoload/debug_tools.gd"] = @'
extends DebugToolsService
## Global Debug Tools service.
##
## Runtime composition must configure the command registry.
'@

$files["autoload/final_hud.gd"] = @'
extends FinalHudService
## Global Final HUD routing service.
##
## Runtime composition must configure and register modules.
'@

$files["docs/package-dependencies-019-020.md"] = @'
# Package dependencies 019–020

```text
019_debug_tools
├── 001_foundation
├── 002_design_system
├── 003_widget_library
├── 004_animation_system
├── 013_diagnostics
└── 014_notification_center

020_final_hud
├── 001_foundation
├── 002_design_system
├── 003_widget_library
├── 004_animation_system
├── 005_fx_system
├── 006_voice_hub
├── 007_home_hub
├── 008_central_hub
├── 009_environment_hub
├── 010_device_hub
├── 011_ai_system
├── 012_automation
├── 013_diagnostics
├── 014_notification_center
├── 015_plugin_sdk
├── 016_android
├── 017_installer
├── 018_boot_loader
└── 019_debug_tools
'@
Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing packages 019-020..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

Assert-GeneratedFiles -FileMap $files

Write-Host ""
Write-Host "Packages 019-020 installed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Optional autoloads:" -ForegroundColor Cyan
Write-Host "DebugTools res://autoload/debug_tools.gd"
Write-Host "FinalHud res://autoload/final_hud.gd"
Write-Host ""
Write-Host "Production scene:" -ForegroundColor Cyan
Write-Host "res://packages/020_final_hud/scenes/final_hud.tscn"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(hud): implement packages 019-020"'
Write-Host "git push"