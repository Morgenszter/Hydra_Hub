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

function Test-GeneratedFiles {
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
# PACKAGE 013 — DIAGNOSTICS
# =============================================================================

$files["packages/013_diagnostics/package.cfg"] = @'
[package]

id="013_diagnostics"
name="Diagnostics"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system"
)
'@

$files["packages/013_diagnostics/README.md"] = @'
# Package 013 — Diagnostics

Diagnostics provides health checks, runtime metrics, incident records and the
system diagnostics panel for HYDRA AI HOME OS.

The package observes other modules through registered probes and EventBus
events. It does not modify feature-module state unless an explicit recovery
operation is invoked by another package.
'@

$files["packages/013_diagnostics/CHANGELOG.md"] = @'
# Diagnostics changelog

## [0.1.0] - 2026-07-17

### Added

- Added diagnostic severity and health-state definitions.
- Added immutable diagnostic finding model.
- Added diagnostic probe contract.
- Added diagnostics service.
- Added runtime probe implementation.
- Added health metric widget.
- Added diagnostics panel.
- Added demo scene and tests.
'@

$files["packages/013_diagnostics/docs/architecture.md"] = @'
# Diagnostics architecture

Diagnostics is an observability package.

Probes collect isolated health information.

DiagnosticsService executes probes, aggregates findings and publishes health
changes.

Presentation components display normalized findings without depending on probe
implementations.
'@

$files["packages/013_diagnostics/docs/operations.md"] = @'
# Diagnostics operations

A diagnostic probe must be deterministic, bounded and non-destructive.

Probe failures are converted into critical findings.

Sensitive values must not be included in findings, logs or exported diagnostic
reports.

Health checks should remain safe to execute repeatedly.
'@

$files["packages/013_diagnostics/resources/diagnostics_configuration.gd"] = @'
class_name DiagnosticsConfiguration
extends Resource
## Stores Diagnostics runtime configuration.


#region Scheduling

@export_group("Scheduling")
@export var automatic_checks_enabled: bool = true
@export_range(1.0, 3600.0, 1.0) var check_interval_seconds: float = 15.0

#endregion


#region Retention

@export_group("Retention")
@export_range(1, 10000, 1) var maximum_findings: int = 500
@export_range(1, 1000, 1) var maximum_incidents: int = 100

#endregion


#region Presentation

@export_group("Presentation")
@export var show_healthy_findings: bool = true
@export var show_resolved_incidents: bool = false

#endregion
'@

$files["packages/013_diagnostics/resources/default_diagnostics_configuration.tres"] = @'
[gd_resource type="Resource" script_class="DiagnosticsConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/013_diagnostics/resources/diagnostics_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
automatic_checks_enabled = true
check_interval_seconds = 15.0
maximum_findings = 500
maximum_incidents = 100
show_healthy_findings = true
show_resolved_incidents = false
'@

$files["packages/013_diagnostics/scripts/domain/diagnostic_severity.gd"] = @'
class_name DiagnosticSeverity
extends RefCounted
## Defines diagnostic finding severity.


#region Values

enum Value {
	TRACE,
	INFO,
	NOTICE,
	WARNING,
	ERROR,
	CRITICAL,
}

#endregion


#region Public API

## Returns a stable severity identifier.
static func to_string_name(severity: Value) -> StringName:
	match severity:
		Value.TRACE:
			return &"trace"
		Value.INFO:
			return &"info"
		Value.NOTICE:
			return &"notice"
		Value.WARNING:
			return &"warning"
		Value.ERROR:
			return &"error"
		Value.CRITICAL:
			return &"critical"
		_:
			return &"unknown"


## Returns a presentation color.
static func to_color(severity: Value) -> Color:
	match severity:
		Value.TRACE:
			return Color("#40515b")
		Value.INFO:
			return Color("#32d8ff")
		Value.NOTICE:
			return Color("#55f2a3")
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

$files["packages/013_diagnostics/scripts/domain/system_health_state.gd"] = @'
class_name SystemHealthState
extends RefCounted
## Defines aggregated system health states.


#region Values

enum Value {
	UNKNOWN,
	HEALTHY,
	DEGRADED,
	UNHEALTHY,
	CRITICAL,
}

#endregion


#region Public API

## Returns a stable health-state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.HEALTHY:
			return &"healthy"
		Value.DEGRADED:
			return &"degraded"
		Value.UNHEALTHY:
			return &"unhealthy"
		Value.CRITICAL:
			return &"critical"
		_:
			return &"unknown"


## Returns a presentation color.
static func to_color(state: Value) -> Color:
	match state:
		Value.HEALTHY:
			return Color("#55f2a3")
		Value.DEGRADED:
			return Color("#ffbf47")
		Value.UNHEALTHY:
			return Color("#ff7a4d")
		Value.CRITICAL:
			return Color("#ff4f62")
		_:
			return Color("#40515b")

#endregion
'@

$files["packages/013_diagnostics/scripts/domain/diagnostic_finding.gd"] = @'
class_name DiagnosticFinding
extends ValueObject
## Represents one immutable diagnostic finding.


#region State

var _finding_id: StringName
var _probe_id: StringName
var _code: StringName
var _title: String
var _message: String
var _severity: DiagnosticSeverity.Value
var _healthy: bool
var _recorded_at_unix_ms: int
var _metadata: Dictionary[StringName, Variant]

#endregion


#region Construction

## Creates an immutable diagnostic finding.
func _init(
	probe_id: StringName,
	code: StringName,
	title: String,
	message: String,
	severity: DiagnosticSeverity.Value,
	healthy: bool,
	metadata: Dictionary[StringName, Variant] = {}
) -> void:
	assert(not probe_id.is_empty(), "DiagnosticFinding requires probe_id.")
	assert(not code.is_empty(), "DiagnosticFinding requires code.")
	assert(
		not title.strip_edges().is_empty(),
		"DiagnosticFinding requires title."
	)

	_finding_id = StringName(UUID.v4())
	_probe_id = probe_id
	_code = code
	_title = title.strip_edges()
	_message = message.strip_edges()
	_severity = severity
	_healthy = healthy
	_recorded_at_unix_ms = int(
		Time.get_unix_time_from_system() * 1000.0
	)
	_metadata = metadata.duplicate(true)

#endregion


#region Public API

func get_finding_id() -> StringName:
	return _finding_id


func get_probe_id() -> StringName:
	return _probe_id


func get_code() -> StringName:
	return _code


func get_title() -> String:
	return _title


func get_message() -> String:
	return _message


func get_severity() -> DiagnosticSeverity.Value:
	return _severity


func is_healthy() -> bool:
	return _healthy


func get_recorded_at_unix_ms() -> int:
	return _recorded_at_unix_ms


func get_metadata() -> Dictionary[StringName, Variant]:
	return _metadata.duplicate(true)

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_finding_id,
		_probe_id,
		_code,
		_title,
		_message,
		_severity,
		_healthy,
		_recorded_at_unix_ms,
		_metadata,
	]

#endregion
'@

$files["packages/013_diagnostics/scripts/contracts/diagnostic_probe_port.gd"] = @'
@abstract
class_name DiagnosticProbePort
extends RefCounted
## Defines a diagnostic health-check boundary.


#region Public API

## Returns the stable probe identifier.
@abstract
func get_probe_id() -> StringName


## Returns the human-readable probe name.
@abstract
func get_display_name() -> String


## Executes the probe and returns Array[DiagnosticFinding].
@abstract
func run_probe() -> Result

#endregion
'@

$files["packages/013_diagnostics/scripts/infrastructure/runtime_diagnostic_probe.gd"] = @'
class_name RuntimeDiagnosticProbe
extends DiagnosticProbePort
## Reports Godot runtime and memory diagnostics.


#region Constants

const PROBE_ID: StringName = &"runtime"

#endregion


#region DiagnosticProbePort

func get_probe_id() -> StringName:
	return PROBE_ID


func get_display_name() -> String:
	return "GODOT RUNTIME"


func run_probe() -> Result:
	var findings: Array[DiagnosticFinding] = []
	var static_memory := Performance.get_monitor(
		Performance.MEMORY_STATIC
	)
	var object_count := Performance.get_monitor(
		Performance.OBJECT_COUNT
	)
	var node_count := Performance.get_monitor(
		Performance.OBJECT_NODE_COUNT
	)
	var fps := Performance.get_monitor(
		Performance.TIME_FPS
	)

	findings.append(
		DiagnosticFinding.new(
			PROBE_ID,
			&"runtime.engine",
			"ENGINE RUNTIME",
			"Godot runtime is responding.",
			DiagnosticSeverity.Value.NOTICE,
			true,
			{
				&"version": Engine.get_version_info(),
				&"fps": fps,
			}
		)
	)

	var memory_warning := static_memory >= 1073741824.0

	findings.append(
		DiagnosticFinding.new(
			PROBE_ID,
			&"runtime.memory",
			"STATIC MEMORY",
			"Static memory: %.2f MiB" % (
				static_memory / 1048576.0
			),
			(
				DiagnosticSeverity.Value.WARNING
				if memory_warning
				else DiagnosticSeverity.Value.INFO
			),
			not memory_warning,
			{
				&"bytes": static_memory,
			}
		)
	)

	findings.append(
		DiagnosticFinding.new(
			PROBE_ID,
			&"runtime.objects",
			"OBJECT INVENTORY",
			"Objects: %d  Nodes: %d" % [
				int(object_count),
				int(node_count),
			],
			DiagnosticSeverity.Value.INFO,
			true,
			{
				&"object_count": object_count,
				&"node_count": node_count,
			}
		)
	)

	return Result.success(findings)

