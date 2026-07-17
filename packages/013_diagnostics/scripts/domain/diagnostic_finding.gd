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