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