#endregion
'@

$files["packages/013_diagnostics/scripts/application/diagnostics_service.gd"] = @'
class_name DiagnosticsService
extends Node
## Coordinates diagnostic probes and aggregated system health.


#region Signals

signal check_started()
signal check_completed(
	findings: Array[DiagnosticFinding],
	health_state: SystemHealthState.Value
)
signal health_state_changed(
	previous_state: SystemHealthState.Value,
	current_state: SystemHealthState.Value
)
signal probe_failed(
	probe_id: StringName,
	error: DomainError
)

#endregion


#region State

var _configuration: DiagnosticsConfiguration
var _probes: Dictionary[StringName, DiagnosticProbePort] = {}
var _findings: Array[DiagnosticFinding] = []
var _health_state: SystemHealthState.Value = \
	SystemHealthState.Value.UNKNOWN
var _timer: Timer

#endregion


#region Lifecycle

func _ready() -> void:
	_timer = Timer.new()
	_timer.name = "DiagnosticsTimer"
	_timer.one_shot = false
	_timer.timeout.connect(run_all)
	add_child(_timer)

#endregion


#region Public API

## Configures Diagnostics.
func configure(
	configuration: DiagnosticsConfiguration
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Diagnostics configuration cannot be null."
			)
		)

	_configuration = configuration
	_timer.wait_time = configuration.check_interval_seconds

	return Result.success()


## Registers a diagnostic probe.
func register_probe(
	probe: DiagnosticProbePort
) -> Result:
	if probe == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Diagnostic probe cannot be null."
			)
		)

	var probe_id := probe.get_probe_id()

	if probe_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Diagnostic probe requires probe_id."
			)
		)

	if _probes.has(probe_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.SERVICE_ALREADY_REGISTERED,
				"Diagnostic probe is already registered.",
				{&"probe_id": probe_id}
			)
		)

	_probes[probe_id] = probe

	return Result.success()


## Starts automatic diagnostics.
func start() -> Result:
	if _configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Diagnostics is not configured."
			)
		)

	if _configuration.automatic_checks_enabled:
		_timer.start()

	return run_all()


## Stops automatic diagnostics.
func stop() -> void:
	_timer.stop()


## Executes every registered probe.
func run_all() -> Result:
	if _configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Diagnostics is not configured."
			)
		)

	check_started.emit()

	var next_findings: Array[DiagnosticFinding] = []

	for probe: DiagnosticProbePort in _probes.values():
		var result := probe.run_probe()

		if result.is_failure():
			var error := result.get_error()

			next_findings.append(
				DiagnosticFinding.new(
					probe.get_probe_id(),
					&"probe.execution_failed",
					"PROBE EXECUTION FAILED",
					error.get_message(),
					DiagnosticSeverity.Value.CRITICAL,
					false,
					{
						&"error": error.to_dictionary(),
					}
				)
			)
			probe_failed.emit(probe.get_probe_id(), error)
			continue

		for finding in result.get_value():
			if finding is DiagnosticFinding:
				next_findings.append(finding)

	_findings = next_findings

	while _findings.size() > _configuration.maximum_findings:
		_findings.pop_front()

	var previous_state := _health_state
	_health_state = _calculate_health_state(_findings)

	if previous_state != _health_state:
		health_state_changed.emit(
			previous_state,
			_health_state
		)

	check_completed.emit(
		get_findings(),
		_health_state
	)

	return Result.success(get_findings())


## Returns current findings.
func get_findings() -> Array[DiagnosticFinding]:
	return _findings.duplicate()


## Returns aggregated system health.
func get_health_state() -> SystemHealthState.Value:
	return _health_state

#endregion


#region Private methods

func _calculate_health_state(
	findings: Array[DiagnosticFinding]
) -> SystemHealthState.Value:
	if findings.is_empty():
		return SystemHealthState.Value.UNKNOWN

	var warning_found := false
	var error_found := false

	for finding in findings:
		if finding.is_healthy():
			continue

		match finding.get_severity():
			DiagnosticSeverity.Value.CRITICAL:
				return SystemHealthState.Value.CRITICAL
			DiagnosticSeverity.Value.ERROR:
				error_found = true
			DiagnosticSeverity.Value.WARNING:
				warning_found = true

	if error_found:
		return SystemHealthState.Value.UNHEALTHY

	if warning_found:
		return SystemHealthState.Value.DEGRADED

	return SystemHealthState.Value.HEALTHY

#endregion
'@

$files["packages/013_diagnostics/scripts/presentation/health_metric_widget.gd"] = @'
class_name HealthMetricWidget
extends WidgetBase
## Displays one diagnostic finding.


#region Nodes

@onready var _indicator: ColorRect = %Indicator
@onready var _title_label: RichTextLabel = %TitleLabel
@onready var _message_label: RichTextLabel = %MessageLabel
@onready var _severity_label: RichTextLabel = %SeverityLabel

#endregion


#region Public API

## Applies one diagnostic finding.
func apply_finding(
	finding: DiagnosticFinding
) -> void:
	assert(
		finding != null,
		"HealthMetricWidget requires a finding."
	)

	if not is_node_ready():
		return

	_indicator.color = DiagnosticSeverity.to_color(
		finding.get_severity()
	)
	_title_label.text = finding.get_title()
	_message_label.text = finding.get_message()
	_severity_label.text = String(
		DiagnosticSeverity.to_string_name(
			finding.get_severity()
		)
	).to_upper()

#endregion
'@

$files["packages/013_diagnostics/scripts/presentation/diagnostics_panel.gd"] = @'
class_name DiagnosticsPanel
extends PanelBase
## Displays aggregated diagnostics and current findings.


#region Constants

const CARD_WIDTH: float = 420.0
const CARD_HEIGHT: float = 130.0
const CARD_START_X: float = 52.0
const CARD_START_Y: float = 190.0
const CARD_HORIZONTAL_GAP: float = 22.0
const CARD_VERTICAL_GAP: float = 18.0
const CARD_COLUMNS: int = 2

#endregion


#region Nodes

@onready var _health_indicator: ColorRect = %HealthIndicator
@onready var _health_label: RichTextLabel = %HealthLabel
@onready var _summary_label: RichTextLabel = %SummaryLabel
@onready var _finding_layer: Control = %FindingLayer
@onready var _error_label: RichTextLabel = %ErrorLabel

#endregion


#region State

var _service: DiagnosticsService
var _metric_scene: PackedScene = preload(
	"res://packages/013_diagnostics/scenes/health_metric_widget.tscn"
)

#endregion


#region Public API

## Binds this panel to Diagnostics.
func bind_service(service: DiagnosticsService) -> void:
	assert(service != null, "Diagnostics service cannot be null.")

	_disconnect_service()
	_service = service

	_service.check_completed.connect(_on_check_completed)
	_service.probe_failed.connect(_on_probe_failed)


## Requests an immediate diagnostic check.
func refresh() -> Result:
	if _service == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Diagnostics panel is not bound."
			)
		)

	return _service.run_all()

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.check_completed.is_connected(
		_on_check_completed
	):
		_service.check_completed.disconnect(
			_on_check_completed
		)

	if _service.probe_failed.is_connected(_on_probe_failed):
		_service.probe_failed.disconnect(_on_probe_failed)


func _on_check_completed(
	findings: Array[DiagnosticFinding],
	health_state: SystemHealthState.Value
) -> void:
	_error_label.visible = false
	_health_indicator.color = SystemHealthState.to_color(
		health_state
	)
	_health_label.text = (
		"SYSTEM HEALTH  //  %s"
		% String(
			SystemHealthState.to_string_name(health_state)
		).to_upper()
	)

	var unhealthy_count := 0

	for finding in findings:
		if not finding.is_healthy():
			unhealthy_count += 1

	_summary_label.text = (
		"FINDINGS  //  %d    ACTIVE ISSUES  //  %d"
		% [
			findings.size(),
			unhealthy_count,
		]
	)

	_render_findings(findings)


func _on_probe_failed(
	probe_id: StringName,
	error: DomainError
) -> void:
	_error_label.visible = true
	_error_label.text = (
		"[color=#ff4f62]PROBE FAILURE  //  %s[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % [
		String(probe_id).to_upper(),
		error.get_message(),
	]


func _render_findings(
	findings: Array[DiagnosticFinding]
) -> void:
	for child in _finding_layer.get_children():
		child.queue_free()

	for index in findings.size():
		var widget := (
			_metric_scene.instantiate()
			as HealthMetricWidget
		)
		var column := index % CARD_COLUMNS
		var row := index / CARD_COLUMNS

		widget.position = Vector2(
			CARD_START_X + (
				column * (
					CARD_WIDTH + CARD_HORIZONTAL_GAP
				)
			),
			CARD_START_Y + (
				row * (
					CARD_HEIGHT + CARD_VERTICAL_GAP
				)
			)
		)
		widget.size = Vector2(CARD_WIDTH, CARD_HEIGHT)

		_finding_layer.add_child(widget)
		widget.apply_finding(findings[index])

#endregion
'@

$files["packages/013_diagnostics/scenes/health_metric_widget.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/013_diagnostics/scripts/presentation/health_metric_widget.gd" id="1"]

[node name="HealthMetricWidget" type="Control"]
custom_minimum_size = Vector2(420, 130)
layout_mode = 3
anchors_preset = 0
offset_right = 420.0
offset_bottom = 130.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"health_metric_widget"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.9)

