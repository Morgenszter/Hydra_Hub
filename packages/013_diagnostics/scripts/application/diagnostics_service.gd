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