[node name="Indicator" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 12.0
offset_top = 12.0
offset_right = 18.0
offset_bottom = 118.0
mouse_filter = 2
color = Color(0.196078, 0.847059, 1, 1)

[node name="TitleLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 12.0
offset_right = 306.0
offset_bottom = 40.0
bbcode_enabled = true
text = "[color=#32d8ff]DIAGNOSTIC FINDING[/color]"
fit_content = true
scroll_active = false

[node name="SeverityLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 316.0
offset_top = 12.0
offset_right = 404.0
offset_bottom = 40.0
text = "INFO"
fit_content = true
scroll_active = false

[node name="MessageLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 34.0
offset_top = 50.0
offset_right = 404.0
offset_bottom = 114.0
text = "Diagnostic message."
scroll_active = false
'@

$files["packages/013_diagnostics/scenes/diagnostics_panel.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/013_diagnostics/scripts/presentation/diagnostics_panel.gd" id="1"]

[node name="DiagnosticsPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 980.0
offset_bottom = 900.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"diagnostics_panel"
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
text = "[font_size=30][color=#32d8ff]DIAGNOSTICS[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 850.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]SYSTEM HEALTH AND TELEMETRY  //  CHANNEL 013[/color]"
fit_content = true
scroll_active = false

[node name="HealthIndicator" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 116.0
offset_right = 62.0
offset_bottom = 152.0
color = Color(0.25098, 0.317647, 0.356863, 1)

[node name="HealthLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 78.0
offset_top = 112.0
offset_right = 490.0
offset_bottom = 146.0
text = "SYSTEM HEALTH  //  UNKNOWN"
fit_content = true
scroll_active = false

[node name="SummaryLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 510.0
offset_top = 112.0
offset_right = 926.0
offset_bottom = 146.0
bbcode_enabled = true
text = "[color=#d6aa48]FINDINGS  //  0    ACTIVE ISSUES  //  0[/color]"
fit_content = true
scroll_active = false

[node name="FindingLayer" type="Control" parent="."]
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
offset_right = 926.0
offset_bottom = 884.0
bbcode_enabled = true
text = "[color=#ff4f62]DIAGNOSTIC FAILURE[/color]"
scroll_active = false
'@

$files["packages/013_diagnostics/demo/diagnostics_demo.gd"] = @'
class_name DiagnosticsDemo
extends Control
## Demonstrates Diagnostics with the runtime probe.


#region Nodes

@onready var _panel: DiagnosticsPanel = %DiagnosticsPanel

#endregion


#region State

var _service: DiagnosticsService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = DiagnosticsService.new()
	_service.name = "DiagnosticsService"
	add_child(_service)

	var configuration := DiagnosticsConfiguration.new()
	var probe := RuntimeDiagnosticProbe.new()

	var configuration_result := _service.configure(
		configuration
	)

	if configuration_result.is_failure():
		push_error(
			configuration_result.get_error().get_message()
		)
		return

	_service.register_probe(probe)
	_panel.bind_service(_service)
	_service.start()

#endregion
'@

$files["packages/013_diagnostics/demo/diagnostics_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/013_diagnostics/demo/diagnostics_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/013_diagnostics/scenes/diagnostics_panel.tscn" id="2"]

[node name="DiagnosticsDemo" type="Control"]
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

[node name="DiagnosticsPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 470.0
offset_top = 90.0
offset_right = 1450.0
offset_bottom = 990.0
'@

$files["packages/013_diagnostics/tests/unit/test_diagnostic_finding.gd"] = @'
class_name DiagnosticFindingTest
extends RefCounted
## Provides DiagnosticFinding tests.


#region Tests

static func run() -> void:
	var finding := DiagnosticFinding.new(
		&"test_probe",
		&"test.code",
		"TEST FINDING",
		"System operational.",
		DiagnosticSeverity.Value.INFO,
		true
	)

	assert(finding.get_probe_id() == &"test_probe")
	assert(finding.get_code() == &"test.code")
	assert(finding.is_healthy())
	assert(
		finding.get_severity()
		== DiagnosticSeverity.Value.INFO
	)

#endregion
'@

$files["packages/013_diagnostics/tests/integration/test_diagnostics_service.gd"] = @'
class_name DiagnosticsServiceTest
extends RefCounted
## Provides Diagnostics service composition tests.


#region Tests

static func run() -> void:
	var service := DiagnosticsService.new()
	var configuration := DiagnosticsConfiguration.new()
	var probe := RuntimeDiagnosticProbe.new()

	assert(service.configure(configuration).is_success())
	assert(service.register_probe(probe).is_success())

#endregion
'@

# =============================================================================
# PACKAGE 014 — NOTIFICATION CENTER
# =============================================================================

$files["packages/014_notification_center/package.cfg"] = @'
[package]

id="014_notification_center"
name="Notification Center"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation",
	"002_design_system",
	"003_widget_library",
	"004_animation_system"
)
'@

$files["packages/014_notification_center/README.md"] = @'
# Package 014 — Notification Center

Notification Center owns notification delivery, prioritization, acknowledgement,
expiration and notification history.

Feature packages submit normalized notifications through NotificationCenter.
'@

$files["packages/014_notification_center/CHANGELOG.md"] = @'
# Notification Center changelog

## [0.1.0] - 2026-07-17

### Added

- Added notification priority and state definitions.
- Added immutable notification request.
- Added notification aggregate.
- Added notification repository contract.
- Added in-memory repository.
- Added Notification Center service.
- Added notification toast and center panel.
- Added demo scene and tests.
'@

$files["packages/014_notification_center/docs/architecture.md"] = @'
# Notification Center architecture

Notification Center normalizes messages produced by other modules.

Notifications are immutable after creation except for lifecycle state.

Presentation components consume notifications through the application service.

Desktop-native notification adapters can be added behind infrastructure ports.
'@

$files["packages/014_notification_center/resources/notification_configuration.gd"] = @'
class_name NotificationConfiguration
extends Resource
## Stores Notification Center runtime configuration.


#region Retention

@export_group("Retention")
@export_range(1, 10000, 1) var maximum_history: int = 500
@export_range(1.0, 86400.0, 1.0) var default_duration_seconds: float = 8.0

#endregion


#region Behavior

@export_group("Behavior")
@export var automatically_expire_notifications: bool = true
@export var automatically_acknowledge_expired: bool = false
@export var play_notification_audio: bool = true

#endregion


#region Presentation

@export_group("Presentation")
@export_range(1, 10, 1) var maximum_visible_toasts: int = 4
@export var show_acknowledged_notifications: bool = true

#endregion
'@

$files["packages/014_notification_center/resources/default_notification_configuration.tres"] = @'
[gd_resource type="Resource" script_class="NotificationConfiguration" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/014_notification_center/resources/notification_configuration.gd" id="1"]

[resource]
script = ExtResource("1")
maximum_history = 500
default_duration_seconds = 8.0
automatically_expire_notifications = true
automatically_acknowledge_expired = false
play_notification_audio = true
maximum_visible_toasts = 4
show_acknowledged_notifications = true
'@

$files["packages/014_notification_center/scripts/domain/notification_priority.gd"] = @'
class_name NotificationPriority
extends RefCounted
## Defines notification delivery priority.


#region Values

enum Value {
	LOW,
	NORMAL,
	HIGH,
	URGENT,
	CRITICAL,
}

#endregion


#region Public API

## Returns a stable priority identifier.
static func to_string_name(priority: Value) -> StringName:
	match priority:
		Value.LOW:
			return &"low"
		Value.NORMAL:
			return &"normal"
		Value.HIGH:
			return &"high"
		Value.URGENT:
			return &"urgent"
		Value.CRITICAL:
			return &"critical"
		_:
			return &"unknown"


## Returns a presentation color.
static func to_color(priority: Value) -> Color:
	match priority:
		Value.LOW:
			return Color("#40515b")
		Value.NORMAL:
			return Color("#32d8ff")
		Value.HIGH:
			return Color("#d6aa48")
		Value.URGENT:
			return Color("#ff8b3d")
		Value.CRITICAL:
			return Color("#ff4f62")
		_:
			return Color.WHITE

#endregion
'@

$files["packages/014_notification_center/scripts/domain/notification_state.gd"] = @'
class_name NotificationState
extends RefCounted
## Defines notification lifecycle state.


#region Values

enum Value {
	PENDING,
	DELIVERED,
	ACKNOWLEDGED,
	EXPIRED,
	DISMISSED,
}

#endregion


#region Public API

## Returns a stable state identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.PENDING:
			return &"pending"
		Value.DELIVERED:
			return &"delivered"
		Value.ACKNOWLEDGED:
			return &"acknowledged"
		Value.EXPIRED:
			return &"expired"
		Value.DISMISSED:
			return &"dismissed"
		_:
			return &"unknown"

#endregion
'@

$files["packages/014_notification_center/scripts/domain/notification_request.gd"] = @'
class_name NotificationRequest
extends ValueObject
## Represents an immutable notification submission request.


#region State

var _source_id: StringName
var _category: StringName
var _title: String
var _message: String
var _priority: NotificationPriority.Value
var _duration_seconds: float
var _metadata: Dictionary[StringName, Variant]

#endregion


#region Construction

## Creates an immutable notification request.
func _init(
	source_id: StringName,
	category: StringName,
	title: String,
	message: String,
	priority: NotificationPriority.Value,
	duration_seconds: float,
	metadata: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not source_id.is_empty(),
		"NotificationRequest requires source_id."
	)
	assert(
		not category.is_empty(),
		"NotificationRequest requires category."
	)
	assert(
		not title.strip_edges().is_empty(),
		"NotificationRequest requires title."
	)
	assert(
		duration_seconds >= 0.0,
		"Notification duration cannot be negative."
	)

	_source_id = source_id
	_category = category
	_title = title.strip_edges()
	_message = message.strip_edges()
	_priority = priority
	_duration_seconds = duration_seconds
	_metadata = metadata.duplicate(true)

#endregion


#region Public API

func get_source_id() -> StringName:
	return _source_id


func get_category() -> StringName:
	return _category


func get_title() -> String:
	return _title


func get_message() -> String:
	return _message


func get_priority() -> NotificationPriority.Value:
	return _priority


func get_duration_seconds() -> float:
	return _duration_seconds


func get_metadata() -> Dictionary[StringName, Variant]:
	return _metadata.duplicate(true)

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_source_id,
		_category,
		_title,
		_message,
		_priority,
		_duration_seconds,
		_metadata,
	]

#endregion
'@

$files["packages/014_notification_center/scripts/domain/hydra_notification.gd"] = @'
class_name HydraNotification
extends AggregateRoot
## Owns one notification lifecycle.


#region Events

const EVENT_CREATED: StringName = \
	&"hydra.notification.created"
const EVENT_DELIVERED: StringName = \
	&"hydra.notification.delivered"
const EVENT_ACKNOWLEDGED: StringName = \
	&"hydra.notification.acknowledged"
const EVENT_EXPIRED: StringName = \
	&"hydra.notification.expired"
const EVENT_DISMISSED: StringName = \
	&"hydra.notification.dismissed"

#endregion


#region State

var _request: NotificationRequest
var _state: NotificationState.Value = NotificationState.Value.PENDING
var _created_at_unix_ms: int
var _delivered_at_unix_ms: int = 0
var _completed_at_unix_ms: int = 0

#endregion


#region Construction

## Creates a notification aggregate.
func _init(
	id: EntityId,
	request: NotificationRequest
) -> void:
	super(id)

	assert(
		request != null,
		"HydraNotification requires request."
	)

	_request = request
	_created_at_unix_ms = _now()

	_record_domain_event(
		DomainEvent.new(
			EVENT_CREATED,
			{
				&"notification_id": get_id().as_string(),
				&"source_id": request.get_source_id(),
				&"priority":
					NotificationPriority.to_string_name(
						request.get_priority()
					),
			}
		)
	)

#endregion


#region Public API

func get_request() -> NotificationRequest:
	return _request


func get_state() -> NotificationState.Value:
	return _state


func get_created_at_unix_ms() -> int:
	return _created_at_unix_ms


func get_delivered_at_unix_ms() -> int:
	return _delivered_at_unix_ms


func get_completed_at_unix_ms() -> int:
	return _completed_at_unix_ms


## Marks the notification as delivered.
func deliver() -> Result:
	if _state != NotificationState.Value.PENDING:
		return _invalid_state("deliver")

	_state = NotificationState.Value.DELIVERED
	_delivered_at_unix_ms = _now()
	increment_version()
	_record_state_event(EVENT_DELIVERED)

	return Result.success()


## Acknowledges the notification.
func acknowledge() -> Result:
	if _state not in [
		NotificationState.Value.DELIVERED,
		NotificationState.Value.EXPIRED,
	]:
		return _invalid_state("acknowledge")

	_state = NotificationState.Value.ACKNOWLEDGED
	_completed_at_unix_ms = _now()
	increment_version()
	_record_state_event(EVENT_ACKNOWLEDGED)

	return Result.success()


## Expires the notification.
func expire() -> Result:
	if _state != NotificationState.Value.DELIVERED:
		return _invalid_state("expire")

	_state = NotificationState.Value.EXPIRED
	_completed_at_unix_ms = _now()
	increment_version()
	_record_state_event(EVENT_EXPIRED)

	return Result.success()


## Dismisses the notification.
func dismiss() -> Result:
	if _state == NotificationState.Value.DISMISSED:
		return Result.success()

	_state = NotificationState.Value.DISMISSED
	_completed_at_unix_ms = _now()
	increment_version()
	_record_state_event(EVENT_DISMISSED)

	return Result.success()

#endregion


#region Private methods

func _record_state_event(
	event_name: StringName
) -> void:
	_record_domain_event(
		DomainEvent.new(
			event_name,
			{
				&"notification_id": get_id().as_string(),
				&"state": NotificationState.to_string_name(_state),
			}
		)
	)


func _invalid_state(
	operation: String
) -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Notification operation is invalid.",
			{
				&"operation": operation,
				&"state": NotificationState.to_string_name(_state),
			}
		)
	)


func _now() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0)

#endregion
'@

$files["packages/014_notification_center/scripts/contracts/notification_repository_port.gd"] = @'
@abstract
class_name NotificationRepositoryPort
extends RefCounted
## Defines notification persistence operations.


#region Public API

@abstract
func save(notification: HydraNotification) -> Result


@abstract
func find_by_id(notification_id: StringName) -> Result


@abstract
func find_all() -> Result


@abstract
func remove(notification_id: StringName) -> Result

#endregion
'@

$files["packages/014_notification_center/scripts/infrastructure/in_memory_notification_repository.gd"] = @'
class_name InMemoryNotificationRepository
extends NotificationRepositoryPort
## Stores notifications in memory.


#region State

var _notifications: Dictionary[StringName, HydraNotification] = {}

#endregion


#region NotificationRepositoryPort

func save(notification: HydraNotification) -> Result:
	if notification == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Notification cannot be null."
			)
		)

	_notifications[
		notification.get_id().get_value()
	] = notification

	return Result.success(notification)


func find_by_id(notification_id: StringName) -> Result:
	var notification := _notifications.get(
		notification_id
	) as HydraNotification

	if notification == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Notification was not found.",
				{&"notification_id": notification_id}
			)
		)

	return Result.success(notification)


func find_all() -> Result:
	var result: Array[HydraNotification] = []

	for notification: HydraNotification in _notifications.values():
		result.append(notification)

	result.sort_custom(
		func(left: HydraNotification, right: HydraNotification) -> bool:
			return (
				left.get_created_at_unix_ms()
				> right.get_created_at_unix_ms()
			)
	)

	return Result.success(result)


func remove(notification_id: StringName) -> Result:
	_notifications.erase(notification_id)

	return Result.success()

#endregion
'@

$files["packages/014_notification_center/scripts/application/notification_center_service.gd"] = @'
class_name NotificationCenterService
extends Node
## Coordinates notification submission and lifecycle.


#region Signals

signal notification_created(notification: HydraNotification)
signal notification_delivered(notification: HydraNotification)
signal notification_updated(notification: HydraNotification)
signal notification_removed(notification_id: StringName)

#endregion


#region State

var _configuration: NotificationConfiguration
var _repository: NotificationRepositoryPort
var _expiration_timers: Dictionary[StringName, Timer] = {}

#endregion


#region Public API

## Configures Notification Center.
func configure(
	configuration: NotificationConfiguration,
	repository: NotificationRepositoryPort
) -> Result:
	if configuration == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Notification configuration cannot be null."
			)
		)

	if repository == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Notification repository cannot be null."
			)
		)

	_configuration = configuration
	_repository = repository

	return Result.success()


## Submits and delivers a notification.
func notify(
	request: NotificationRequest
) -> Result:
	if _configuration == null or _repository == null:
		return _not_configured()

	if request == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Notification request cannot be null."
			)
		)

	var notification := HydraNotification.new(
		EntityId.generate(),
		request
	)

	_repository.save(notification)
	_publish_events(notification)
	notification_created.emit(notification)

	var delivery_result := notification.deliver()

	if delivery_result.is_failure():
		return delivery_result

	_repository.save(notification)
	_publish_events(notification)
	notification_delivered.emit(notification)

	if _configuration.automatically_expire_notifications:
		_schedule_expiration(notification)

	_trim_history()

	return Result.success(notification)


## Acknowledges a notification.
func acknowledge(
	notification_id: StringName
) -> Result:
	var result := _find(notification_id)

	if result.is_failure():
		return result

	var notification := result.get_value() as HydraNotification
	var state_result := notification.acknowledge()

	if state_result.is_failure():
		return state_result

	_cancel_expiration(notification_id)
	_repository.save(notification)
	_publish_events(notification)
	notification_updated.emit(notification)

	return Result.success(notification)


## Dismisses a notification.
func dismiss(
	notification_id: StringName
) -> Result:
	var result := _find(notification_id)

	if result.is_failure():
		return result

	var notification := result.get_value() as HydraNotification
	var state_result := notification.dismiss()

	if state_result.is_failure():
		return state_result

	_cancel_expiration(notification_id)
	_repository.save(notification)
	_publish_events(notification)
	notification_updated.emit(notification)

	return Result.success(notification)


## Removes a notification from history.
func remove(
	notification_id: StringName
) -> Result:
	_cancel_expiration(notification_id)

	var result := _repository.remove(notification_id)

	if result.is_success():
		notification_removed.emit(notification_id)

	return result


## Returns all notifications.
func get_notifications() -> Array[HydraNotification]:
	if _repository == null:
		return []

	var result := _repository.find_all()

	if result.is_failure():
		return []

	return result.get_value()

#endregion


#region Private methods

func _find(notification_id: StringName) -> Result:
	if _repository == null:
		return _not_configured()

	return _repository.find_by_id(notification_id)


func _schedule_expiration(
	notification: HydraNotification
) -> void:
	var notification_id := notification.get_id().get_value()
	var duration := notification.get_request().get_duration_seconds()

	if duration <= 0.0:
		duration = _configuration.default_duration_seconds

	var timer := Timer.new()
	timer.name = "NotificationExpiration_%s" % notification_id
	timer.one_shot = true
	timer.wait_time = duration
	timer.timeout.connect(
		_on_expiration_timeout.bind(notification_id)
	)
	add_child(timer)

	_expiration_timers[notification_id] = timer
	timer.start()


func _cancel_expiration(
	notification_id: StringName
) -> void:
	var timer := _expiration_timers.get(
		notification_id
	) as Timer

	if timer == null:
		return

	timer.stop()
	timer.queue_free()
	_expiration_timers.erase(notification_id)


func _on_expiration_timeout(
	notification_id: StringName
) -> void:
	_expiration_timers.erase(notification_id)

	var result := _repository.find_by_id(notification_id)

	if result.is_failure():
		return

	var notification := result.get_value() as HydraNotification

	if notification.get_state() != NotificationState.Value.DELIVERED:
		return

	notification.expire()

	if _configuration.automatically_acknowledge_expired:
		notification.acknowledge()

	_repository.save(notification)
	_publish_events(notification)
	notification_updated.emit(notification)


func _trim_history() -> void:
	var notifications := get_notifications()

	while notifications.size() > _configuration.maximum_history:
		var oldest := notifications.pop_back()
		remove(oldest.get_id().get_value())


func _publish_events(
	notification: HydraNotification
) -> void:
	var events := notification.pull_domain_events()
	var event_bus := get_node_or_null("/root/EventBus")

	if event_bus == null:
		return

	for event in events:
		event_bus.publish(event)


func _not_configured() -> Result:
	return Result.failure(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Notification Center is not configured."
		)
	)

#endregion
'@

$files["packages/014_notification_center/scripts/presentation/notification_toast.gd"] = @'
class_name NotificationToast
extends WidgetBase
## Displays one transient notification.


#region Signals

signal acknowledged(notification_id: StringName)
signal dismissed(notification_id: StringName)

#endregion


#region Nodes

@onready var _indicator: ColorRect = %Indicator
@onready var _title_label: RichTextLabel = %TitleLabel
@onready var _message_label: RichTextLabel = %MessageLabel
@onready var _priority_label: RichTextLabel = %PriorityLabel

#endregion


#region State

var _notification: HydraNotification

#endregion


#region Public API

## Applies a notification.
func apply_notification(
	notification: HydraNotification
) -> void:
	assert(
		notification != null,
		"NotificationToast requires notification."
	)

	_notification = notification

	if not is_node_ready():
		return

	var request := notification.get_request()
	var priority := request.get_priority()

	_indicator.color = NotificationPriority.to_color(priority)
	_title_label.text = request.get_title()
	_message_label.text = request.get_message()
	_priority_label.text = String(
		NotificationPriority.to_string_name(priority)
	).to_upper()


## Emits an acknowledgement request.
func request_acknowledgement() -> void:
	if _notification != null:
		acknowledged.emit(
			_notification.get_id().get_value()
		)


## Emits a dismissal request.
func request_dismissal() -> void:
	if _notification != null:
		dismissed.emit(
			_notification.get_id().get_value()
		)

#endregion
'@

$files["packages/014_notification_center/scripts/presentation/notification_center_panel.gd"] = @'
class_name NotificationCenterPanel
extends PanelBase
## Displays Notification Center history.


#region Constants

const TOAST_WIDTH: float = 760.0
const TOAST_HEIGHT: float = 126.0
const TOAST_START_X: float = 56.0
const TOAST_START_Y: float = 174.0
const TOAST_GAP: float = 18.0

#endregion


#region Nodes

@onready var _notification_layer: Control = %NotificationLayer
@onready var _summary_label: RichTextLabel = %SummaryLabel

#endregion


#region State

var _service: NotificationCenterService
var _toast_scene: PackedScene = preload(
	"res://packages/014_notification_center/scenes/notification_toast.tscn"
)

#endregion


#region Public API

## Binds the panel to Notification Center.
func bind_service(
	service: NotificationCenterService
) -> void:
	assert(
		service != null,
		"Notification Center service cannot be null."
	)

	_disconnect_service()
	_service = service

	_service.notification_created.connect(
		_on_notification_changed
	)
	_service.notification_delivered.connect(
		_on_notification_changed
	)
	_service.notification_updated.connect(
		_on_notification_changed
	)
	_service.notification_removed.connect(
		_on_notification_removed
	)

	rebuild_notifications()


## Rebuilds notification history.
func rebuild_notifications() -> void:
	if _service == null:
		return

	var notifications := _service.get_notifications()

	for child in _notification_layer.get_children():
		child.queue_free()

	for index in notifications.size():
		var toast := (
			_toast_scene.instantiate()
			as NotificationToast
		)

		toast.position = Vector2(
			TOAST_START_X,
			TOAST_START_Y + (
				index * (TOAST_HEIGHT + TOAST_GAP)
			)
		)
		toast.size = Vector2(
			TOAST_WIDTH,
			TOAST_HEIGHT
		)

		_notification_layer.add_child(toast)
		toast.apply_notification(notifications[index])
		toast.acknowledged.connect(
			_on_acknowledged
		)
		toast.dismissed.connect(_on_dismissed)

	var active_count := 0

	for notification in notifications:
		if notification.get_state() == NotificationState.Value.DELIVERED:
			active_count += 1

	_summary_label.text = (
		"NOTIFICATIONS  //  %d    ACTIVE  //  %d"
		% [
			notifications.size(),
			active_count,
		]
	)

#endregion


#region Private methods

func _disconnect_service() -> void:
	if _service == null:
		return

	if _service.notification_created.is_connected(
		_on_notification_changed
	):
		_service.notification_created.disconnect(
			_on_notification_changed
		)

	if _service.notification_delivered.is_connected(
		_on_notification_changed
	):
		_service.notification_delivered.disconnect(
			_on_notification_changed
		)

	if _service.notification_updated.is_connected(
		_on_notification_changed
	):
		_service.notification_updated.disconnect(
			_on_notification_changed
		)

	if _service.notification_removed.is_connected(
		_on_notification_removed
	):
		_service.notification_removed.disconnect(
			_on_notification_removed
		)


func _on_notification_changed(
	_notification: HydraNotification
) -> void:
	rebuild_notifications()


func _on_notification_removed(
	_notification_id: StringName
) -> void:
	rebuild_notifications()


func _on_acknowledged(
	notification_id: StringName
) -> void:
	_service.acknowledge(notification_id)


func _on_dismissed(
	notification_id: StringName
) -> void:
	_service.dismiss(notification_id)

#endregion
'@

$files["packages/014_notification_center/scenes/notification_toast.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/014_notification_center/scripts/presentation/notification_toast.gd" id="1"]

[node name="NotificationToast" type="Control"]
custom_minimum_size = Vector2(760, 126)
layout_mode = 3
anchors_preset = 0
offset_right = 760.0
offset_bottom = 126.0
mouse_filter = 1
script = ExtResource("1")
widget_id = &"notification_toast"

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.027451, 0.0901961, 0.133333, 0.94)

[node name="Indicator" type="ColorRect" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 12.0
offset_top = 12.0
offset_right = 18.0
offset_bottom = 114.0
mouse_filter = 2
color = Color(0.196078, 0.847059, 1, 1)

[node name="TitleLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 36.0
offset_top = 12.0
offset_right = 586.0
offset_bottom = 42.0
bbcode_enabled = true
text = "[color=#32d8ff]NOTIFICATION[/color]"
fit_content = true
scroll_active = false

[node name="PriorityLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 614.0
offset_top = 12.0
offset_right = 738.0
offset_bottom = 42.0
text = "NORMAL"
fit_content = true
scroll_active = false

[node name="MessageLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 36.0
offset_top = 50.0
offset_right = 738.0
offset_bottom = 108.0
text = "Notification message."
scroll_active = false
'@

$files["packages/014_notification_center/scenes/notification_center_panel.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/014_notification_center/scripts/presentation/notification_center_panel.gd" id="1"]

[node name="NotificationCenterPanel" type="Control"]
layout_mode = 3
anchors_preset = 0
offset_right = 880.0
offset_bottom = 900.0
mouse_filter = 1
script = ExtResource("1")
panel_id = &"notification_center_panel"
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
text = "[font_size=30][color=#32d8ff]NOTIFICATION CENTER[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="Subtitle" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 54.0
offset_top = 62.0
offset_right = 820.0
offset_bottom = 96.0
bbcode_enabled = true
text = "[color=#6e8794]SYSTEM MESSAGE CONTROL  //  CHANNEL 014[/color]"
fit_content = true
scroll_active = false

[node name="SummaryLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 54.0
offset_top = 116.0
offset_right = 826.0
offset_bottom = 150.0
bbcode_enabled = true
text = "[color=#d6aa48]NOTIFICATIONS  //  0    ACTIVE  //  0[/color]"
fit_content = true
scroll_active = false

[node name="NotificationLayer" type="Control" parent="."]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 1
'@

$files["packages/014_notification_center/demo/notification_center_demo.gd"] = @'
class_name NotificationCenterDemo
extends Control
## Demonstrates Notification Center.


#region Nodes

@onready var _panel: NotificationCenterPanel = %NotificationCenterPanel

#endregion


#region State

var _service: NotificationCenterService

#endregion


#region Lifecycle

func _ready() -> void:
	_service = NotificationCenterService.new()
	_service.name = "NotificationCenterService"
	add_child(_service)

	var configuration := NotificationConfiguration.new()
	var repository := InMemoryNotificationRepository.new()

	_service.configure(configuration, repository)
	_panel.bind_service(_service)

	_service.notify(
		NotificationRequest.new(
			&"diagnostics",
			&"system",
			"SYSTEM ONLINE",
			"HYDRA core services are operational.",
			NotificationPriority.Value.NORMAL,
			12.0
		)
	)

	_service.notify(
		NotificationRequest.new(
			&"security",
			&"security",
			"SECURITY CHANNEL",
			"Perimeter monitoring is active.",
			NotificationPriority.Value.HIGH,
			16.0
		)
	)

#endregion
'@

$files["packages/014_notification_center/demo/notification_center_demo.tscn"] = @'
[gd_scene load_steps=3 format=3]

[ext_resource type="Script" path="res://packages/014_notification_center/demo/notification_center_demo.gd" id="1"]
[ext_resource type="PackedScene" path="res://packages/014_notification_center/scenes/notification_center_panel.tscn" id="2"]

[node name="NotificationCenterDemo" type="Control"]
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

[node name="NotificationCenterPanel" parent="." instance=ExtResource("2")]
unique_name_in_owner = true
layout_mode = 0
offset_left = 520.0
offset_top = 90.0
offset_right = 1400.0
offset_bottom = 990.0
'@

$files["packages/014_notification_center/tests/unit/test_hydra_notification.gd"] = @'
class_name HydraNotificationTest
extends RefCounted
## Provides HydraNotification lifecycle tests.


#region Tests

static func run() -> void:
	var request := NotificationRequest.new(
		&"test",
		&"system",
		"TEST",
		"Test notification.",
		NotificationPriority.Value.NORMAL,
		5.0
	)
	var notification := HydraNotification.new(
		EntityId.generate(),
		request
	)

	assert(notification.deliver().is_success())
	assert(
		notification.get_state()
		== NotificationState.Value.DELIVERED
	)
	assert(notification.acknowledge().is_success())
	assert(
		notification.get_state()
		== NotificationState.Value.ACKNOWLEDGED
	)

#endregion
'@

$files["packages/014_notification_center/tests/integration/test_notification_center_service.gd"] = @'
class_name NotificationCenterServiceTest
extends RefCounted
## Provides Notification Center composition tests.


#region Tests

static func run() -> void:
	var service := NotificationCenterService.new()
	var configuration := NotificationConfiguration.new()
	var repository := InMemoryNotificationRepository.new()

	assert(
		service.configure(
			configuration,
			repository
		).is_success()
	)

#endregion
'@

# =============================================================================
# PACKAGE 015 — PLUGIN SDK
# =============================================================================

$files["packages/015_plugin_sdk/package.cfg"] = @'
[package]

id="015_plugin_sdk"
name="Plugin SDK"
version="0.1.0"
minimum_godot_version="4.7"
dependencies=PackedStringArray(
	"001_foundation"
)
'@

$files["packages/015_plugin_sdk/README.md"] = @'
# Package 015 — Plugin SDK

Plugin SDK defines stable extension contracts for HYDRA AI HOME OS.

Plugins expose manifests, lifecycle callbacks, service requirements and
extension registrations.

Plugin SDK does not load arbitrary native code and does not grant unrestricted
access to platform services.
'@

$files["packages/015_plugin_sdk/CHANGELOG.md"] = @'
# Plugin SDK changelog

## [0.1.0] - 2026-07-17

### Added

- Added plugin manifest resource.
- Added plugin lifecycle states.
- Added plugin capability definitions.
- Added plugin contract.
- Added plugin registry.
- Added plugin loader service.
- Added example plugin.
- Added SDK tests and documentation.
'@

$files["packages/015_plugin_sdk/docs/architecture.md"] = @'
# Plugin SDK architecture

Plugin SDK provides contracts only.

Plugin implementations depend on Plugin SDK.

The application composition root owns plugin discovery and loading.

Plugins receive explicitly granted services instead of resolving unrestricted
autoloads.
'@

$files["packages/015_plugin_sdk/docs/security.md"] = @'
# Plugin security

Plugins are untrusted until validated.

A plugin manifest declares requested capabilities.

Unknown capabilities are rejected.

Plugins may only access services explicitly granted by the composition root.

Native libraries, shell execution and unrestricted file access are outside the
default SDK contract.
'@

$files["packages/015_plugin_sdk/docs/plugin-api.md"] = @'
# Plugin API

A plugin extends HydraPlugin.

Required lifecycle:

- validate_manifest
- initialize_plugin
- start_plugin
- stop_plugin
- dispose_plugin

Plugins register extension descriptors through PluginContext.
'@

$files["packages/015_plugin_sdk/resources/plugin_manifest.gd"] = @'
class_name PluginManifest
extends Resource
## Declares plugin identity, compatibility and requested capabilities.


#region Identity

@export_group("Identity")
@export var plugin_id: StringName = &""
@export var display_name: String = ""
@export var version: String = "0.1.0"
@export var author: String = ""
@export_multiline var description: String = ""

#endregion


#region Compatibility

@export_group("Compatibility")
@export var minimum_hydra_version: String = "0.1.0"
@export var minimum_godot_version: String = "4.7"
@export var entry_script_path: String = ""

#endregion


#region Dependencies

@export_group("Dependencies")
@export var required_plugins: PackedStringArray = PackedStringArray()
@export var requested_capabilities: PackedStringArray = PackedStringArray()

#endregion


#region Validation

## Validates required manifest fields.
func validate() -> Result:
	if plugin_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin manifest requires plugin_id."
			)
		)

	if display_name.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin manifest requires display_name.",
				{&"plugin_id": plugin_id}
			)
		)

	if version.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin manifest requires version.",
				{&"plugin_id": plugin_id}
			)
		)

	if entry_script_path.strip_edges().is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin manifest requires entry_script_path.",
				{&"plugin_id": plugin_id}
			)
		)

	if not entry_script_path.begins_with("res://"):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin entry script must use a res:// path.",
				{&"plugin_id": plugin_id}
			)
		)

	return Result.success()

#endregion
'@

$files["packages/015_plugin_sdk/scripts/domain/plugin_lifecycle_state.gd"] = @'
class_name PluginLifecycleState
extends RefCounted
## Defines plugin lifecycle states.


#region Values

enum Value {
	DISCOVERED,
	VALIDATING,
	VALIDATED,
	INITIALIZING,
	READY,
	STARTING,
	RUNNING,
	STOPPING,
	STOPPED,
	FAILED,
	DISPOSED,
}

#endregion


#region Public API

## Returns a stable lifecycle identifier.
static func to_string_name(state: Value) -> StringName:
	match state:
		Value.DISCOVERED:
			return &"discovered"
		Value.VALIDATING:
			return &"validating"
		Value.VALIDATED:
			return &"validated"
		Value.INITIALIZING:
			return &"initializing"
		Value.READY:
			return &"ready"
		Value.STARTING:
			return &"starting"
		Value.RUNNING:
			return &"running"
		Value.STOPPING:
			return &"stopping"
		Value.STOPPED:
			return &"stopped"
		Value.FAILED:
			return &"failed"
		Value.DISPOSED:
			return &"disposed"
		_:
			return &"unknown"

#endregion
'@

$files["packages/015_plugin_sdk/scripts/domain/plugin_capability.gd"] = @'
class_name PluginCapability
extends RefCounted
## Defines supported plugin capability identifiers.


#region Constants

const EVENT_SUBSCRIPTION: StringName = &"event_subscription"
const EVENT_PUBLICATION: StringName = &"event_publication"
const UI_WIDGET: StringName = &"ui_widget"
const UI_PANEL: StringName = &"ui_panel"
const DEVICE_PROVIDER: StringName = &"device_provider"
const AI_PROVIDER: StringName = &"ai_provider"
const AUTOMATION_EXECUTOR: StringName = &"automation_executor"
const DIAGNOSTIC_PROBE: StringName = &"diagnostic_probe"

#endregion


#region Public API

## Returns all capabilities supported by the SDK.
static func get_supported() -> Array[StringName]:
	return [
		EVENT_SUBSCRIPTION,
		EVENT_PUBLICATION,
		UI_WIDGET,
		UI_PANEL,
		DEVICE_PROVIDER,
		AI_PROVIDER,
		AUTOMATION_EXECUTOR,
		DIAGNOSTIC_PROBE,
	]


## Returns whether a capability is supported.
static func is_supported(
	capability: StringName
) -> bool:
	return capability in get_supported()

#endregion
'@

$files["packages/015_plugin_sdk/scripts/domain/plugin_extension_descriptor.gd"] = @'
class_name PluginExtensionDescriptor
extends ValueObject
## Describes one extension exported by a plugin.


#region State

var _extension_id: StringName
var _capability: StringName
var _implementation: Variant
var _metadata: Dictionary[StringName, Variant]

#endregion


#region Construction

## Creates an extension descriptor.
func _init(
	extension_id: StringName,
	capability: StringName,
	implementation: Variant,
	metadata: Dictionary[StringName, Variant] = {}
) -> void:
	assert(
		not extension_id.is_empty(),
		"PluginExtensionDescriptor requires extension_id."
	)
	assert(
		PluginCapability.is_supported(capability),
		"Plugin extension capability is unsupported."
	)
	assert(
		implementation != null,
		"Plugin extension implementation cannot be null."
	)

	_extension_id = extension_id
	_capability = capability
	_implementation = implementation
	_metadata = metadata.duplicate(true)

#endregion


#region Public API

func get_extension_id() -> StringName:
	return _extension_id


func get_capability() -> StringName:
	return _capability


func get_implementation() -> Variant:
	return _implementation


func get_metadata() -> Dictionary[StringName, Variant]:
	return _metadata.duplicate(true)

#endregion


#region ValueObject

func _get_atomic_values() -> Array[Variant]:
	return [
		_extension_id,
		_capability,
		_implementation,
		_metadata,
	]

#endregion
'@

$files["packages/015_plugin_sdk/scripts/application/plugin_context.gd"] = @'
class_name PluginContext
extends RefCounted
## Provides explicitly granted services and extension registration.


#region State

var _services: Dictionary[StringName, Variant] = {}
var _extensions: Array[PluginExtensionDescriptor] = []

#endregion


#region Public API

## Grants one service to the plugin.
func grant_service(
	service_id: StringName,
	service: Variant
) -> Result:
	if service_id.is_empty():
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin service identifier cannot be empty."
			)
		)

	if service == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin service cannot be null.",
				{&"service_id": service_id}
			)
		)

	_services[service_id] = service

	return Result.success()


## Returns a granted service.
func get_service(
	service_id: StringName
) -> Variant:
	return _services.get(service_id)


## Returns whether a service was granted.
func has_service(
	service_id: StringName
) -> bool:
	return _services.has(service_id)


## Registers one plugin extension.
func register_extension(
	descriptor: PluginExtensionDescriptor
) -> Result:
	if descriptor == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin extension descriptor cannot be null."
			)
		)

	for extension in _extensions:
		if (
			extension.get_extension_id()
			== descriptor.get_extension_id()
		):
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_STATE,
					"Plugin extension is already registered.",
					{
						&"extension_id":
							descriptor.get_extension_id(),
					}
				)
			)

	_extensions.append(descriptor)

	return Result.success()


## Returns registered plugin extensions.
func get_extensions() -> Array[PluginExtensionDescriptor]:
	return _extensions.duplicate()

#endregion
'@

$files["packages/015_plugin_sdk/scripts/application/hydra_plugin.gd"] = @'
@abstract
class_name HydraPlugin
extends RefCounted
## Base class for all HYDRA plugins.


#region State

var _manifest: PluginManifest
var _context: PluginContext
var _state: PluginLifecycleState.Value = \
	PluginLifecycleState.Value.DISCOVERED
var _last_error: DomainError

#endregion


#region Public API

## Assigns the validated plugin manifest.
func set_manifest(
	manifest: PluginManifest
) -> void:
	assert(manifest != null, "Plugin manifest cannot be null.")
	_manifest = manifest


## Returns the plugin manifest.
func get_manifest() -> PluginManifest:
	return _manifest


## Returns the current lifecycle state.
func get_state() -> PluginLifecycleState.Value:
	return _state


## Returns the most recent lifecycle error.
func get_last_error() -> DomainError:
	return _last_error


## Validates this plugin.
func validate_plugin() -> Result:
	_state = PluginLifecycleState.Value.VALIDATING

	if _manifest == null:
		return _fail(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin manifest is not assigned."
			)
		)

	var manifest_result := _manifest.validate()

	if manifest_result.is_failure():
		return _fail(manifest_result.get_error())

	for capability in _manifest.requested_capabilities:
		if not PluginCapability.is_supported(
			StringName(capability)
		):
			return _fail(
				DomainError.new(
					HydraErrors.INVALID_ARGUMENT,
					"Plugin requested an unsupported capability.",
					{
						&"plugin_id": _manifest.plugin_id,
						&"capability": capability,
					}
				)
			)

	var custom_result := _on_validate()

	if custom_result.is_failure():
		return _fail(custom_result.get_error())

	_state = PluginLifecycleState.Value.VALIDATED

	return Result.success()


## Initializes the plugin.
func initialize_plugin(
	context: PluginContext
) -> Result:
	if _state != PluginLifecycleState.Value.VALIDATED:
		return _invalid_state("initialize")

	if context == null:
		return _fail(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin context cannot be null."
			)
		)

	_state = PluginLifecycleState.Value.INITIALIZING
	_context = context

	var result := _on_initialize(context)

	if result.is_failure():
		return _fail(result.get_error())

	_state = PluginLifecycleState.Value.READY

	return Result.success()


## Starts the plugin.
func start_plugin() -> Result:
	if _state not in [
		PluginLifecycleState.Value.READY,
		PluginLifecycleState.Value.STOPPED,
	]:
		return _invalid_state("start")

	_state = PluginLifecycleState.Value.STARTING

	var result := _on_start()

	if result.is_failure():
		return _fail(result.get_error())

	_state = PluginLifecycleState.Value.RUNNING

	return Result.success()


## Stops the plugin.
func stop_plugin() -> Result:
	if _state != PluginLifecycleState.Value.RUNNING:
		return _invalid_state("stop")

	_state = PluginLifecycleState.Value.STOPPING

	var result := _on_stop()

	if result.is_failure():
		return _fail(result.get_error())

	_state = PluginLifecycleState.Value.STOPPED

	return Result.success()


## Disposes the plugin.
func dispose_plugin() -> void:
	if _state == PluginLifecycleState.Value.RUNNING:
		stop_plugin()

	_on_dispose()
	_context = null
	_state = PluginLifecycleState.Value.DISPOSED

#endregion


#region Extension points

func _on_validate() -> Result:
	return Result.success()


func _on_initialize(
	_context_value: PluginContext
) -> Result:
	return Result.success()


func _on_start() -> Result:
	return Result.success()


func _on_stop() -> Result:
	return Result.success()


func _on_dispose() -> void:
	pass

#endregion


#region Private methods

func _fail(error: DomainError) -> Result:
	_last_error = error
	_state = PluginLifecycleState.Value.FAILED

	return Result.failure(error)


func _invalid_state(operation: String) -> Result:
	return _fail(
		DomainError.new(
			HydraErrors.INVALID_STATE,
			"Plugin lifecycle operation is invalid.",
			{
				&"operation": operation,
				&"state": PluginLifecycleState.to_string_name(_state),
			}
		)
	)

#endregion
'@

$files["packages/015_plugin_sdk/scripts/application/plugin_registry.gd"] = @'
class_name PluginRegistry
extends RefCounted
## Stores loaded plugins and exported extensions.


#region State

var _plugins: Dictionary[StringName, HydraPlugin] = {}
var _extensions: Dictionary[StringName, PluginExtensionDescriptor] = {}

#endregion


#region Public API

## Registers a plugin.
func register_plugin(
	plugin: HydraPlugin
) -> Result:
	if plugin == null or plugin.get_manifest() == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin and manifest are required."
			)
		)

	var plugin_id := plugin.get_manifest().plugin_id

	if _plugins.has(plugin_id):
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Plugin is already registered.",
				{&"plugin_id": plugin_id}
			)
		)

	_plugins[plugin_id] = plugin

	return Result.success(plugin)


## Registers exported extensions.
func register_extensions(
	extensions: Array[PluginExtensionDescriptor]
) -> Result:
	for extension in extensions:
		var extension_id := extension.get_extension_id()

		if _extensions.has(extension_id):
			return Result.failure(
				DomainError.new(
					HydraErrors.INVALID_STATE,
					"Plugin extension is already registered.",
					{&"extension_id": extension_id}
				)
			)

		_extensions[extension_id] = extension

	return Result.success()


## Returns a plugin.
func get_plugin(plugin_id: StringName) -> HydraPlugin:
	return _plugins.get(plugin_id)


## Returns all plugins.
func get_plugins() -> Array[HydraPlugin]:
	var result: Array[HydraPlugin] = []

	for plugin: HydraPlugin in _plugins.values():
		result.append(plugin)

	return result


## Returns extensions for a capability.
func get_extensions_by_capability(
	capability: StringName
) -> Array[PluginExtensionDescriptor]:
	var result: Array[PluginExtensionDescriptor] = []

	for extension: PluginExtensionDescriptor in _extensions.values():
		if extension.get_capability() == capability:
			result.append(extension)

	return result

#endregion
'@

$files["packages/015_plugin_sdk/scripts/application/plugin_loader_service.gd"] = @'
class_name PluginLoaderService
extends Node
## Validates, initializes and starts HYDRA plugins.


#region Signals

signal plugin_loaded(plugin: HydraPlugin)
signal plugin_started(plugin: HydraPlugin)
signal plugin_stopped(plugin: HydraPlugin)
signal plugin_failed(
	plugin_id: StringName,
	error: DomainError
)

#endregion


#region State

var _registry: PluginRegistry
var _granted_services: Dictionary[StringName, Variant] = {}

#endregion


#region Public API

## Configures the loader.
func configure(
	registry: PluginRegistry
) -> Result:
	if registry == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin registry cannot be null."
			)
		)

	_registry = registry

	return Result.success()


## Grants a service to future plugin contexts.
func grant_service(
	service_id: StringName,
	service: Variant
) -> Result:
	if service_id.is_empty() or service == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin service grant is invalid."
			)
		)

	_granted_services[service_id] = service

	return Result.success()


## Loads and starts one plugin.
func load_plugin(
	plugin: HydraPlugin,
	manifest: PluginManifest
) -> Result:
	if _registry == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Plugin loader is not configured."
			)
		)

	if plugin == null or manifest == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.VALUE_REQUIRED,
				"Plugin and manifest are required."
			)
		)

	plugin.set_manifest(manifest)

	var validation_result := plugin.validate_plugin()

	if validation_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			validation_result.get_error()
		)

	var context := PluginContext.new()

	for service_id in _granted_services:
		context.grant_service(
			service_id,
			_granted_services[service_id]
		)

	var initialization_result := plugin.initialize_plugin(
		context
	)

	if initialization_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			initialization_result.get_error()
		)

	var registration_result := _registry.register_plugin(
		plugin
	)

	if registration_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			registration_result.get_error()
		)

	var extension_result := _registry.register_extensions(
		context.get_extensions()
	)

	if extension_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			extension_result.get_error()
		)

	plugin_loaded.emit(plugin)

	var start_result := plugin.start_plugin()

	if start_result.is_failure():
		return _report_failure(
			manifest.plugin_id,
			start_result.get_error()
		)

	plugin_started.emit(plugin)

	return Result.success(plugin)


## Stops one plugin.
func stop_plugin(
	plugin_id: StringName
) -> Result:
	if _registry == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_STATE,
				"Plugin loader is not configured."
			)
		)

	var plugin := _registry.get_plugin(plugin_id)

	if plugin == null:
		return Result.failure(
			DomainError.new(
				HydraErrors.INVALID_ARGUMENT,
				"Plugin was not found.",
				{&"plugin_id": plugin_id}
			)
		)

	var result := plugin.stop_plugin()

	if result.is_failure():
		return _report_failure(
			plugin_id,
			result.get_error()
		)

	plugin_stopped.emit(plugin)

	return Result.success(plugin)

#endregion


#region Private methods

func _report_failure(
	plugin_id: StringName,
	error: DomainError
) -> Result:
	plugin_failed.emit(plugin_id, error)

	return Result.failure(error)

#endregion
'@

$files["packages/015_plugin_sdk/demo/example_plugin.gd"] = @'
class_name ExampleHydraPlugin
extends HydraPlugin
## Demonstrates a safe SDK plugin lifecycle.


#region State

var _started: bool = false

#endregion


#region HydraPlugin

func _on_validate() -> Result:
	return Result.success()


func _on_initialize(
	context: PluginContext
) -> Result:
	var extension := PluginExtensionDescriptor.new(
		&"example_diagnostic_probe",
		PluginCapability.DIAGNOSTIC_PROBE,
		self,
		{
			&"display_name": "EXAMPLE PLUGIN PROBE",
		}
	)

	return context.register_extension(extension)


func _on_start() -> Result:
	_started = true
	print("Example HYDRA plugin started.")

	return Result.success()


func _on_stop() -> Result:
	_started = false
	print("Example HYDRA plugin stopped.")

	return Result.success()


func _on_dispose() -> void:
	_started = false

#endregion


#region Public API

func is_started() -> bool:
	return _started

#endregion
'@

$files["packages/015_plugin_sdk/demo/example_plugin_manifest.tres"] = @'
[gd_resource type="Resource" script_class="PluginManifest" load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/015_plugin_sdk/resources/plugin_manifest.gd" id="1"]

[resource]
script = ExtResource("1")
plugin_id = &"example_plugin"
display_name = "EXAMPLE HYDRA PLUGIN"
version = "0.1.0"
author = "HYDRA AI HOME OS Contributors"
description = "Demonstrates the Plugin SDK lifecycle."
minimum_hydra_version = "0.1.0"
minimum_godot_version = "4.7"
entry_script_path = "res://packages/015_plugin_sdk/demo/example_plugin.gd"
required_plugins = PackedStringArray()
requested_capabilities = PackedStringArray("diagnostic_probe")
'@

$files["packages/015_plugin_sdk/demo/plugin_sdk_demo.gd"] = @'
class_name PluginSdkDemo
extends Control
## Demonstrates plugin validation, registration and startup.


#region Nodes

@onready var _status_label: RichTextLabel = %StatusLabel

#endregion


#region State

var _loader: PluginLoaderService
var _registry: PluginRegistry

#endregion


#region Lifecycle

func _ready() -> void:
	_registry = PluginRegistry.new()
	_loader = PluginLoaderService.new()
	_loader.name = "PluginLoaderService"
	add_child(_loader)

	_loader.configure(_registry)
	_loader.plugin_started.connect(_on_plugin_started)
	_loader.plugin_failed.connect(_on_plugin_failed)

	var plugin := ExampleHydraPlugin.new()
	var manifest: PluginManifest = preload(
		"res://packages/015_plugin_sdk/demo/example_plugin_manifest.tres"
	)

	var result := _loader.load_plugin(plugin, manifest)

	if result.is_failure():
		_on_plugin_failed(
			manifest.plugin_id,
			result.get_error()
		)

#endregion


#region Event handlers

func _on_plugin_started(plugin: HydraPlugin) -> void:
	_status_label.text = (
		"[color=#55f2a3]PLUGIN ONLINE[/color]\n"
		+ "[color=#32d8ff]%s  //  VERSION %s[/color]"
	) % [
		plugin.get_manifest().display_name,
		plugin.get_manifest().version,
	]


func _on_plugin_failed(
	plugin_id: StringName,
	error: DomainError
) -> void:
	_status_label.text = (
		"[color=#ff4f62]PLUGIN FAILURE  //  %s[/color]\n"
		+ "[color=#ff9aa5]%s[/color]"
	) % [
		String(plugin_id).to_upper(),
		error.get_message(),
	]

#endregion
'@

$files["packages/015_plugin_sdk/demo/plugin_sdk_demo.tscn"] = @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://packages/015_plugin_sdk/demo/plugin_sdk_demo.gd" id="1"]

[node name="PluginSdkDemo" type="Control"]
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

[node name="Title" type="RichTextLabel" parent="."]
layout_mode = 0
offset_left = 560.0
offset_top = 300.0
offset_right = 1360.0
offset_bottom = 360.0
bbcode_enabled = true
text = "[font_size=32][color=#32d8ff]HYDRA PLUGIN SDK[/color][/font_size]"
fit_content = true
scroll_active = false

[node name="StatusLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 560.0
offset_top = 400.0
offset_right = 1360.0
offset_bottom = 620.0
bbcode_enabled = true
text = "[color=#d6aa48]LOADING PLUGIN...[/color]"
scroll_active = false
'@

$files["packages/015_plugin_sdk/tests/unit/test_plugin_manifest.gd"] = @'
class_name PluginManifestTest
extends RefCounted
## Provides PluginManifest validation tests.


#region Tests

static func run() -> void:
	var manifest := PluginManifest.new()

	assert(manifest.validate().is_failure())

	manifest.plugin_id = &"test_plugin"
	manifest.display_name = "TEST PLUGIN"
	manifest.version = "0.1.0"
	manifest.entry_script_path = "res://test_plugin.gd"

	assert(manifest.validate().is_success())

#endregion
'@

$files["packages/015_plugin_sdk/tests/unit/test_plugin_context.gd"] = @'
class_name PluginContextTest
extends RefCounted
## Provides PluginContext tests.


#region Tests

static func run() -> void:
	var context := PluginContext.new()
	var service := RefCounted.new()

	assert(
		context.grant_service(
			&"test_service",
			service
		).is_success()
	)
	assert(context.has_service(&"test_service"))
	assert(context.get_service(&"test_service") == service)

	var extension := PluginExtensionDescriptor.new(
		&"test_extension",
		PluginCapability.UI_WIDGET,
		service
	)

	assert(
		context.register_extension(extension).is_success()
	)
	assert(context.get_extensions().size() == 1)

#endregion
'@

$files["packages/015_plugin_sdk/tests/integration/test_plugin_loader_service.gd"] = @'
class_name PluginLoaderServiceTest
extends RefCounted
## Provides Plugin Loader composition tests.


#region Tests

static func run() -> void:
	var registry := PluginRegistry.new()
	var loader := PluginLoaderService.new()
	var plugin := ExampleHydraPlugin.new()
	var manifest := PluginManifest.new()

	manifest.plugin_id = &"test_plugin"
	manifest.display_name = "TEST PLUGIN"
	manifest.version = "0.1.0"
	manifest.entry_script_path = (
		"res://packages/015_plugin_sdk/demo/example_plugin.gd"
	)
	manifest.requested_capabilities = PackedStringArray(
		["diagnostic_probe"]
	)

	assert(loader.configure(registry).is_success())
	assert(loader.load_plugin(plugin, manifest).is_success())
	assert(
		plugin.get_state()
		== PluginLifecycleState.Value.RUNNING
	)

#endregion
'@

# =============================================================================
# AUTOLOADS AND DEPENDENCY DOCUMENTATION
# =============================================================================

$files["autoload/diagnostics.gd"] = @'
extends DiagnosticsService
## Global Diagnostics application service.
##
## Runtime composition must configure Diagnostics and register probes.
'@

$files["autoload/notification_center.gd"] = @'
extends NotificationCenterService
## Global Notification Center application service.
##
## Runtime composition must configure its repository.
'@

$files["autoload/plugin_loader.gd"] = @'
extends PluginLoaderService
## Global Plugin Loader service.
##
## Runtime composition must configure the registry and granted services.
'@

$files["docs/package-dependencies-013-015.md"] = @'
# Package dependencies 013–015

```text
013_diagnostics
├── 001_foundation
├── 002_design_system
├── 003_widget_library
└── 004_animation_system

014_notification_center
├── 001_foundation
├── 002_design_system
├── 003_widget_library
└── 004_animation_system

015_plugin_sdk
└── 001_foundation
'@
Write-Host ""
Write-Host "HYDRA AI HOME OS" -ForegroundColor Cyan
Write-Host "Installing packages 013-015..." -ForegroundColor Cyan
Write-Host ""

foreach ($entry in $files.GetEnumerator()) {
Write-HydraFile -RelativePath $entry.Key -Content $entry.Value
}

Test-GeneratedFiles -FileMap $files

Write-Host ""
Write-Host "Packages 013-015 installed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Optional autoloads:" -ForegroundColor Cyan
Write-Host "Diagnostics res://autoload/diagnostics.gd"
Write-Host "NotificationCenter res://autoload/notification_center.gd"
Write-Host "PluginLoader res://autoload/plugin_loader.gd"
Write-Host ""
Write-Host "Git commands:" -ForegroundColor Cyan
Write-Host "git add ."
Write-Host 'git commit -m "feat(platform): implement packages 013-015"'
Write-Host "git push"